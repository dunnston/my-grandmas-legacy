extends Node3D

# Sink - Chore station for washing dishes

signal dishes_washed()

@export var wash_time: float = 15.0  # 15 seconds to wash dishes

# Node references
@onready var interaction_area: Area3D = $InteractionArea
@onready var mesh: CSGBox3D = $SinkMesh

# State
var is_washing: bool = false
var wash_timer: float = 0.0
var player_nearby: Node3D = null

func _ready() -> void:
	# Connect interaction area
	if interaction_area:
		interaction_area.body_entered.connect(_on_body_entered)
		interaction_area.body_exited.connect(_on_body_exited)

	print("Sink ready: ", name)

func _process(delta: float) -> void:
	if is_washing and not GameManager.is_game_paused():
		wash_timer += delta * GameManager.get_time_scale()

		if wash_timer >= wash_time:
			complete_washing()

func _on_body_entered(body: Node3D) -> void:
	if body.has_method("get_inventory_id"):
		player_nearby = body
		if CleanlinessManager.is_chore_completed("dishes"):
			print("[E] Dishes are already clean")
		else:
			print("[E] to wash dishes")

func _on_body_exited(body: Node3D) -> void:
	if body == player_nearby:
		player_nearby = null

func get_interaction_prompt() -> String:
	if CleanlinessManager.is_chore_completed("dishes"):
		return "Dishes are clean"
	return "[E] Wash Dishes"

func interact(player: Node3D) -> void:
	# Check if cleanup phase
	if GameManager.get_current_phase() != GameManager.Phase.CLEANUP:
		print("Can only wash dishes during cleanup phase!")
		return

	# Check if already completed
	if CleanlinessManager.is_chore_completed("dishes"):
		print("Dishes are already clean!")
		return

	# Check if already washing
	if is_washing:
		print("Already washing! Time remaining: %.1f seconds" % (wash_time - wash_timer))
		return

	# Start washing
	start_washing()

func start_washing() -> void:
	is_washing = true
	wash_timer = 0.0

	print("\n🧽 Washing dishes...")
	print("This will take %.0f seconds" % wash_time)

	# Visual feedback (make sink glow blue - water)
	if mesh:
		var mat = mesh.material
		if mat:
			mat.emission_enabled = true
			mat.emission = Color(0.3, 0.5, 1.0)  # Blue for water
			mat.emission_energy = 0.5

func complete_washing() -> void:
	print("✓ Dishes washed!")

	# Complete chore in CleanlinessManager
	CleanlinessManager.complete_chore("dishes")

	dishes_washed.emit()

	# Reset state
	is_washing = false
	wash_timer = 0.0

	# Visual feedback (turn off glow)
	if mesh:
		var mat = mesh.material
		if mat:
			mat.emission_enabled = false

func get_progress() -> float:
	if not is_washing:
		return 0.0
	return wash_timer / wash_time
