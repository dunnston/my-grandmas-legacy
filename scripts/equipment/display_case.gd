extends Node3D

# DisplayCase - Store finished goods for sale (Phase 2 will handle customers)
# TODO: Extend to support quality tiers - requires InventoryManager to store item metadata

signal item_stocked(item_id: String, quantity: int)
signal item_removed(item_id: String, quantity: int)

# Node references
@onready var interaction_area: Area3D = $InteractionArea

# State
var player_nearby: Node3D = null

func _ready() -> void:
	# Create inventory for this station
	InventoryManager.create_inventory(get_inventory_id())

	# Connect interaction area
	if interaction_area:
		interaction_area.body_entered.connect(_on_body_entered)
		interaction_area.body_exited.connect(_on_body_exited)

	print("DisplayCase ready: ", name)

# Interaction system
func _on_body_entered(body: Node3D) -> void:
	if body.has_method("get_inventory_id"):
		player_nearby = body
		print("[E] to use Display Case")

func _on_body_exited(body: Node3D) -> void:
	if body == player_nearby:
		player_nearby = null

func get_interaction_prompt() -> String:
	return "[E] Stock Display Case"

func interact(player: Node3D) -> void:
	open_display_ui(player)

func open_display_ui(player: Node3D) -> void:
	print("\n=== DISPLAY CASE ===")
	print("Stock your baked goods here for customers to buy")
	print("(Quality tracking coming soon - will affect prices!)")
	print("\nYour inventory:")
	InventoryManager.print_inventory("player")
	print("\nCurrent display:")
	InventoryManager.print_inventory(get_inventory_id())

	# Check for finished goods
	var player_inventory = InventoryManager.get_inventory("player")
	var has_goods: bool = false

	# Look for finished products (any valid recipe that's not dough/batter)
	for item_id in player_inventory.keys():
		# Check if this is a finished product (not dough/batter intermediate)
		if not item_id.ends_with("_dough") and not item_id.ends_with("_batter"):
			# Verify it's a valid recipe
			if RecipeManager and RecipeManager.get_recipe(item_id) != {}:
				var quantity = player_inventory[item_id]
				print("\nStocking ", quantity, "x ", item_id, " in display case...")
				stock_item(player, item_id, quantity)
				has_goods = true

	if not has_goods:
		print("You don't have any finished goods to stock!")
		print("Bake something first!")

func stock_item(player: Node3D, item_id: String, quantity: int) -> void:
	# Check if there's an active bulk order for this item
	var bulk_order_quantity: int = 0
	if EventManager and EventManager.has_active_bulk_order(item_id):
		# Try to deliver to bulk order first
		var delivered: bool = EventManager.deliver_to_bulk_order(item_id, quantity)
		if delivered:
			bulk_order_quantity = quantity
			print("Delivered %d x %s to bulk order!" % [quantity, item_id])

	# Stock remaining items in display case for regular customers
	var remaining: int = quantity - bulk_order_quantity
	if remaining > 0:
		if InventoryManager.transfer_item("player", get_inventory_id(), item_id, remaining):
			print("Successfully stocked ", remaining, "x ", item_id)
			item_stocked.emit(item_id, remaining)
		else:
			print("Error: Could not stock ", item_id)
	elif bulk_order_quantity > 0:
		# All items went to bulk order, still need to remove from player
		InventoryManager.remove_item("player", item_id, bulk_order_quantity)
		item_stocked.emit(item_id, 0)  # None stocked in display, all to bulk order

func get_inventory_id() -> String:
	return "display_case"  # Fixed ID for customer access

func get_display_contents() -> Dictionary:
	return InventoryManager.get_inventory(get_inventory_id())
