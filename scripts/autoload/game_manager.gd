extends Node

# GameManager - Singleton for managing game state, phases, and time
# Handles the daily cycle and phase transitions

# Signals
signal phase_changed(new_phase: Phase)
signal time_scale_changed(new_scale: float)
signal day_changed(new_day: int)

# Enums
enum Phase {
	BAKING,
	BUSINESS,
	CLEANUP,
	PLANNING
}

# Game state
var current_phase: Phase = Phase.BAKING
var current_day: int = 1
var time_scale: float = 1.0  # 1.0 = normal speed, 0.0 = paused, 2.0/3.0 = faster
var is_paused: bool = false

# Time tracking (game time in seconds)
var game_time: float = 0.0  # Time of day in seconds (0 = midnight, 32400 = 9 AM)
var phase_start_time: float = 0.0

# Constants
const SECONDS_PER_GAME_HOUR: float = 60.0  # 1 game hour = 60 real seconds at 1x speed
const BUSINESS_START_HOUR: int = 9  # 9 AM
const BUSINESS_END_HOUR: int = 17  # 5 PM

func _ready() -> void:
	print("GameManager initialized")
	print("Starting Day ", current_day, " - Phase: BAKING")

func _process(delta: float) -> void:
	if not is_paused:
		game_time += delta * time_scale
		# Additional time logic can be added here if needed

# Phase management
func set_phase(new_phase: Phase) -> void:
	if current_phase != new_phase:
		current_phase = new_phase
		phase_start_time = game_time
		print("Phase changed to: ", Phase.keys()[new_phase])
		phase_changed.emit(new_phase)

func start_baking_phase() -> void:
	set_phase(Phase.BAKING)
	print("=== BAKING PHASE STARTED ===")
	print("Prepare goods for the day!")

	# Stop customer spawning if it was active
	if CustomerManager:
		CustomerManager.stop_spawning()
	resume_game()

func start_business_phase() -> void:
	set_phase(Phase.BUSINESS)
	game_time = BUSINESS_START_HOUR * 3600  # Set to 9 AM
	print("=== BUSINESS PHASE STARTED ===")
	print("Shop opens at 9 AM")

	# Start spawning customers
	if CustomerManager:
		CustomerManager.start_spawning()
	resume_game()

func start_cleanup_phase() -> void:
	set_phase(Phase.CLEANUP)
	print("=== CLEANUP PHASE STARTED ===")
	print("Time to clean up!")

	# Stop customer spawning
	if CustomerManager:
		CustomerManager.stop_spawning()
		# Clear any remaining customers
		CustomerManager.clear_all_customers()

	# Auto-complete cleanup phase after brief delay (respects pause state)
	await get_tree().create_timer(2.0, false).timeout
	start_planning_phase()

func start_planning_phase() -> void:
	set_phase(Phase.PLANNING)
	print("=== PLANNING PHASE STARTED ===")
	print("Review the day and plan for tomorrow")

	# Auto-save before planning
	if SaveManager:
		SaveManager.auto_save()

	# Note: Planning menu will be opened by the bakery scene

func end_day() -> void:
	current_day += 1
	game_time = 0.0

	# Update progression manager day tracking and reputation
	if ProgressionManager:
		ProgressionManager.increment_day()

	print("=== DAY ", current_day, " ===")
	day_changed.emit(current_day)
	start_baking_phase()

# Time control
func set_time_scale(scale: float) -> void:
	time_scale = clamp(scale, 0.0, 3.0)
	print("Time scale set to: ", time_scale, "x")
	time_scale_changed.emit(time_scale)

func toggle_pause() -> void:
	is_paused = !is_paused
	if is_paused:
		print("Game PAUSED")
	else:
		print("Game RESUMED")

func pause_game() -> void:
	is_paused = true
	print("Game PAUSED")

func resume_game() -> void:
	is_paused = false
	print("Game RESUMED")

# Getters
func get_current_phase() -> Phase:
	return current_phase

func get_current_day() -> int:
	return current_day

func get_time_scale() -> float:
	return time_scale

func get_game_time_formatted() -> String:
	var hours: int = int(game_time / 3600) % 24
	var minutes: int = int(game_time / 60) % 60
	return "%02d:%02d" % [hours, minutes]

func is_game_paused() -> bool:
	return is_paused
