extends Node3D

# DisplayCase - Store finished goods for sale (Phase 2 will handle customers)

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
	print("\nYour inventory:")
	InventoryManager.print_inventory("player")
	print("\nCurrent display:")
	InventoryManager.print_inventory(get_inventory_id())

	# Check for finished goods
	var player_inventory = InventoryManager.get_inventory("player")
	var has_goods: bool = false

	# Look for finished products (must match oven output and recipe IDs)
	var finished_goods = ["white_bread", "chocolate_chip_cookies", "blueberry_muffins"]

	for item_id in player_inventory.keys():
		if item_id in finished_goods:
			var quantity = player_inventory[item_id]
			print("\nStocking ", quantity, "x ", item_id, " in display case...")
			stock_item(player, item_id, quantity)
			has_goods = true

	if not has_goods:
		print("You don't have any finished goods to stock!")
		print("Bake something first!")

func stock_item(player: Node3D, item_id: String, quantity: int) -> void:
	if InventoryManager.transfer_item("player", get_inventory_id(), item_id, quantity):
		print("Successfully stocked ", quantity, "x ", item_id)
		item_stocked.emit(item_id, quantity)
	else:
		print("Error: Could not stock ", item_id)

func get_inventory_id() -> String:
	return "display_case"  # Fixed ID for customer access

func get_display_contents() -> Dictionary:
	return InventoryManager.get_inventory(get_inventory_id())
