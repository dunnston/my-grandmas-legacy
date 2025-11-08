extends Node3D

# Register - Checkout station where customers pay for their purchases
# Player interacts to process customer transactions

signal transaction_completed(customer: Node3D, total: float)

# Node references
@onready var interaction_area: Area3D = $InteractionArea

# State
var player_nearby: Node3D = null
var current_customer: Node3D = null
var is_processing_checkout: bool = false

func _ready() -> void:
	print("Register ready: ", name)

	# Connect interaction area
	if interaction_area:
		interaction_area.body_entered.connect(_on_body_entered)
		interaction_area.body_exited.connect(_on_body_exited)

	# Connect to CustomerManager signals
	CustomerManager.customer_spawned.connect(_on_customer_spawned)

func _process(_delta: float) -> void:
	# Update interaction prompt
	if player_nearby and _has_waiting_customer():
		# Show prompt to checkout customer
		pass  # UI will handle this

func _on_body_entered(body: Node3D) -> void:
	"""Player entered interaction range"""
	if body.has_method("get_inventory_id"):
		player_nearby = body
		if _has_waiting_customer():
			print("[E] to Process Checkout")

func _on_body_exited(body: Node3D) -> void:
	"""Player left interaction range"""
	if body == player_nearby:
		player_nearby = null

func _on_customer_spawned(_customer: Node3D) -> void:
	"""A new customer was spawned"""
	# Check if anyone is waiting at register
	_check_for_waiting_customers()

func get_interaction_prompt() -> String:
	"""Get the prompt text for player UI"""
	if _has_waiting_customer():
		return "[E] Process Checkout"
	return "[E] Register (No customers)"

func interact(player: Node3D) -> void:
	"""Player interacted with register"""
	if is_processing_checkout:
		print("Already processing a checkout")
		return

	# Get next customer waiting at register
	current_customer = CustomerManager.get_next_customer_at_register()

	if not current_customer:
		print("No customers waiting at register")
		return

	process_checkout(current_customer)

func process_checkout(customer: Node3D) -> void:
	"""Process a customer's checkout"""
	if not customer:
		return

	is_processing_checkout = true

	print("\n=== PROCESSING CHECKOUT ===")

	# Get customer's selected items
	var items: Array[Dictionary] = customer.get_selected_items()
	var total_cost: float = customer.get_total_cost()

	print("Customer wants to buy:")
	var actual_total: float = 0.0
	for item_data in items:
		var item_id: String = item_data["item_id"]
		var quantity: int = item_data["quantity"]
		var recipe: Dictionary = RecipeManager.get_recipe(item_id)
		var item_name: String = recipe.get("name", item_id)
		var base_price: float = recipe.get("base_price", 0.0)

		# Get quality metadata from display case to calculate actual price
		var metadata: Dictionary = InventoryManager.get_item_metadata("display_case", item_id)
		var price: float = base_price

		if metadata.has("quality_data"):
			var quality_data = metadata.quality_data
			price = QualityManager.get_price_for_quality(base_price, quality_data)
			var quality_str = " [%s - %.0f%%]" % [quality_data.get("tier_name", ""), quality_data.get("quality", 0.0)]
			if quality_data.get("is_legendary", false):
				quality_str += " ✨LEGENDARY"
			print("  - %dx %s ($%.2f each%s)" % [quantity, item_name, price, quality_str])
		else:
			print("  - %dx %s ($%.2f each)" % [quantity, item_name, price])

		actual_total += price * quantity

	print("Total: $%.2f (Quality-adjusted!)" % actual_total)
	total_cost = actual_total  # Use quality-adjusted total

	# Check if items are available in display case
	var can_fulfill: bool = _check_item_availability(items)

	if not can_fulfill:
		print("ERROR: Not enough items in display case!")
		print("Customer leaves disappointed")
		# Customer leaves with low satisfaction
		customer.satisfaction_score = 0.0
		customer.set_target_position(customer.exit_position)
		customer.current_state = customer.State.LEAVING
		is_processing_checkout = false
		return

	# Remove items from display case
	_remove_items_from_display(items)

	# Complete the transaction
	EconomyManager.complete_sale("Items", total_cost)

	# Tell customer purchase is complete
	customer.complete_purchase()

	print("Checkout complete!")
	print("===========================\n")

	transaction_completed.emit(customer, total_cost)
	is_processing_checkout = false

	# Check if more customers are waiting
	_check_for_waiting_customers()

func _check_item_availability(items: Array[Dictionary]) -> bool:
	"""Check if all requested items are available in display case"""
	for item_data in items:
		var item_id: String = item_data["item_id"]
		var quantity: int = item_data["quantity"]
		var available: int = InventoryManager.get_item_quantity("display_case", item_id)

		if available < quantity:
			print("Not enough %s: need %d, have %d" % [item_id, quantity, available])
			return false

	return true

func _remove_items_from_display(items: Array[Dictionary]) -> void:
	"""Remove purchased items from display case"""
	for item_data in items:
		var item_id: String = item_data["item_id"]
		var quantity: int = item_data["quantity"]
		InventoryManager.remove_item("display_case", item_id, quantity)
		print("Removed %dx %s from display" % [quantity, item_id])

func _has_waiting_customer() -> bool:
	"""Check if any customers are waiting at register"""
	var waiting: Array[Node3D] = CustomerManager.get_customers_waiting_at_register()
	return waiting.size() > 0

func _check_for_waiting_customers() -> void:
	"""Check and notify if customers are waiting"""
	if _has_waiting_customer():
		print("Register: Customer waiting for checkout!")

# UI Helpers (for future UI integration)
func get_waiting_customer_count() -> int:
	"""Get number of customers waiting at register"""
	return CustomerManager.get_customers_waiting_at_register().size()

func get_current_customer_info() -> Dictionary:
	"""Get info about customer being served"""
	if current_customer and current_customer.has_method("get_selected_items"):
		return {
			"items": current_customer.get_selected_items(),
			"total": current_customer.get_total_cost(),
			"mood": current_customer.get_mood()
		}
	return {}

# ============================================================================
# AUTOMATION METHODS (for staff AI)
# ============================================================================

func get_waiting_customer() -> Node3D:
	"""Get next waiting customer (called by Cashier AI)"""
	if current_customer:
		return null  # Already serving someone

	var waiting: Array[Node3D] = CustomerManager.get_customers_waiting_at_register()
	if waiting.size() > 0:
		return waiting[0]
	return null

func auto_process_customer(customer: Node3D) -> bool:
	"""Process a customer checkout automatically (called by Cashier AI)"""
	if current_customer or not customer:
		return false

	# Check if customer has selected items
	if not customer.has_method("get_selected_items"):
		return false

	var items: Array = customer.get_selected_items()
	if items.is_empty():
		print("[Register] Customer has no items")
		return false

	# Check availability
	if not _check_item_availability(items):
		print("[Register] Items not available")
		return false

	# Process the sale
	var total_price: float = customer.get_total_cost()

	# Remove items from display
	_remove_items_from_display(items)

	# Add money
	EconomyManager.add_money(total_price, "Sale")

	# Update customer satisfaction
	if customer.has_method("complete_purchase"):
		customer.complete_purchase()

	# Track the sale
	if CustomerManager:
		CustomerManager.record_sale(items, total_price)

	print("[Register] Auto-processed sale: $%.2f" % total_price)
	sale_completed.emit(items, total_price)

	return true
