extends Node

# BuildingManager - Handles placement, rotation, and destruction of furniture/decorations
# Works with UpgradeManager to track purchases and provides visual placement system

# Signals
signal placement_mode_started(item_id: String)
signal placement_mode_ended()
signal item_placed(item_id: String, position: Vector3, rotation: float)
signal item_destroyed(item_id: String, refund_amount: float)
signal placement_validity_changed(is_valid: bool)

# Placement state
var is_in_placement_mode: bool = false
var current_item_id: String = ""
var current_preview: Node3D = null
var current_rotation: float = 0.0
var is_placement_valid: bool = false

# Placed objects tracking
var placed_objects: Array[Dictionary] = []  # [{item_id, position, rotation, node}]

# Placement settings
const ROTATION_STEP: float = PI / 4.0  # 45 degrees
const GRID_SIZE: float = 1.0  # Snap to 1 meter grid
const PLACEMENT_HEIGHT: float = 0.0  # Ground level

# Material for preview
var valid_material: StandardMaterial3D
var invalid_material: StandardMaterial3D

func _ready() -> void:
	print("BuildingManager initialized")
	_setup_preview_materials()

func _setup_preview_materials() -> void:
	# Valid placement - blue semi-transparent
	valid_material = StandardMaterial3D.new()
	valid_material.albedo_color = Color(0.3, 0.5, 1.0, 0.5)
	valid_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	valid_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	# Invalid placement - red semi-transparent
	invalid_material = StandardMaterial3D.new()
	invalid_material.albedo_color = Color(1.0, 0.3, 0.3, 0.5)
	invalid_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	invalid_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

func _process(_delta: float) -> void:
	if is_in_placement_mode and current_preview:
		_update_preview_position()
		_check_placement_validity()

func _input(event: InputEvent) -> void:
	if not is_in_placement_mode:
		return

	# Rotation
	if event.is_action_pressed("rotate_left"):
		rotate_preview(-ROTATION_STEP)
	elif event.is_action_pressed("rotate_right"):
		rotate_preview(ROTATION_STEP)

	# Confirm placement
	elif event.is_action_pressed("interact"):  # E key
		confirm_placement()

	# Cancel placement
	elif event.is_action_pressed("ui_cancel"):  # ESC key
		cancel_placement()

# Start placement mode for an item
func start_placement(item_id: String) -> bool:
	if is_in_placement_mode:
		print("Already in placement mode")
		return false

	# Verify the upgrade exists and is purchased
	if not UpgradeManager.is_upgrade_purchased(item_id):
		print("Cannot place unpurchased item: %s" % item_id)
		return false

	current_item_id = item_id
	is_in_placement_mode = true
	current_rotation = 0.0

	# Create preview object
	current_preview = _create_preview_object(item_id)
	if not current_preview:
		print("Failed to create preview for: %s" % item_id)
		is_in_placement_mode = false
		return false

	# Add to bakery scene
	var bakery = get_tree().get_first_node_in_group("bakery")
	if bakery:
		bakery.add_child(current_preview)
	else:
		print("Warning: Bakery scene not found")
		get_tree().root.add_child(current_preview)

	print("Started placement mode: %s" % item_id)
	placement_mode_started.emit(item_id)
	return true

# Create preview object for an item
func _create_preview_object(item_id: String) -> Node3D:
	var upgrade = UpgradeManager.get_upgrade(item_id)
	if upgrade.is_empty():
		return null

	# Create container node
	var preview = Node3D.new()
	preview.name = "PlacementPreview"

	# Create visual based on item type
	var visual = _create_item_visual(item_id, upgrade)
	if visual:
		preview.add_child(visual)

	# Add collision shape for validity checking
	var area = Area3D.new()
	area.name = "CollisionCheck"
	preview.add_child(area)

	var collision_shape = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = _get_item_size(item_id, upgrade)
	collision_shape.shape = shape
	area.add_child(collision_shape)

	# Connect collision signals
	area.body_entered.connect(_on_preview_collision_entered)
	area.body_exited.connect(_on_preview_collision_exited)
	area.area_entered.connect(_on_preview_area_entered)
	area.area_exited.connect(_on_preview_area_exited)

	return preview

# Create visual representation of item (CSG placeholders for now)
func _create_item_visual(item_id: String, upgrade: Dictionary) -> Node3D:
	var subcategory = upgrade.get("subcategory", "")
	var size = _get_item_size(item_id, upgrade)

	var visual: CSGBox3D = CSGBox3D.new()
	visual.name = "Visual"
	visual.size = size
	visual.material = valid_material

	# Add label
	var label = Label3D.new()
	label.text = upgrade.get("name", item_id)
	label.position = Vector3(0, size.y / 2 + 0.2, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 32
	visual.add_child(label)

	return visual

# Get size of item based on type
func _get_item_size(item_id: String, upgrade: Dictionary) -> Vector3:
	var subcategory = upgrade.get("subcategory", "")

	# Default sizes for different items (can be customized per item later)
	match subcategory:
		"tables":
			return Vector3(1.5, 0.8, 1.0)
		"chairs":
			return Vector3(0.5, 1.0, 0.5)
		"counters":
			return Vector3(2.0, 1.0, 0.6)
		"shelving":
			return Vector3(1.0, 2.0, 0.3)
		"plants":
			return Vector3(0.4, 0.8, 0.4)
		"art":
			return Vector3(0.1, 0.8, 0.6)
		_:
			return Vector3(1.0, 1.0, 1.0)

# Update preview position to follow mouse/raycast
func _update_preview_position() -> void:
	if not current_preview:
		return

	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	# Raycast from player camera to get position
	var camera = player.get_viewport().get_camera_3d()
	if not camera:
		return

	var from = camera.global_position
	var to = from + camera.project_ray_normal(get_viewport().get_mouse_position()) * 100.0

	var space_state = player.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [current_preview]  # Don't collide with preview itself

	var result = space_state.intersect_ray(query)

	if result:
		var pos = result.position

		# Snap to grid
		pos.x = round(pos.x / GRID_SIZE) * GRID_SIZE
		pos.z = round(pos.z / GRID_SIZE) * GRID_SIZE
		pos.y = PLACEMENT_HEIGHT

		current_preview.global_position = pos
		current_preview.rotation.y = current_rotation

# Check if current placement is valid
func _check_placement_validity() -> void:
	if not current_preview:
		return

	var area = current_preview.get_node_or_null("CollisionCheck")
	if not area:
		return

	# Check for overlapping bodies or areas
	var overlapping_bodies = area.get_overlapping_bodies()
	var overlapping_areas = area.get_overlapping_areas()

	# Valid if no collisions
	var was_valid = is_placement_valid
	is_placement_valid = overlapping_bodies.is_empty() and overlapping_areas.is_empty()

	# Update visual
	var visual = current_preview.get_node_or_null("Visual")
	if visual and visual is CSGBox3D:
		visual.material = valid_material if is_placement_valid else invalid_material

	# Emit signal if validity changed
	if was_valid != is_placement_valid:
		placement_validity_changed.emit(is_placement_valid)

# Collision callbacks
var collision_count: int = 0

func _on_preview_collision_entered(_body: Node3D) -> void:
	collision_count += 1

func _on_preview_collision_exited(_body: Node3D) -> void:
	collision_count = max(0, collision_count - 1)

func _on_preview_area_entered(_area: Area3D) -> void:
	collision_count += 1

func _on_preview_area_exited(_area: Area3D) -> void:
	collision_count = max(0, collision_count - 1)

# Rotate preview
func rotate_preview(angle: float) -> void:
	current_rotation += angle
	if current_preview:
		current_preview.rotation.y = current_rotation

# Confirm placement
func confirm_placement() -> bool:
	if not is_placement_valid:
		print("Cannot place here - invalid location")
		return false

	if not current_preview:
		return false

	# Create permanent object
	var placed_node = _create_permanent_object(current_item_id)
	if not placed_node:
		print("Failed to create permanent object")
		return false

	# Set position and rotation
	placed_node.global_position = current_preview.global_position
	placed_node.rotation.y = current_rotation

	# Add to bakery scene
	var bakery = get_tree().get_first_node_in_group("bakery")
	if bakery:
		bakery.add_child(placed_node)
	else:
		get_tree().root.add_child(placed_node)

	# Track placed object
	placed_objects.append({
		"item_id": current_item_id,
		"position": placed_node.global_position,
		"rotation": current_rotation,
		"node": placed_node
	})

	print("Placed: %s at %v" % [current_item_id, placed_node.global_position])
	item_placed.emit(current_item_id, placed_node.global_position, current_rotation)

	# End placement mode
	end_placement()
	return true

# Create permanent object (with full materials, collision, etc.)
func _create_permanent_object(item_id: String) -> Node3D:
	var upgrade = UpgradeManager.get_upgrade(item_id)
	if upgrade.is_empty():
		return null

	# Load PlacedObject script
	var placed_object_script = load("res://scripts/building/placed_object.gd")

	var obj = Node3D.new()
	obj.name = item_id
	obj.set_script(placed_object_script)
	obj.item_id = item_id

	# Create visual
	var visual = _create_permanent_visual(item_id, upgrade)
	if visual:
		obj.add_child(visual)

	# Add collision for interaction
	var area = Area3D.new()
	area.name = "InteractionArea"
	obj.add_child(area)

	var collision_shape = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = _get_item_size(item_id, upgrade)
	collision_shape.shape = shape
	area.add_child(collision_shape)

	return obj

# Create permanent visual (proper materials, not preview)
func _create_permanent_visual(item_id: String, upgrade: Dictionary) -> Node3D:
	var subcategory = upgrade.get("subcategory", "")
	var size = _get_item_size(item_id, upgrade)

	var visual = CSGBox3D.new()
	visual.name = "Visual"
	visual.size = size

	# Use proper material based on item type
	var material = StandardMaterial3D.new()

	# Color based on subcategory
	match subcategory:
		"tables":
			material.albedo_color = Color(0.6, 0.4, 0.2)  # Wood brown
		"chairs":
			material.albedo_color = Color(0.5, 0.3, 0.15)  # Darker wood
		"counters":
			material.albedo_color = Color(0.7, 0.7, 0.7)  # Gray
		"shelving":
			material.albedo_color = Color(0.8, 0.8, 0.8)  # Light gray
		"plants":
			material.albedo_color = Color(0.2, 0.6, 0.2)  # Green
		"art":
			material.albedo_color = Color(0.9, 0.9, 0.7)  # Cream
		_:
			material.albedo_color = Color(0.8, 0.8, 0.8)

	visual.material = material

	return visual

# Cancel placement
func cancel_placement() -> void:
	end_placement()
	print("Placement cancelled")

# End placement mode
func end_placement() -> void:
	if current_preview:
		current_preview.queue_free()
		current_preview = null

	is_in_placement_mode = false
	current_item_id = ""
	current_rotation = 0.0
	is_placement_valid = false
	collision_count = 0

	placement_mode_ended.emit()

# Destroy a placed object and refund
func destroy_object(obj: Node3D) -> bool:
	# Find in placed_objects
	var index = -1
	for i in range(placed_objects.size()):
		if placed_objects[i].node == obj:
			index = i
			break

	if index == -1:
		print("Object not found in placed objects")
		return false

	var data = placed_objects[index]
	var item_id = data.item_id
	var upgrade = UpgradeManager.get_upgrade(item_id)

	if upgrade.is_empty():
		print("Upgrade not found for: %s" % item_id)
		return false

	# Full refund
	var refund = upgrade.get("cost", 0.0)
	EconomyManager.add_money(refund, "Refund: %s" % upgrade.get("name", item_id))

	# Remove from tracking
	placed_objects.remove_at(index)

	# Remove from scene
	obj.queue_free()

	print("Destroyed: %s - Refunded $%.2f" % [item_id, refund])
	item_destroyed.emit(item_id, refund)

	return true

# Get all placed objects of a specific item type
func get_placed_objects_by_id(item_id: String) -> Array:
	var result: Array = []
	for data in placed_objects:
		if data.item_id == item_id:
			result.append(data)
	return result

# Save/Load
func get_save_data() -> Dictionary:
	var saved_objects: Array = []

	for data in placed_objects:
		saved_objects.append({
			"item_id": data.item_id,
			"position": {
				"x": data.position.x,
				"y": data.position.y,
				"z": data.position.z
			},
			"rotation": data.rotation
		})

	return {
		"placed_objects": saved_objects
	}

func load_save_data(data: Dictionary) -> void:
	# Clear existing objects
	for obj_data in placed_objects:
		if obj_data.node:
			obj_data.node.queue_free()
	placed_objects.clear()

	# Load saved objects
	if data.has("placed_objects"):
		for obj_data in data.placed_objects:
			var item_id = obj_data.item_id
			var pos = Vector3(obj_data.position.x, obj_data.position.y, obj_data.position.z)
			var rot = obj_data.rotation

			# Create object
			var placed_node = _create_permanent_object(item_id)
			if placed_node:
				placed_node.global_position = pos
				placed_node.rotation.y = rot

				# Add to scene
				var bakery = get_tree().get_first_node_in_group("bakery")
				if bakery:
					bakery.add_child(placed_node)
				else:
					get_tree().root.add_child(placed_node)

				# Track
				placed_objects.append({
					"item_id": item_id,
					"position": pos,
					"rotation": rot,
					"node": placed_node
				})

	print("Loaded %d placed objects" % placed_objects.size())

func reset() -> void:
	"""Reset all placed objects (for new game)"""
	for obj_data in placed_objects:
		if obj_data.node:
			obj_data.node.queue_free()
	placed_objects.clear()

	if is_in_placement_mode:
		end_placement()

	print("BuildingManager reset")
