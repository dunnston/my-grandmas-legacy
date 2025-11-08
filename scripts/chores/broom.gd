extends Node3D

# Broom - Chore station for sweeping the floor

signal floor_swept()

@export var sweep_time: float = 20.0  # 20 seconds to sweep floor

# Node references
@onready var interaction_area: Area3D = $InteractionArea
@onready var mesh: CSGCylinder3D = $BroomMesh

# State
var is_sweeping: bool = false
var sweep_timer: float = 0.0
var player_nearby: Node3D = null

func _ready() -> void:
	# Connect interaction area
	if interaction_area:
		interaction_area.body_entered.connect(_on_body_entered)
		interaction_area.body_exited.connect(_on_body_exited)

	print("Broom ready: ", name)

func _process(delta: float) -> void:
	if is_sweeping and not GameManager.is_game_paused():
		sweep_timer += delta * GameManager.get_time_scale()

		if sweep_timer >= sweep_time:
			complete_sweeping()

func _on_body_entered(body: Node3D) -> void:
	if body.has_method("get_inventory_id"):
		player_nearby = body
		if CleanlinessManager.is_chore_completed("floor"):
			print("[E] Floor is already swept")
		else:
			print("[E] to sweep floor")

func _on_body_exited(body: Node3D) -> void:
	if body == player_nearby:
		player_nearby = null

func get_interaction_prompt() -> String:
	if CleanlinessManager.is_chore_completed("floor"):
		return "Floor is clean"
	return "[E] Sweep Floor"

func interact(player: Node3D) -> void:
	# Check if cleanup phase
	if GameManager.get_current_phase() != GameManager.Phase.CLEANUP:
		print("Can only sweep during cleanup phase!")
		return

	# Check if already completed
	if CleanlinessManager.is_chore_completed("floor"):
		print("Floor is already swept!")
		return

	# Check if already sweeping
	if is_sweeping:
		print("Already sweeping! Time remaining: %.1f seconds" % (sweep_time - sweep_timer))
		return

	# Start sweeping
	start_sweeping()

func start_sweeping() -> void:
	is_sweeping = true
	sweep_timer = 0.0

	print("\n🧹 Sweeping floor...")
	print("This will take %.0f seconds" % sweep_time)

	# Visual feedback (make broom glow - in use)
	if mesh:
		var mat = mesh.material
		if mat:
			mat.emission_enabled = true
			mat.emission = Color(0.8, 0.7, 0.4)  # Brownish for broom
			mat.emission_energy = 0.4

func complete_sweeping() -> void:
	print("✓ Floor swept!")

	# Complete chore in CleanlinessManager
	CleanlinessManager.complete_chore("floor")

	floor_swept.emit()

	# Reset state
	is_sweeping = false
	sweep_timer = 0.0

	# Visual feedback (turn off glow)
	if mesh:
		var mat = mesh.material
		if mat:
			mat.emission_enabled = false

func get_progress() -> float:
	if not is_sweeping:
		return 0.0
	return sweep_timer / sweep_time
