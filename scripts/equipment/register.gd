extends StaticBody3D

# Register - Checkout station where customers pay for their purchases
# Player interacts to process customer transactions using interactive checkout UI

signal transaction_completed(customer: Node3D, total: float)
signal sale_completed(items: Array, total: float)  # For AI automation

# Node references
@onready var interaction_area: Area3D = $InteractionArea

# Checkout states
enum CheckoutState {
	IDLE,              # No checkout in progress
	VIEWING_ORDER,     # Player is viewing what customer wants
	COLLECTING_ITEMS,  # Player is collecting items from display case
	BAGGING_ITEMS,     # Player can bag items at counter
	READY_FOR_PAYMENT  # All items bagged, ready to process payment
}

# State
var player_nearby: Node3D = null
var current_customer: Node3D = null
var checkout_state: CheckoutState = CheckoutState.IDLE

# UI references
var customer_wants_ui: Control = null
var payment_ui: Control = null  # The payment mini-game UI
var bag_station: Node3D = null
var interaction_indicator: Node3D = null

func _ready() -> void:
	print("Register ready: ", name)

	# Add to register group so display case can find us
	add_to_group("register")

	# Connect interaction area
	if interaction_area:
		interaction_area.body_entered.connect(_on_body_entered)
		interaction_area.body_exited.connect(_on_body_exited)

	# Connect to CustomerManager signals
	CustomerManager.customer_spawned.connect(_on_customer_spawned)

	# Create interaction indicator
	_create_interaction_indicator()

	# Create UIs (await to ensure they complete initialization)
	await _create_customer_wants_ui()
	_create_payment_ui()

	# Find bag station
	_find_bag_station()

	print("Register initialization complete")

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
	match checkout_state:
		CheckoutState.IDLE:
			if _has_waiting_customer():
				return "[E] Start Checkout"
			return "[E] Register (No customers)"
		CheckoutState.COLLECTING_ITEMS:
			return "[E] Collect items from display case"
		CheckoutState.BAGGING_ITEMS:
			return "[E] Bag items at counter"
		CheckoutState.READY_FOR_PAYMENT:
			return "[E] Process Payment"
		_:
			return "[E] Register"

func is_checkout_in_progress() -> bool:
	"""Check if checkout is currently in progress"""
	return checkout_state != CheckoutState.IDLE

func _create_customer_wants_ui() -> void:
	"""Create the customer wants popup UI"""
	print("Register: Creating customer wants UI...")

	# Check if already exists
	if customer_wants_ui:
		print("Customer Wants UI already exists")
		return

	var CustomerWantsUIScript = preload("res://scripts/ui/customer_wants_ui.gd")
	if not CustomerWantsUIScript:
		push_error("Failed to load customer_wants_ui.gd!")
		return

	customer_wants_ui = CustomerWantsUIScript.new()
	if not customer_wants_ui:
		push_error("Failed to create CustomerWantsUI instance!")
		return

	customer_wants_ui.name = "CustomerWantsUI"

	# Find HUD and add UI to it (deferred to avoid "parent busy" error)
	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		print("Adding Customer Wants UI to HUD: ", hud.name)
		hud.add_child.call_deferred(customer_wants_ui)
	else:
		print("WARNING: HUD not found, adding to root")
		get_tree().get_root().add_child.call_deferred(customer_wants_ui)

	# Wait for deferred add_child to complete
	await get_tree().process_frame

	# Verify it was added
	if customer_wants_ui and customer_wants_ui.is_inside_tree():
		print("✓ Customer Wants UI successfully added to tree")

		# Wait for _ready() to be called
		if not customer_wants_ui.is_node_ready():
			print("  Waiting for node to be ready...")
			await get_tree().process_frame

		if customer_wants_ui.is_node_ready():
			print("  ✓ Node is ready")
		else:
			print("  ✗ Warning: Node still not ready")
	else:
		push_error("✗ Customer Wants UI NOT in tree!")
		customer_wants_ui = null
		return

	# Connect signal
	if customer_wants_ui and not customer_wants_ui.ui_closed.is_connected(_on_customer_wants_closed):
		customer_wants_ui.ui_closed.connect(_on_customer_wants_closed)
		print("✓ Signal connected")

	print("✓ Customer Wants UI creation complete")

func _create_payment_ui() -> void:
	"""Create the payment mini-game UI"""
	print("Register: Creating payment UI...")

	var PaymentUIScript = preload("res://scripts/ui/payment_ui.gd")
	payment_ui = PaymentUIScript.new()
	payment_ui.name = "PaymentUI"

	# Add to HUD (deferred to avoid "parent busy" error)
	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		print("Adding Payment UI to HUD: ", hud.name)
		hud.add_child.call_deferred(payment_ui)
	else:
		print("WARNING: HUD not found, adding to root")
		get_tree().get_root().add_child.call_deferred(payment_ui)

	# Wait for deferred add_child to complete
	await get_tree().process_frame

	# Connect signal
	if payment_ui and payment_ui.has_signal("payment_completed"):
		payment_ui.payment_completed.connect(_on_payment_completed)
		print("✓ Payment completed signal connected")

	print("✓ Payment UI created")

func _find_bag_station() -> void:
	"""Find the bag station in the scene"""
	# Look for bag station as sibling or in equipment group
	bag_station = get_parent().get_node_or_null("BagStation")
	if bag_station:
		print("Found bag station: ", bag_station.name)
	else:
		print("Warning: Bag station not found!")

func interact(player: Node3D) -> void:
	"""Player interacted with register - multi-step checkout"""
	match checkout_state:
		CheckoutState.IDLE:
			_start_checkout()
		CheckoutState.READY_FOR_PAYMENT:
			_process_payment()
		_:
			print("Checkout in progress - follow the steps")

func _start_checkout() -> void:
	"""Step 1: Show customer wants and start checkout"""
	current_customer = CustomerManager.get_next_customer_at_register()

	if not current_customer:
		print("No customers waiting")
		return

	# Verify this customer is at the front of the queue
	if current_customer.has("queue_position_index") and current_customer.queue_position_index > 0:
		print("Customer is not at front of queue - please wait for their turn")
		current_customer = null
		return

	print("Starting checkout for ", current_customer.customer_id)

	# Activate bag station for checkout
	if bag_station and bag_station.has_method("activate_for_checkout"):
		bag_station.activate_for_checkout()
	else:
		print("Warning: Bag station not available!")

	# Show customer wants popup
	if not customer_wants_ui:
		print("ERROR: Customer wants UI not initialized!")
		_create_customer_wants_ui()  # Try to create it now
		if not customer_wants_ui:
			push_error("Failed to create customer wants UI!")
			return

	# Get customer's items and show the UI
	var items = current_customer.get_selected_items()
	print("Customer wants %d items" % items.size())

	# Call show directly - the UI will handle initialization
	customer_wants_ui.show_customer_wants(items)
	checkout_state = CheckoutState.VIEWING_ORDER
	print("Checkout UI should now be visible")

func _on_customer_wants_closed() -> void:
	"""Customer wants popup closed - move to collecting items"""
	print("Customer wants closed - now collect items from display case")
	checkout_state = CheckoutState.COLLECTING_ITEMS

	# Create holding inventory
	InventoryManager.create_inventory("player_carry")

	# Activate bag station
	if bag_station and bag_station.has_method("activate_for_checkout"):
		bag_station.activate_for_checkout()

	# Update state when items are bagged
	if bag_station and bag_station.has_signal("items_bagged"):
		if not bag_station.items_bagged.is_connected(_on_items_bagged):
			bag_station.items_bagged.connect(_on_items_bagged)

	# Move to bagging state
	checkout_state = CheckoutState.BAGGING_ITEMS

func _on_items_bagged() -> void:
	"""Items were bagged - check if ready for payment"""
	print("Register: items_bagged signal received")

	var bag_inventory = InventoryManager.get_inventory("shopping_bag")
	var customer_items = current_customer.get_selected_items() if current_customer else []

	print("Register: Checking if all items bagged...")
	print("  Bag contains: ", bag_inventory)
	print("  Customer wants: ", customer_items)

	# Check if all items are bagged
	var all_items_bagged = true
	for item_data in customer_items:
		var item_id = item_data["item_id"]
		var needed_qty = item_data["quantity"]
		var bagged_qty = bag_inventory.get(item_id, 0)

		print("  Item %s: needed %d, bagged %d" % [item_id, needed_qty, bagged_qty])

		if bagged_qty < needed_qty:
			all_items_bagged = false
			break

	if all_items_bagged:
		print("✓ All items bagged! READY FOR PAYMENT")
		print("  >>> GO TO REGISTER AND PRESS [E] TO COMPLETE CHECKOUT <<<")
		checkout_state = CheckoutState.READY_FOR_PAYMENT
	else:
		print("✗ Still need more items in bag")

func _process_payment() -> void:
	"""Step 3: Process payment mini-game"""
	print("Processing payment - launching mini-game...")

	if not payment_ui or not payment_ui.has_method("show_payment"):
		push_error("Payment UI not initialized!")
		_complete_checkout(30.0, true)  # Fallback auto-complete
		return

	# Calculate total
	var total = current_customer.get_total_cost() if current_customer else 0.0
	print("Total amount due: $%.2f" % total)

	# Show payment UI
	payment_ui.show_payment(total)

func _on_payment_completed(transaction_time: float, had_errors: bool, success: bool) -> void:
	"""Payment mini-game completed"""
	print("Register: Payment completed!")
	print("  Time: %.2f seconds" % transaction_time)
	print("  Had errors: ", had_errors)
	print("  Success: ", success)

	if success:
		_complete_checkout(transaction_time, had_errors)
	else:
		# Payment failed - cancel checkout
		print("Payment failed - cancelling checkout")
		_reset_checkout()

func _complete_checkout(transaction_time: float = 0.0, had_errors: bool = false) -> void:
	"""Complete the checkout transaction"""
	if not current_customer:
		return

	print("Completing checkout...")
	print("  Transaction time: %.2f seconds" % transaction_time)
	print("  Had errors: ", had_errors)

	# Remove items from display case
	var bag_inventory = InventoryManager.get_inventory("shopping_bag")
	for item_id in bag_inventory:
		var quantity = bag_inventory[item_id]
		InventoryManager.remove_item("display_case", item_id, quantity)

	# Add money
	var total = current_customer.get_total_cost()
	EconomyManager.add_money(total, "Sale")

	# Complete customer purchase with timing and error info
	current_customer.complete_purchase(transaction_time, had_errors)

	# Reset state
	_reset_checkout()

	print("Checkout complete!")

func _reset_checkout() -> void:
	"""Reset checkout state"""
	checkout_state = CheckoutState.IDLE
	current_customer = null

	# Clear inventories
	InventoryManager.clear_inventory("player_carry")
	InventoryManager.clear_inventory("shopping_bag")

	# Deactivate bag station
	if bag_station and bag_station.has_method("deactivate"):
		bag_station.deactivate()

func force_reset_checkout() -> void:
	"""Force reset checkout state (for debugging/recovery)"""
	print("FORCE RESET: Resetting checkout state")
	_reset_checkout()

func process_checkout(customer: Node3D) -> void:
	"""Process a customer's checkout (legacy/automation method)"""
	if not customer:
		return

	print("\n=== PROCESSING CHECKOUT (AUTO) ===")

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

func _create_interaction_indicator() -> void:
	"""Create the interaction indicator label"""
	var IndicatorScript = load("res://scripts/ui/interaction_indicator.gd")
	interaction_indicator = Node3D.new()
	interaction_indicator.set_script(IndicatorScript)
	interaction_indicator.name = "InteractionIndicator"
	interaction_indicator.position = Vector3(0, 1.5, 0)  # Above the register
	add_child(interaction_indicator)

	# Wait for it to be ready
	await interaction_indicator.ready

	if interaction_indicator.has_method("set_text"):
		interaction_indicator.set_text("Cash Register")

func show_interaction_indicator() -> void:
	"""Called when player looks at this object"""
	if interaction_indicator and interaction_indicator.has_method("show_indicator"):
		interaction_indicator.show_indicator()

func hide_interaction_indicator() -> void:
	"""Called when player looks away"""
	if interaction_indicator and interaction_indicator.has_method("hide_indicator"):
		interaction_indicator.hide_indicator()

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
