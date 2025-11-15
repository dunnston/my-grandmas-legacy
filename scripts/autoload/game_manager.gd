extends Node

# GameManager - Singleton for managing game state and time
# Handles shop open/closed states and continuous 24-hour time
#
# BALANCE CONFIG INTEGRATION:
# Time constants are now loaded from BalanceConfig.
# To adjust timing balance, modify scripts/autoload/balance_config.gd

# Signals
signal shop_state_changed(is_open: bool)
signal time_scale_changed(new_scale: float)
signal day_changed(new_day: int)
signal hour_changed(new_hour: int)

# Enums
enum ShopState {
	CLOSED,
	OPEN
}

# Game state
var shop_state: ShopState = ShopState.CLOSED
var current_day: int = 1
var time_scale: float = 1.0  # 1.0 = normal speed, 0.0 = paused, 2.0/3.0 = faster
var is_paused: bool = false

# Time tracking (game time in seconds from midnight 0:00)
var game_time: float = 21600.0  # Start at 6 AM (6 * 3600)
var previous_hour: int = 6

# Time constants - loaded from BalanceConfig
var SECONDS_PER_GAME_HOUR: float = 60.0
var DEFAULT_OPEN_HOUR: int = 6
var DEFAULT_CLOSE_HOUR: int = 22

func _ready() -> void:
	# Load balance config values
	SECONDS_PER_GAME_HOUR = BalanceConfig.TIME.seconds_per_game_hour
	DEFAULT_OPEN_HOUR = BalanceConfig.TIME.default_open_hour
	DEFAULT_CLOSE_HOUR = BalanceConfig.TIME.default_close_hour

	print("GameManager initialized")
	print("Starting Day ", current_day, " - Shop: CLOSED")
	print("Default hours: ", DEFAULT_OPEN_HOUR, ":00 to ", DEFAULT_CLOSE_HOUR, ":00")
	print("Current time: ", get_game_time_formatted())

func _process(delta: float) -> void:
	if not is_paused:
		# Convert real seconds to game seconds
		# If SECONDS_PER_GAME_HOUR = 30, then 30 real seconds = 3600 game seconds
		var game_seconds_per_real_second = 3600.0 / SECONDS_PER_GAME_HOUR
		var time_increment = delta * game_seconds_per_real_second * time_scale
		game_time += time_increment

		# Wrap to next day at midnight
		if game_time >= 86400.0:  # 24 hours in seconds
			_advance_to_next_day()

		# Check for hour changes
		var current_hour = get_current_hour()
		if current_hour != previous_hour:
			previous_hour = current_hour
			hour_changed.emit(current_hour)

# Shop state management
func open_shop() -> void:
	if shop_state != ShopState.OPEN:
		shop_state = ShopState.OPEN
		print("=== SHOP OPENED ===")
		print("Time: ", get_game_time_formatted())
		shop_state_changed.emit(true)

		# Start spawning customers
		if CustomerManager:
			CustomerManager.start_spawning()

func close_shop() -> void:
	if shop_state != ShopState.CLOSED:
		shop_state = ShopState.CLOSED
		print("=== SHOP CLOSED ===")
		print("Time: ", get_game_time_formatted())
		shop_state_changed.emit(false)

		# Stop customer spawning and clear remaining customers
		if CustomerManager:
			CustomerManager.stop_spawning()
			CustomerManager.clear_all_customers()

		# Regenerate employee energy when shop closes
		if StaffManager:
			StaffManager.regenerate_all_employee_energy()

func toggle_shop() -> void:
	if shop_state == ShopState.OPEN:
		close_shop()
	else:
		open_shop()

# Day management
func _advance_to_next_day() -> void:
	# Wrap time back to midnight
	game_time = fmod(game_time, 86400.0)
	current_day += 1

	# Ensure shop is closed at day transition
	if shop_state == ShopState.OPEN:
		close_shop()

	# Update progression manager day tracking and reputation
	if ProgressionManager:
		ProgressionManager.increment_day()

	# Process employee daily updates (morale, etc.)
	if StaffManager:
		StaffManager.process_daily_updates()

	# Auto-save
	if SaveManager:
		SaveManager.auto_save()

	print("=== DAY ", current_day, " ===")
	print("Time: ", get_game_time_formatted())
	day_changed.emit(current_day)

# Sleep function (for player sleep mechanic)
func sleep(hours: int) -> void:
	print("Sleeping for ", hours, " hours...")

	# Close shop if open
	if shop_state == ShopState.OPEN:
		close_shop()

	# Advance time
	var sleep_seconds = hours * 3600.0
	game_time += sleep_seconds

	# Check if we crossed midnight
	if game_time >= 86400.0:
		_advance_to_next_day()

	print("Woke up at ", get_game_time_formatted())

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
func is_shop_open() -> bool:
	return shop_state == ShopState.OPEN

func get_shop_state() -> ShopState:
	return shop_state

func get_current_day() -> int:
	return current_day

func get_time_scale() -> float:
	return time_scale

func get_current_hour() -> int:
	return int(game_time / 3600) % 24

func get_current_minute() -> int:
	return int(game_time / 60) % 60

func get_game_time_formatted() -> String:
	var hours: int = get_current_hour()
	var minutes: int = get_current_minute()
	return "%02d:%02d" % [hours, minutes]

func get_time_of_day_string() -> String:
	var hour = get_current_hour()
	if hour >= 5 and hour < 12:
		return "Morning"
	elif hour >= 12 and hour < 17:
		return "Afternoon"
	elif hour >= 17 and hour < 21:
		return "Evening"
	else:
		return "Night"

func is_game_paused() -> bool:
	return is_paused

# Backwards compatibility (deprecated - to be removed)
func get_current_phase() -> int:
	push_warning("get_current_phase() is deprecated. Use is_shop_open() instead.")
	return 1 if shop_state == ShopState.OPEN else 0
