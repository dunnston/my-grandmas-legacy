extends Node

# InventoryManager - Singleton for managing all inventories
# Handles player inventory, station inventories, and item transfers

# Signals
signal inventory_changed(inventory_id: String)
signal item_added(inventory_id: String, item_id: String, quantity: int)
signal item_removed(inventory_id: String, item_id: String, quantity: int)

# Inventory storage - Dictionary of dictionaries
# Key: inventory_id (e.g., "player", "mixing_bowl_1", "oven_1")
# Value: Dictionary of {item_id: quantity}
var inventories: Dictionary = {}

func _ready() -> void:
	# Initialize player inventory
	create_inventory("player")
	print("InventoryManager initialized")

# Create a new inventory
func create_inventory(inventory_id: String) -> void:
	if not inventories.has(inventory_id):
		inventories[inventory_id] = {}
		print("Created inventory: ", inventory_id)
	else:
		print("Warning: Inventory ", inventory_id, " already exists")

# Add item to inventory
func add_item(inventory_id: String, item_id: String, quantity: int = 1) -> bool:
	if not inventories.has(inventory_id):
		print("Error: Inventory ", inventory_id, " does not exist")
		return false

	if inventories[inventory_id].has(item_id):
		inventories[inventory_id][item_id] += quantity
	else:
		inventories[inventory_id][item_id] = quantity

	print("Added ", quantity, "x ", item_id, " to ", inventory_id)
	item_added.emit(inventory_id, item_id, quantity)
	inventory_changed.emit(inventory_id)
	return true

# Remove item from inventory
func remove_item(inventory_id: String, item_id: String, quantity: int = 1) -> bool:
	if not inventories.has(inventory_id):
		print("Error: Inventory ", inventory_id, " does not exist")
		return false

	if not inventories[inventory_id].has(item_id):
		print("Error: ", inventory_id, " does not have ", item_id)
		return false

	if inventories[inventory_id][item_id] < quantity:
		print("Error: Not enough ", item_id, " in ", inventory_id)
		return false

	inventories[inventory_id][item_id] -= quantity

	# Remove entry if quantity reaches 0
	if inventories[inventory_id][item_id] <= 0:
		inventories[inventory_id].erase(item_id)

	print("Removed ", quantity, "x ", item_id, " from ", inventory_id)
	item_removed.emit(inventory_id, item_id, quantity)
	inventory_changed.emit(inventory_id)
	return true

# Transfer item between inventories
func transfer_item(from_inventory: String, to_inventory: String, item_id: String, quantity: int = 1) -> bool:
	if remove_item(from_inventory, item_id, quantity):
		if add_item(to_inventory, item_id, quantity):
			print("Transferred ", quantity, "x ", item_id, " from ", from_inventory, " to ", to_inventory)
			return true
		else:
			# Rollback if add failed
			add_item(from_inventory, item_id, quantity)
			return false
	return false

# Check if inventory has item
func has_item(inventory_id: String, item_id: String, quantity: int = 1) -> bool:
	if not inventories.has(inventory_id):
		return false
	if not inventories[inventory_id].has(item_id):
		return false
	return inventories[inventory_id][item_id] >= quantity

# Get item quantity
func get_item_quantity(inventory_id: String, item_id: String) -> int:
	if not inventories.has(inventory_id):
		return 0
	if not inventories[inventory_id].has(item_id):
		return 0
	return inventories[inventory_id][item_id]

# Get entire inventory
func get_inventory(inventory_id: String) -> Dictionary:
	if inventories.has(inventory_id):
		return inventories[inventory_id].duplicate()
	return {}

# Clear inventory
func clear_inventory(inventory_id: String) -> void:
	if inventories.has(inventory_id):
		inventories[inventory_id].clear()
		inventory_changed.emit(inventory_id)
		print("Cleared inventory: ", inventory_id)

# Get all items in inventory (returns array of item_ids)
func get_inventory_items(inventory_id: String) -> Array:
	if inventories.has(inventory_id):
		return inventories[inventory_id].keys()
	return []

# Debug: Print inventory contents
func print_inventory(inventory_id: String) -> void:
	if not inventories.has(inventory_id):
		print("Inventory ", inventory_id, " does not exist")
		return

	print("=== Inventory: ", inventory_id, " ===")
	if inventories[inventory_id].is_empty():
		print("  (empty)")
	else:
		for item_id in inventories[inventory_id]:
			print("  ", item_id, ": ", inventories[inventory_id][item_id])

# Save/Load support
func get_save_data() -> Dictionary:
	"""Get all inventory data for saving"""
	return {
		"inventories": inventories.duplicate(true)
	}

func load_save_data(data: Dictionary) -> void:
	"""Load inventory data from save"""
	if data.has("inventories"):
		inventories = data["inventories"].duplicate(true)
		print("Inventory data loaded: %d inventories" % inventories.size())
