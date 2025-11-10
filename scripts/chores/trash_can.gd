extends Node3D

# TrashCan - Chore station for emptying trash with fill-over-time mechanic

signal trash_filled()
signal trash_emptied()

@export var time_to_fill: float = 300.0  # 5 minutes in-game to fill (affected by time scale)
@export var empty_time: float = 3.0  # 3 seconds to hold E and empty

# Node references
@onready var interaction_area: Area3D = $InteractionArea
@onready var empty_model: Node3D = $EmptyModel
@onready var full_model: Node3D = $FullModel
@onready var progress_bar_container: Node3D = $ProgressBarContainer
@onready var progress_bar: ProgressBar = $ProgressBarContainer/SubViewport/ProgressBar
@onready var interact_prompt: Node3D = $InteractPrompt

# State
enum TrashState { EMPTY, FILLING, FULL, EMPTYING }
var current_state: TrashState = TrashState.EMPTY
var fill_timer: float = 0.0
var empty_timer: float = 0.0
var player_nearby: Node3D = null
var is_emptying: bool = false  # Keep for compatibility

func _ready() -> void:
	# Connect interaction area
	if interaction_area:
		interaction_area.body_entered.connect(_on_body_entered)
		interaction_area.body_exited.connect(_on_body_exited)

	# Hide progress bar initially
	if progress_bar_container:
		progress_bar_container.visible = false

	# Set initial model visibility
	update_model_visibility()

	# Start filling timer automatically
	start_filling()

	print("Trash can ready: ", name)

func _process(delta: float) -> void:
	if GameManager.is_game_paused():
		return

	var scaled_delta = delta * GameManager.get_time_scale()

	match current_state:
		TrashState.EMPTY:
			# Trash stays empty briefly, waiting to start filling
			pass

		TrashState.FILLING:
			# Trash gradually fills over time
			fill_timer += scaled_delta
			if fill_timer >= time_to_fill:
				become_full()

		TrashState.FULL:
			# Wait for player to start holding E
			if player_nearby and Input.is_action_pressed("interact"):
				# Just started holding - switch to emptying state
				start_emptying_progress()

		TrashState.EMPTYING:
			# Player is actively emptying trash
			if player_nearby and Input.is_action_pressed("interact"):
				# Continue emptying
				empty_timer += delta  # Use real delta, not scaled (player action)

				# Update progress bar
				if progress_bar:
					var progress_percent = (empty_timer / empty_time) * 100.0
					progress_bar.value = progress_percent

				if empty_timer >= empty_time:
					complete_emptying()
			else:
				# Player released E or walked away - cancel emptying
				stop_emptying_progress()

func start_filling() -> void:
	"""Start the trash filling process"""
	if current_state == TrashState.EMPTY:
		current_state = TrashState.FILLING
		fill_timer = 0.0
		print("[TrashCan] Started filling...")

func become_full() -> void:
	"""Trash has become full"""
	current_state = TrashState.FULL
	fill_timer = 0.0
	update_model_visibility()
	update_prompt()
	trash_filled.emit()
	print("[TrashCan] Trash is now FULL! Take it out!")

func start_emptying_progress() -> void:
	"""Player started holding E to empty trash"""
	current_state = TrashState.EMPTYING
	is_emptying = true

	# Show progress bar
	if progress_bar_container:
		progress_bar_container.visible = true
	if progress_bar:
		progress_bar.value = 0.0

	print("[TrashCan] Player started emptying trash...")

func stop_emptying_progress() -> void:
	"""Player released E before completing"""
	if current_state == TrashState.EMPTYING:
		current_state = TrashState.FULL
		is_emptying = false
		empty_timer = 0.0

		# Hide progress bar
		if progress_bar_container:
			progress_bar_container.visible = false
		if progress_bar:
			progress_bar.value = 0.0

		print("[TrashCan] Player stopped emptying trash")

func _on_body_entered(body: Node3D) -> void:
	if body.has_method("get_inventory_id"):
		player_nearby = body
		update_prompt()

func _on_body_exited(body: Node3D) -> void:
	if body == player_nearby:
		player_nearby = null
		is_emptying = false
		update_prompt()

		# Hide progress bar if player leaves
		if progress_bar_container:
			progress_bar_container.visible = false
		empty_timer = 0.0

func get_interaction_prompt() -> String:
	if current_state == TrashState.FULL:
		return "[Hold E] Take out trash"
	elif current_state == TrashState.FILLING:
		return "Trash is filling..."
	return ""

func interact(player: Node3D) -> void:
	"""Called when player presses E - now handled by holding E in _process"""
	# Note: Hold-to-interact is now handled in _process function
	# This is kept for compatibility but the main interaction is hold-based
	pass

func complete_emptying() -> void:
	"""Player has successfully emptied the trash"""
	print("✓ Trash emptied! Good job!")

	# Complete chore in CleanlinessManager if it exists
	if CleanlinessManager:
		CleanlinessManager.complete_chore("trash")

	trash_emptied.emit()

	# Reset state
	current_state = TrashState.EMPTY
	is_emptying = false
	empty_timer = 0.0
	update_model_visibility()
	update_prompt()

	# Hide progress bar
	if progress_bar_container:
		progress_bar_container.visible = false
	if progress_bar:
		progress_bar.value = 0.0

	# Start filling again after a delay
	await get_tree().create_timer(5.0).timeout
	if current_state == TrashState.EMPTY:
		start_filling()

func update_model_visibility() -> void:
	"""Show the correct model based on state"""
	if empty_model:
		empty_model.visible = (current_state == TrashState.EMPTY or current_state == TrashState.FILLING)
	if full_model:
		full_model.visible = (current_state == TrashState.FULL or current_state == TrashState.EMPTYING)

func update_prompt() -> void:
	"""Update the interaction prompt based on state"""
	if not player_nearby:
		if interact_prompt:
			interact_prompt.visible = false
		return

	if current_state == TrashState.FULL or current_state == TrashState.EMPTYING:
		if interact_prompt:
			interact_prompt.visible = true
	else:
		if interact_prompt:
			interact_prompt.visible = false

func get_progress() -> float:
	"""Get emptying progress (for UI/automation)"""
	if not is_emptying:
		return 0.0
	return empty_timer / empty_time

# ============================================================================
# AUTOMATION METHODS (for staff AI)
# ============================================================================

func needs_cleaning() -> bool:
	"""Check if this station needs cleaning (called by Cleaner AI)"""
	return current_state == TrashState.FULL and not is_emptying

func get_cleanup_duration() -> float:
	"""Get how long this task takes (called by Cleaner AI)"""
	return empty_time

func auto_clean(quality_mult: float = 1.0) -> bool:
	"""Clean automatically (called by Cleaner AI)"""
	if not needs_cleaning():
		return false

	# Instant completion for AI (already spent time in AI logic)
	current_state = TrashState.EMPTY
	is_emptying = false
	empty_timer = 0.0
	update_model_visibility()

	if CleanlinessManager:
		CleanlinessManager.complete_chore("trash")

	print("[TrashCan] Auto-emptied trash (quality: ", int(quality_mult * 100), "%)")
	trash_emptied.emit()

	# Start filling again after a delay
	await get_tree().create_timer(5.0).timeout
	if current_state == TrashState.EMPTY:
		start_filling()

	return true

# ============================================================================
# DEBUG HELPERS
# ============================================================================

func force_fill() -> void:
	"""Debug: Force trash to become full immediately"""
	become_full()
