extends Node

# InventoryManager - Singleton for managing all inventories
# Handles player inventory, station inventories, and item transfers
# Now supports item metadata (quality, freshness, etc.)

# Signals
signal inventory_changed(inventory_id: String)
signal item_added(inventory_id: String, item_id: String, quantity: int)
signal item_removed(inventory_id: String, item_id: String, quantity: int)

# Inventory storage - Dictionary of dictionaries
# Key: inventory_id (e.g., "player", "mixing_bowl_1", "oven_1")
# Value: Dictionary of {item_id: quantity} OR {item_id: {stacks: Array}}
var inventories: Dictionary = {}

# Metadata storage - tracks quality and other item properties
# Structure: {inventory_id: {item_id: [{quantity: int, metadata: Dictionary}]}}
var item_metadata: Dictionary = {}

func _ready() -> void:
	# Initialize player inventory
	create_inventory("player")
	print("InventoryManager initialized")

# Create a new inventory
func create_inventory(inventory_id: String) -> void:
	if not inventories.has(inventory_id):
		inventories[inventory_id] = {}
		item_metadata[inventory_id] = {}
		print("Created inventory: ", inventory_id)
	else:
		print("Warning: Inventory ", inventory_id, " already exists")

# Add item to inventory (with optional metadata for quality, etc.)
func add_item(inventory_id: String, item_id: String, quantity: int = 1, metadata: Dictionary = {}) -> bool:
	if not inventories.has(inventory_id):
		print("Error: Inventory ", inventory_id, " does not exist")
		return false

	# If metadata provided, store in metadata system
	if not metadata.is_empty():
		_add_item_with_metadata(inventory_id, item_id, quantity, metadata)
	else:
		# Simple quantity tracking (backward compatible)
		if inventories[inventory_id].has(item_id):
			inventories[inventory_id][item_id] += quantity
		else:
			inventories[inventory_id][item_id] = quantity

	var quality_info: String = ""
	if metadata.has("quality_data"):
		var qd = metadata.quality_data
		quality_info = " [%s - %.1f%%]" % [qd.get("tier_name", ""), qd.get("quality", 0.0)]

	print("Added ", quantity, "x ", item_id, quality_info, " to ", inventory_id)
	item_added.emit(inventory_id, item_id, quantity)
	inventory_changed.emit(inventory_id)
	return true

# Internal: Add item with metadata tracking
func _add_item_with_metadata(inventory_id: String, item_id: String, quantity: int, metadata: Dictionary) -> void:
	# Initialize metadata storage if needed
	if not item_metadata.has(inventory_id):
		item_metadata[inventory_id] = {}
	if not item_metadata[inventory_id].has(item_id):
		item_metadata[inventory_id][item_id] = []

	# Try to stack with existing items of same quality
	var stacked: bool = false
	for stack in item_metadata[inventory_id][item_id]:
		if _metadata_matches(stack.metadata, metadata):
			stack.quantity += quantity
			stacked = true
			break

	# Create new stack if couldn't stack
	if not stacked:
		item_metadata[inventory_id][item_id].append({
			"quantity": quantity,
			"metadata": metadata.duplicate()
		})

	# Update total quantity in main inventory
	var total_quantity: int = _get_total_metadata_quantity(inventory_id, item_id)
	inventories[inventory_id][item_id] = total_quantity

# Check if two metadata dictionaries match (for stacking)
func _metadata_matches(meta1: Dictionary, meta2: Dictionary) -> bool:
	if meta1.is_empty() and meta2.is_empty():
		return true

	# Quality data matching
	if meta1.has("quality_data") and meta2.has("quality_data"):
		var q1 = meta1.quality_data
		var q2 = meta2.quality_data
		return (q1.get("tier", 0) == q2.get("tier", 0) and
				q1.get("is_legendary", false) == q2.get("is_legendary", false))

	return meta1 == meta2

# Get total quantity from metadata stacks
func _get_total_metadata_quantity(inventory_id: String, item_id: String) -> int:
	if not item_metadata.has(inventory_id):
		return 0
	if not item_metadata[inventory_id].has(item_id):
		return 0

	var total: int = 0
	for stack in item_metadata[inventory_id][item_id]:
		total += stack.quantity
	return total

# Remove item from inventory (handles metadata automatically)
func remove_item(inventory_id: String, item_id: String, quantity: int = 1, prefer_quality: int = -1) -> bool:
	if not inventories.has(inventory_id):
		print("Error: Inventory ", inventory_id, " does not exist")
		return false

	if not inventories[inventory_id].has(item_id):
		print("Error: ", inventory_id, " does not have ", item_id)
		return false

	if inventories[inventory_id][item_id] < quantity:
		print("Error: Not enough ", item_id, " in ", inventory_id)
		return false

	# Remove from metadata stacks if they exist
	if item_metadata.has(inventory_id) and item_metadata[inventory_id].has(item_id):
		_remove_item_with_metadata(inventory_id, item_id, quantity, prefer_quality)
	else:
		# Simple removal
		inventories[inventory_id][item_id] -= quantity

	# Remove entry if quantity reaches 0
	if inventories[inventory_id][item_id] <= 0:
		inventories[inventory_id].erase(item_id)
		if item_metadata.has(inventory_id):
			item_metadata[inventory_id].erase(item_id)

	print("Removed ", quantity, "x ", item_id, " from ", inventory_id)
	item_removed.emit(inventory_id, item_id, quantity)
	inventory_changed.emit(inventory_id)
	return true

# Internal: Remove item from metadata stacks
func _remove_item_with_metadata(inventory_id: String, item_id: String, quantity: int, prefer_quality: int) -> void:
	var remaining: int = quantity
	var stacks = item_metadata[inventory_id][item_id]

	# Sort stacks - remove from preferred quality first, then lowest quality
	stacks.sort_custom(func(a, b):
		var qa = a.metadata.get("quality_data", {}).get("tier", 0)
		var qb = b.metadata.get("quality_data", {}).get("tier", 0)
		if prefer_quality >= 0:
			# Prefer specific quality first
			if qa == prefer_quality and qb != prefer_quality:
				return true
			if qa != prefer_quality and qb == prefer_quality:
				return false
		# Then lowest quality first
		return qa < qb
	)

	# Remove from stacks
	var i: int = 0
	while i < stacks.size() and remaining > 0:
		var stack = stacks[i]
		if stack.quantity <= remaining:
			remaining -= stack.quantity
			stacks.remove_at(i)
		else:
			stack.quantity -= remaining
			remaining = 0
			i += 1

	# Update total
	var total_quantity: int = _get_total_metadata_quantity(inventory_id, item_id)
	inventories[inventory_id][item_id] = total_quantity

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

# Get metadata for an item (returns first stack's metadata, or empty dict)
func get_item_metadata(inventory_id: String, item_id: String) -> Dictionary:
	if not item_metadata.has(inventory_id):
		return {}
	if not item_metadata[inventory_id].has(item_id):
		return {}
	if item_metadata[inventory_id][item_id].is_empty():
		return {}

	# Return first stack's metadata
	return item_metadata[inventory_id][item_id][0].metadata.duplicate()

# Get all stacks for an item (for detailed quality breakdown)
func get_item_stacks(inventory_id: String, item_id: String) -> Array:
	if not item_metadata.has(inventory_id):
		return []
	if not item_metadata[inventory_id].has(item_id):
		return []

	return item_metadata[inventory_id][item_id].duplicate(true)

# Get highest quality stack for an item
func get_highest_quality_stack(inventory_id: String, item_id: String) -> Dictionary:
	var stacks = get_item_stacks(inventory_id, item_id)
	if stacks.is_empty():
		return {}

	var best_stack = stacks[0]
	var best_quality: float = best_stack.get("metadata", {}).get("quality_data", {}).get("quality", 0.0)

	for stack in stacks:
		var quality: float = stack.get("metadata", {}).get("quality_data", {}).get("quality", 0.0)
		if quality > best_quality:
			best_quality = quality
			best_stack = stack

	return best_stack.duplicate()

# Debug: Print inventory contents with quality info
func print_inventory(inventory_id: String) -> void:
	if not inventories.has(inventory_id):
		print("Inventory ", inventory_id, " does not exist")
		return

	print("=== Inventory: ", inventory_id, " ===")
	if inventories[inventory_id].is_empty():
		print("  (empty)")
	else:
		for item_id in inventories[inventory_id]:
			var total_qty: int = inventories[inventory_id][item_id]
			print("  ", item_id, ": ", total_qty)

			# Show quality breakdown if metadata exists
			if item_metadata.has(inventory_id) and item_metadata[inventory_id].has(item_id):
				for stack in item_metadata[inventory_id][item_id]:
					var meta = stack.metadata
					if meta.has("quality_data"):
						var qd = meta.quality_data
						var legendary = " ✨LEGENDARY" if qd.get("is_legendary", false) else ""
						print("    └─ %dx %s (%.1f%%)%s" % [
							stack.quantity,
							qd.get("tier_name", ""),
							qd.get("quality", 0.0),
							legendary
						])

# Save/Load support
func get_save_data() -> Dictionary:
	"""Get all inventory data for saving"""
	return {
		"inventories": inventories.duplicate(true),
		"item_metadata": item_metadata.duplicate(true)
	}

func load_save_data(data: Dictionary) -> void:
	"""Load inventory data from save"""
	if data.has("inventories"):
		inventories = data["inventories"].duplicate(true)
		print("Inventory data loaded: %d inventories" % inventories.size())

	if data.has("item_metadata"):
		item_metadata = data["item_metadata"].duplicate(true)
		print("Item metadata loaded")
	else:
		# Initialize empty metadata for old saves
		item_metadata = {}
		for inventory_id in inventories.keys():
			item_metadata[inventory_id] = {}
