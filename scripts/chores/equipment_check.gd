extends Node3D

# EquipmentCheck - Chore station for equipment maintenance check

signal equipment_checked()

@export var check_time: float = 10.0  # 10 seconds to check equipment

# Node references
@onready var interaction_area: Area3D = $InteractionArea
@onready var mesh: CSGBox3D = $ChecklistMesh

# State
var is_checking: bool = false
var check_timer: float = 0.0
var player_nearby: Node3D = null

func _ready() -> void:
	# Connect interaction area
	if interaction_area:
		interaction_area.body_entered.connect(_on_body_entered)
		interaction_area.body_exited.connect(_on_body_exited)

	print("Equipment check station ready: ", name)

func _process(delta: float) -> void:
	if is_checking and not GameManager.is_game_paused():
		check_timer += delta * GameManager.get_time_scale()

		if check_timer >= check_time:
			complete_checking()

func _on_body_entered(body: Node3D) -> void:
	if body.has_method("get_inventory_id"):
		player_nearby = body
		if CleanlinessManager.is_chore_completed("equipment"):
			print("[E] Equipment already checked")
		else:
			print("[E] to check equipment")

func _on_body_exited(body: Node3D) -> void:
	if body == player_nearby:
		player_nearby = null

func get_interaction_prompt() -> String:
	if CleanlinessManager.is_chore_completed("equipment"):
		return "Equipment checked"
	return "[E] Check Equipment"

func interact(player: Node3D) -> void:
	# Check if cleanup phase
	if GameManager.is_shop_open():
		print("Can only clean when shop is closed!")
		return

	# Check if already completed
	if CleanlinessManager.is_chore_completed("equipment"):
		print("Equipment already checked!")
		return

	# Check if already checking
	if is_checking:
		print("Already checking! Time remaining: %.1f seconds" % (check_time - check_timer))
		return

	# Start checking
	start_checking()

func start_checking() -> void:
	is_checking = true
	check_timer = 0.0

	print("\n🔧 Checking equipment...")
	print("Inspecting ovens, mixers, and displays...")
	print("This will take %.0f seconds" % check_time)

	# Visual feedback (make checklist glow)
	if mesh:
		var mat = mesh.material
		if mat:
			mat.emission_enabled = true
			mat.emission = Color(0.3, 0.8, 0.3)  # Green - maintenance
			mat.emission_energy = 0.4

func complete_checking() -> void:
	print("✓ Equipment checked!")
	print("  All equipment is functioning properly.")

	# Complete chore in CleanlinessManager
	CleanlinessManager.complete_chore("equipment")

	equipment_checked.emit()

	# Reset state
	is_checking = false
	check_timer = 0.0

	# Visual feedback (turn off glow)
	if mesh:
		var mat = mesh.material
		if mat:
			mat.emission_enabled = false

func get_progress() -> float:
	if not is_checking:
		return 0.0
	return check_timer / check_time
