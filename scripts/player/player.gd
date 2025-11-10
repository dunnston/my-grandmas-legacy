extends CharacterBody3D

# Player controller with WASD movement, mouse camera, and interaction

# Movement settings
@export var move_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var jump_velocity: float = 4.5
@export var rotation_speed: float = 10.0  # How fast model rotates to face movement direction

# Camera settings
@export var camera_distance: float = 4.0
@export var camera_height: float = 2.0
@export var mouse_sensitivity: float = 0.003

# Interaction settings
@export var interaction_distance: float = 3.0

# Node references
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var interaction_ray: RayCast3D = $CameraPivot/InteractionRay
@onready var model_root: Node3D = $ModelRoot
@onready var idle_model: Node3D = $ModelRoot/IdleModel
@onready var walk_model: Node3D = $ModelRoot/WalkModel
@onready var run_model: Node3D = $ModelRoot/RunModel

# State
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var current_interactable: Node3D = null
var current_animation_state: String = "idle"

func _ready() -> void:
	# Capture mouse for gameplay (can toggle with ESC)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Start with idle animation
	set_animation_state("idle")
	print("Player ready")

func _input(event: InputEvent) -> void:
	# Mouse look - rotate camera around player
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# Rotate player body left/right (camera follows)
		rotate_y(-event.relative.x * mouse_sensitivity)
		# Rotate camera pivot up/down
		camera_pivot.rotate_x(-event.relative.y * mouse_sensitivity)
		# Clamp camera pitch to avoid flipping
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, -PI/3, PI/3)

	# Toggle mouse visibility with ESC
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# Interaction
	if event.is_action_pressed("interact") and current_interactable:
		interact_with(current_interactable)

	# Quick bag access (press B to open bag during checkout)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_B:
			_try_open_bag()

func _physics_process(delta: float) -> void:
	# Don't move if game is paused
	if GameManager.is_game_paused():
		return

	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Jump (optional for now)
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity

	# Get movement input
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")

	# Calculate movement direction relative to camera (fixed)
	# Since camera is fixed, we use camera's rotation basis
	var cam_basis = camera.global_transform.basis
	var forward = cam_basis.z   # Direction away from camera (W = away, S = toward)
	var right = cam_basis.x     # Camera's right direction

	# Project onto ground plane (remove Y component)
	forward.y = 0
	right.y = 0
	forward = forward.normalized()
	right = right.normalized()

	# Calculate direction based on input
	var direction: Vector3 = (right * input_dir.x + forward * input_dir.y).normalized()

	# Apply movement
	if direction:
		var current_speed = sprint_speed if Input.is_action_pressed("sprint") else move_speed
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		# Deceleration
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)

	move_and_slide()

	# Rotate model to face movement direction
	rotate_model_to_movement(direction, delta)

	# Update animation based on movement
	update_animation_state(direction)

	# Check for interactables
	check_for_interactable()

func check_for_interactable() -> void:
	# Find all equipment in scene that has player_nearby set to this player
	# If multiple are in range, choose the closest one
	var found_interactable: Node3D = null
	var closest_distance: float = INF

	# Get all nodes in equipment group
	var equipment_nodes = get_tree().get_nodes_in_group("equipment")
	for equipment in equipment_nodes:
		# Check if this equipment has player_nearby property and it's set to us
		if "player_nearby" in equipment and equipment.player_nearby == self:
			if equipment.has_method("interact"):
				# Calculate distance to this equipment
				var distance = global_position.distance_to(equipment.global_position)
				if distance < closest_distance:
					closest_distance = distance
					found_interactable = equipment

	# If no equipment found via group, check individual equipment types
	if not found_interactable:
		# Check all possible equipment types (mixing bowl, oven, display case, etc.)
		var all_nodes = get_tree().get_nodes_in_group("interactable")
		for node in all_nodes:
			if "player_nearby" in node and node.player_nearby == self:
				if node.has_method("interact"):
					var distance = global_position.distance_to(node.global_position)
					if distance < closest_distance:
						closest_distance = distance
						found_interactable = node

	# Update current_interactable
	if found_interactable:
		if current_interactable != found_interactable:
			current_interactable = found_interactable
			#print("Can interact with: ", current_interactable.name)
	else:
		current_interactable = null

func interact_with(interactable: Node3D) -> void:
	if interactable.has_method("interact"):
		print("Interacting with: ", interactable.name)
		interactable.interact(self)

func _try_open_bag() -> void:
	"""Try to open the bag UI (called when player presses B)"""
	print("Player: B key pressed - trying to open bag")

	# Find the bag station in the scene
	var bag_station = get_tree().get_first_node_in_group("bag_station")
	print("Player: Found bag station in group: ", bag_station != null)

	if not bag_station:
		# Try finding it as a child of Equipment
		var equipment = get_tree().get_first_node_in_group("equipment")
		if equipment:
			print("Player: Trying to find BagStation under Equipment")
			bag_station = equipment.get_node_or_null("BagStation")
			print("Player: Found BagStation: ", bag_station != null)

	if bag_station and bag_station.has_method("open_bag_ui"):
		# Check if player has items in carry inventory
		var carry_inventory = InventoryManager.get_inventory("player_carry")
		print("Player: Carry inventory has %d items" % carry_inventory.size())

		if carry_inventory.is_empty():
			print("No items to bag - collect items from the display case first")
			return

		print("Player: Calling bag_station.open_bag_ui()")
		bag_station.open_bag_ui()
	else:
		print("ERROR: Bag station not found or missing open_bag_ui method!")
		print("  bag_station exists: ", bag_station != null)
		if bag_station:
			print("  has open_bag_ui method: ", bag_station.has_method("open_bag_ui"))

func get_inventory_id() -> String:
	return "player"

func rotate_model_to_movement(direction: Vector3, delta: float) -> void:
	# Only rotate if there's movement
	if direction.length() > 0.1:
		# Calculate the target angle from movement direction in world space
		# atan2 gives us the angle in radians
		var target_angle_world = atan2(direction.x, direction.z)

		# Convert to local space (relative to player's rotation)
		# Since camera rotation rotates the player body, we need to subtract that
		var player_angle = rotation.y
		var target_angle_local = target_angle_world - player_angle

		# Get current model rotation (local)
		var current_angle = model_root.rotation.y

		# Smoothly interpolate to target angle
		var new_angle = lerp_angle(current_angle, target_angle_local, rotation_speed * delta)

		# Apply rotation to model
		model_root.rotation.y = new_angle

func update_animation_state(direction: Vector3) -> void:
	var new_state: String = "idle"

	if direction.length() > 0.1:
		# Player is moving
		if Input.is_action_pressed("sprint"):
			new_state = "run"
		else:
			new_state = "walk"
	else:
		# Player is idle
		new_state = "idle"

	# Only change if state is different
	if new_state != current_animation_state:
		set_animation_state(new_state)

func set_animation_state(state: String) -> void:
	current_animation_state = state

	# Hide all models first
	idle_model.visible = false
	walk_model.visible = false
	run_model.visible = false

	# Show and play the appropriate model
	match state:
		"idle":
			idle_model.visible = true
			play_model_animation(idle_model)
		"walk":
			walk_model.visible = true
			play_model_animation(walk_model)
		"run":
			run_model.visible = true
			play_model_animation(run_model)

func play_model_animation(model: Node3D) -> void:
	# Each GLB model has its own AnimationPlayer
	var anim_player = model.get_node_or_null("AnimationPlayer")
	if anim_player and anim_player is AnimationPlayer:
		# Get the first animation in the player
		var anim_list = anim_player.get_animation_list()
		if anim_list.size() > 0:
			anim_player.play(anim_list[0])
			# Loop the animation
			if anim_player.has_animation(anim_list[0]):
				var animation = anim_player.get_animation(anim_list[0])
				animation.loop_mode = Animation.LOOP_LINEAR
