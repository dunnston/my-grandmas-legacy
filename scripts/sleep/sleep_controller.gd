extends Node

# SleepController - Orchestrates the full sleep sequence
# Manages transition -> mini-game -> results -> wake up

# Signals
signal sleep_sequence_complete()

# Node references (will be added as children)
var transition_overlay: Node
var sheep_minigame: Node
var results_screen: Node

# Scene references
const TRANSITION_SCENE = preload("res://scenes/sleep/sleep_transition.tscn")
const MINIGAME_SCENE = preload("res://scenes/sleep/sheep_minigame.tscn")
const RESULTS_SCENE = preload("res://scenes/sleep/sleep_results_screen.tscn")

# State
var is_sleeping: bool = false
var current_calm: float = 0.0
var current_quality: String = ""
var current_bonuses: Dictionary = {}

func _ready() -> void:
	print("[SleepController] Initializing...")

	# Create transition overlay (persistent)
	if TRANSITION_SCENE:
		transition_overlay = TRANSITION_SCENE.instantiate()
		add_child(transition_overlay)
		print("[SleepController] Transition overlay created")
	else:
		push_error("[SleepController] Failed to load TRANSITION_SCENE")
		return

	# Connect signals
	if transition_overlay:
		if transition_overlay.has_signal("fade_complete"):
			transition_overlay.fade_complete.connect(_on_fade_to_black_complete)
			print("[SleepController] Connected fade_complete signal")
		else:
			push_error("[SleepController] fade_complete signal not found")

		if transition_overlay.has_signal("wake_complete"):
			transition_overlay.wake_complete.connect(_on_wake_transition_complete)
			print("[SleepController] Connected wake_complete signal")
		else:
			push_error("[SleepController] wake_complete signal not found")

	print("[SleepController] Ready")

func start_sleep_sequence() -> void:
	"""Begin the full sleep sequence"""
	if is_sleeping:
		print("[SleepController] Already sleeping!")
		return

	print("[SleepController] Starting sleep sequence...")
	is_sleeping = true

	# Notify SleepManager
	SleepManager.initiate_sleep()

	# Phase 1: Fade to black
	if transition_overlay:
		transition_overlay.fade_to_black(2.0)

func _on_fade_to_black_complete() -> void:
	"""Called when fade to black is complete"""
	print("[SleepController] Fade to black complete, starting mini-game...")

	# Phase 2: Start mini-game
	_start_minigame()

func _start_minigame() -> void:
	"""Start the sheep counting mini-game"""
	# Create mini-game instance
	sheep_minigame = MINIGAME_SCENE.instantiate()
	add_child(sheep_minigame)

	# Connect signals
	if sheep_minigame:
		sheep_minigame.minigame_completed.connect(_on_minigame_complete)

		# Start the game
		sheep_minigame.start_minigame()

func _on_minigame_complete(calm_percentage: float) -> void:
	"""Called when mini-game is complete"""
	print("[SleepController] Mini-game complete with %.1f%% calm" % calm_percentage)

	current_calm = calm_percentage

	# Remove mini-game
	if sheep_minigame:
		sheep_minigame.queue_free()
		sheep_minigame = null

	# Phase 3: Complete sleep in SleepManager
	SleepManager.complete_sleep(calm_percentage)

	# Get quality and bonuses from SleepManager
	current_quality = SleepManager._get_quality_name(SleepManager.current_sleep_quality)
	current_bonuses = SleepManager._calculate_bonuses()

	# Phase 4: Show results
	_show_results()

func _show_results() -> void:
	"""Show sleep results screen"""
	print("[SleepController] Showing results...")

	# Create results screen
	results_screen = RESULTS_SCENE.instantiate()
	add_child(results_screen)

	# Connect signals
	if results_screen:
		results_screen.continue_pressed.connect(_on_results_continue)

		# Show results
		results_screen.show_results(current_calm, current_quality, current_bonuses)

func _on_results_continue() -> void:
	"""Called when player clicks continue on results"""
	print("[SleepController] Continuing from results...")

	# Remove results screen
	if results_screen:
		results_screen.queue_free()
		results_screen = null

	# Phase 5: Fade from black (wake up)
	if transition_overlay:
		transition_overlay.fade_from_black(2.0)

func _on_wake_transition_complete() -> void:
	"""Called when wake up transition is complete"""
	print("[SleepController] Wake transition complete")

	is_sleeping = false

	# Emit completion
	sleep_sequence_complete.emit()

	# Player should now be back in apartment at morning time

func cleanup() -> void:
	"""Clean up any active sleep UI"""
	if sheep_minigame:
		sheep_minigame.queue_free()
		sheep_minigame = null

	if results_screen:
		results_screen.queue_free()
		results_screen = null

	is_sleeping = false
