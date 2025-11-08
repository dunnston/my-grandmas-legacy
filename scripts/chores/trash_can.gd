extends Node3D

# TrashCan - Chore station for emptying trash

signal trash_emptied()

@export var empty_time: float = 10.0  # 10 seconds to empty trash

# Node references
@onready var interaction_area: Area3D = $InteractionArea
@onready var mesh: CSGCylinder3D = $TrashMesh

# State
var is_emptying: bool = false
var empty_timer: float = 0.0
var player_nearby: Node3D = null

func _ready() -> void:
	# Connect interaction area
	if interaction_area:
		interaction_area.body_entered.connect(_on_body_entered)
		interaction_area.body_exited.connect(_on_body_exited)

	print("Trash can ready: ", name)

func _process(delta: float) -> void:
	if is_emptying and not GameManager.is_game_paused():
		empty_timer += delta * GameManager.get_time_scale()

		if empty_timer >= empty_time:
			complete_emptying()

func _on_body_entered(body: Node3D) -> void:
	if body.has_method("get_inventory_id"):
		player_nearby = body
		if CleanlinessManager.is_chore_completed("trash"):
			print("[E] Trash is already empty")
		else:
			print("[E] to empty trash")

func _on_body_exited(body: Node3D) -> void:
	if body == player_nearby:
		player_nearby = null

func get_interaction_prompt() -> String:
	if CleanlinessManager.is_chore_completed("trash"):
		return "Trash is empty"
	return "[E] Empty Trash"

func interact(player: Node3D) -> void:
	# Check if cleanup phase
	if GameManager.get_current_phase() != GameManager.Phase.CLEANUP:
		print("Can only empty trash during cleanup phase!")
		return

	# Check if already completed
	if CleanlinessManager.is_chore_completed("trash"):
		print("Trash is already empty!")
		return

	# Check if already emptying
	if is_emptying:
		print("Already emptying! Time remaining: %.1f seconds" % (empty_time - empty_timer))
		return

	# Start emptying
	start_emptying()

func start_emptying() -> void:
	is_emptying = true
	empty_timer = 0.0

	print("\n🗑️ Emptying trash...")
	print("This will take %.0f seconds" % empty_time)

	# Visual feedback (make trash can glow - being emptied)
	if mesh:
		var mat = mesh.material
		if mat:
			mat.emission_enabled = true
			mat.emission = Color(0.4, 0.4, 0.4)  # Gray for trash
			mat.emission_energy = 0.3

func complete_emptying() -> void:
	print("✓ Trash emptied!")

	# Complete chore in CleanlinessManager
	CleanlinessManager.complete_chore("trash")

	trash_emptied.emit()

	# Reset state
	is_emptying = false
	empty_timer = 0.0

	# Visual feedback (turn off glow)
	if mesh:
		var mat = mesh.material
		if mat:
			mat.emission_enabled = false

func get_progress() -> float:
	if not is_emptying:
		return 0.0
	return empty_timer / empty_time

# ============================================================================
# AUTOMATION METHODS (for staff AI)
# ============================================================================

func needs_cleaning() -> bool:
	"""Check if this station needs cleaning (called by Cleaner AI)"""
	return not CleanlinessManager.is_chore_completed("trash") and not is_emptying

func get_cleanup_duration() -> float:
	"""Get how long this task takes (called by Cleaner AI)"""
	return empty_time

func auto_clean(quality_mult: float = 1.0) -> bool:
	"""Clean automatically (called by Cleaner AI)"""
	if not needs_cleaning():
		return false

	# Instant completion for AI (already spent time in AI logic)
	CleanlinessManager.complete_chore("trash")
	print("[TrashCan] Auto-emptied trash (quality: ", int(quality_mult * 100), "%)")
	trash_emptied.emit()
	return true
