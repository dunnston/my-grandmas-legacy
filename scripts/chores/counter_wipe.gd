extends Node3D

# CounterWipe - Chore station for wiping counters

signal counters_wiped()

@export var wipe_time: float = 15.0  # 15 seconds to wipe counters

# Node references
@onready var interaction_area: Area3D = $InteractionArea
@onready var mesh: CSGBox3D = $CounterMesh

# State
var is_wiping: bool = false
var wipe_timer: float = 0.0
var player_nearby: Node3D = null

func _ready() -> void:
	# Connect interaction area
	if interaction_area:
		interaction_area.body_entered.connect(_on_body_entered)
		interaction_area.body_exited.connect(_on_body_exited)

	print("Counter wipe station ready: ", name)

func _process(delta: float) -> void:
	if is_wiping and not GameManager.is_game_paused():
		wipe_timer += delta * GameManager.get_time_scale()

		if wipe_timer >= wipe_time:
			complete_wiping()

func _on_body_entered(body: Node3D) -> void:
	if body.has_method("get_inventory_id"):
		player_nearby = body
		if CleanlinessManager.is_chore_completed("counters"):
			print("[E] Counters are already clean")
		else:
			print("[E] to wipe counters")

func _on_body_exited(body: Node3D) -> void:
	if body == player_nearby:
		player_nearby = null

func get_interaction_prompt() -> String:
	if CleanlinessManager.is_chore_completed("counters"):
		return "Counters are clean"
	return "[E] Wipe Counters"

func interact(player: Node3D) -> void:
	# Check if cleanup phase
	if GameManager.get_current_phase() != GameManager.Phase.CLEANUP:
		print("Can only wipe counters during cleanup phase!")
		return

	# Check if already completed
	if CleanlinessManager.is_chore_completed("counters"):
		print("Counters are already clean!")
		return

	# Check if already wiping
	if is_wiping:
		print("Already wiping! Time remaining: %.1f seconds" % (wipe_time - wipe_timer))
		return

	# Start wiping
	start_wiping()

func start_wiping() -> void:
	is_wiping = true
	wipe_timer = 0.0

	print("\n🧽 Wiping counters...")
	print("This will take %.0f seconds" % wipe_time)

	# Visual feedback (make counter glow - being cleaned)
	if mesh:
		var mat = mesh.material
		if mat:
			mat.emission_enabled = true
			mat.emission = Color(0.9, 0.9, 1.0)  # Light blue - clean
			mat.emission_energy = 0.4

func complete_wiping() -> void:
	print("✓ Counters wiped!")

	# Complete chore in CleanlinessManager
	CleanlinessManager.complete_chore("counters")

	counters_wiped.emit()

	# Reset state
	is_wiping = false
	wipe_timer = 0.0

	# Visual feedback (turn off glow)
	if mesh:
		var mat = mesh.material
		if mat:
			mat.emission_enabled = false

func get_progress() -> float:
	if not is_wiping:
		return 0.0
	return wipe_timer / wipe_time

# ============================================================================
# AUTOMATION METHODS (for staff AI)
# ============================================================================

func needs_cleaning() -> bool:
	"""Check if this station needs cleaning (called by Cleaner AI)"""
	return not CleanlinessManager.is_chore_completed("counters") and not is_wiping

func get_cleanup_duration() -> float:
	"""Get how long this task takes (called by Cleaner AI)"""
	return wipe_time

func auto_clean(quality_mult: float = 1.0) -> bool:
	"""Clean automatically (called by Cleaner AI)"""
	if not needs_cleaning():
		return false

	# Instant completion for AI (already spent time in AI logic)
	CleanlinessManager.complete_chore("counters")
	print("[CounterWipe] Auto-wiped counters (quality: ", int(quality_mult * 100), "%)")
	counters_wiped.emit()
	return true
