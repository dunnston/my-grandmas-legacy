extends Node

# DeliveryManager - Handles package delivery system
# Orders are queued and delivered at 3am each game day
# Packages must be physically opened by the player in the bakery

# Signals
signal delivery_available  # Emitted when a package arrives
signal package_opened(items: Dictionary)  # Emitted when player opens a package
signal package_emptied  # Emitted when package is fully emptied

# Delivery queue - items waiting to be delivered
var delivery_queue: Array[Dictionary] = []  # Array of {type: String, id: String, quantity: int, cost: float}

# Current package - items in the spawned package waiting to be picked up
var current_package_contents: Dictionary = {}  # {item_id: quantity}
var package_spawned: bool = false

# Delivery time (3 AM = 3 * 3600 seconds)
const DELIVERY_HOUR: int = 3
const DELIVERY_TIME: float = DELIVERY_HOUR * 3600.0

# Package spawn position (will be set by bakery scene)
var package_spawn_position: Vector3 = Vector3(0, 0, 0)
var package_scene_ref: Node3D = null  # Reference to spawned package in world

func _ready() -> void:
	print("DeliveryManager initialized")
	print("Packages will be delivered at %d:00 AM each day" % DELIVERY_HOUR)

	# Connect to day changed signal
	if GameManager:
		GameManager.day_changed.connect(_on_day_changed)

func _on_day_changed(_new_day: int) -> void:
	"""Handle new day - deliver queued items"""
	if delivery_queue.size() > 0:
		_deliver_package()

# ============================================================================
# ORDERING SYSTEM
# ============================================================================

func order_ingredient(ingredient_id: String, quantity: int, cost: float) -> void:
	"""Add an ingredient to the delivery queue"""
	delivery_queue.append({
		"type": "ingredient",
		"id": ingredient_id,
		"quantity": quantity,
		"cost": cost
	})
	print("Ordered: %dx %s (will arrive tomorrow at %d AM)" % [quantity, ingredient_id, DELIVERY_HOUR])

func order_equipment(equipment_id: String, cost: float) -> void:
	"""Add equipment to the delivery queue"""
	delivery_queue.append({
		"type": "equipment",
		"id": equipment_id,
		"quantity": 1,
		"cost": cost
	})
	print("Ordered: %s (will arrive tomorrow at %d AM)" % [equipment_id, DELIVERY_HOUR])

func order_decoration(decoration_id: String, cost: float) -> void:
	"""Add decoration to the delivery queue"""
	delivery_queue.append({
		"type": "decoration",
		"id": decoration_id,
		"quantity": 1,
		"cost": cost
	})
	print("Ordered: %s (will arrive tomorrow at %d AM)" % [decoration_id, DELIVERY_HOUR])

func get_pending_orders_count() -> int:
	"""Get number of items waiting to be delivered"""
	return delivery_queue.size()

func get_pending_orders() -> Array[Dictionary]:
	"""Get list of all pending orders"""
	return delivery_queue.duplicate()

# ============================================================================
# DELIVERY SYSTEM
# ============================================================================

func _deliver_package() -> void:
	"""Create a package with all queued items"""
	if delivery_queue.size() == 0:
		return

	# Clear any existing package
	if package_spawned:
		_clear_current_package()

	# Move queued items into current package
	current_package_contents.clear()

	print("\n=== PACKAGE DELIVERED ===")
	for order in delivery_queue:
		var item_id: String = order.id
		var quantity: int = order.quantity

		# Group items by ID
		if current_package_contents.has(item_id):
			current_package_contents[item_id] += quantity
		else:
			current_package_contents[item_id] = quantity

		print("- %dx %s" % [quantity, item_id])
	print("Package is waiting at the bakery entrance!")
	print("==========================\n")

	# Clear the delivery queue
	delivery_queue.clear()

	# Mark package as ready to spawn
	package_spawned = true
	delivery_available.emit()

func is_package_available() -> bool:
	"""Check if there's a package ready to be picked up"""
	return package_spawned and current_package_contents.size() > 0

func get_package_contents() -> Dictionary:
	"""Get contents of current package"""
	return current_package_contents.duplicate()

func take_item_from_package(item_id: String, quantity: int = 1) -> bool:
	"""Take an item from the package and add to player inventory
	Returns true if successful"""
	if not is_package_available():
		return false

	if not current_package_contents.has(item_id):
		return false

	var available: int = current_package_contents[item_id]
	if available < quantity:
		quantity = available

	# Add item to player inventory
	const PLAYER_INVENTORY_ID: String = "player"
	if InventoryManager.add_item(PLAYER_INVENTORY_ID, item_id, quantity):
		print("Added %dx %s to player inventory" % [quantity, item_id])
	else:
		print("Failed to add %s to player inventory" % item_id)
		return false

	# Remove from package
	current_package_contents[item_id] -= quantity
	if current_package_contents[item_id] <= 0:
		current_package_contents.erase(item_id)

	package_opened.emit(current_package_contents)

	# Check if package is empty
	if current_package_contents.size() == 0:
		_empty_package()

	return true

func take_all_from_package() -> void:
	"""Take all items from package at once"""
	var items: Array = current_package_contents.keys()
	for item_id in items:
		var quantity: int = current_package_contents[item_id]
		take_item_from_package(item_id, quantity)

func _empty_package() -> void:
	"""Package has been fully emptied"""
	print("Package is empty!")
	package_spawned = false
	current_package_contents.clear()
	package_emptied.emit()

	# Remove package from scene if it exists
	if package_scene_ref:
		package_scene_ref.queue_free()
		package_scene_ref = null

func _clear_current_package() -> void:
	"""Clear current package (used when new delivery arrives before old one is opened)"""
	print("Warning: Previous package was not opened!")
	_empty_package()

# ============================================================================
# PACKAGE SPAWNING (Called by bakery scene)
# ============================================================================

func set_package_spawn_position(position: Vector3) -> void:
	"""Set where packages should spawn in the bakery"""
	package_spawn_position = position

func set_package_scene_reference(scene: Node3D) -> void:
	"""Store reference to spawned package scene"""
	package_scene_ref = scene

# ============================================================================
# SAVE/LOAD SYSTEM
# ============================================================================

func save_data() -> Dictionary:
	"""Save delivery system state"""
	return {
		"delivery_queue": delivery_queue.duplicate(),
		"current_package_contents": current_package_contents.duplicate(),
		"package_spawned": package_spawned
	}

func load_data(data: Dictionary) -> void:
	"""Load delivery system state"""
	if data.has("delivery_queue"):
		delivery_queue = data.delivery_queue.duplicate()

	if data.has("current_package_contents"):
		current_package_contents = data.current_package_contents.duplicate()

	if data.has("package_spawned"):
		package_spawned = data.package_spawned
		if package_spawned:
			# Emit signal so bakery can spawn the package
			delivery_available.emit()

	print("DeliveryManager data loaded")
