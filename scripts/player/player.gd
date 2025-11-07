extends CharacterBody3D

# Player controller with WASD movement, mouse look, and interaction

# Movement settings
@export var move_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.003

# Camera settings
@export var camera_distance: float = 4.0
@export var camera_height: float = 2.0

# Interaction settings
@export var interaction_distance: float = 3.0

# Node references
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var interaction_ray: RayCast3D = $CameraPivot/InteractionRay

# State
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var current_interactable: Node3D = null

func _ready() -> void:
	# Capture mouse for camera control
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	print("Player ready")

func _input(event: InputEvent) -> void:
	# Mouse look
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera_pivot.rotate_x(-event.relative.y * mouse_sensitivity)
		# Clamp camera pitch to avoid flipping
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, -PI/3, PI/3)

	# Toggle mouse capture
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# Interaction
	if event.is_action_pressed("interact") and current_interactable:
		interact_with(current_interactable)

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

	# Calculate movement direction relative to player rotation
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

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

	# Check for interactables
	check_for_interactable()

func check_for_interactable() -> void:
	if not interaction_ray:
		return

	if interaction_ray.is_colliding():
		var collider = interaction_ray.get_collider()
		if collider and collider.has_method("get_interaction_prompt"):
			if current_interactable != collider:
				current_interactable = collider
				print("Can interact with: ", collider.name)
		else:
			current_interactable = null
	else:
		current_interactable = null

func interact_with(interactable: Node3D) -> void:
	if interactable.has_method("interact"):
		print("Interacting with: ", interactable.name)
		interactable.interact(self)

func get_inventory_id() -> String:
	return "player"
