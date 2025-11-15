extends CanvasLayer

# SheepMinigame - Counting sheep rhythm game for sleep quality
# Player presses SPACE when sheep jump over fence to count them accurately

# Signals
signal minigame_completed(calm_percentage: float)

# Node references (will be created via scene)
@onready var calm_meter: ProgressBar = $GameContainer/UI/CalmMeter
@onready var sheep_counter_label: Label = $GameContainer/UI/SheepCounter
@onready var instructions_label: Label = $GameContainer/UI/Instructions
@onready var sheep_sprite: ColorRect = $GameContainer/GameArea/Sheep
@onready var fence: ColorRect = $GameContainer/GameArea/Fence
@onready var timing_indicator: Control = $GameContainer/UI/TimingIndicator
@onready var perfect_zone: ColorRect = $GameContainer/UI/TimingIndicator/PerfectZone
@onready var good_zone: ColorRect = $GameContainer/UI/TimingIndicator/GoodZone
@onready var feedback_label: Label = $GameContainer/UI/FeedbackLabel

# Game state
var sheep_counted: int = 0
var total_sheep_to_count: int = 20
var calm_level: float = 50.0  # Starts at 50%
var is_active: bool = false
var current_sheep_index: int = 0

# Timing variables
var sheep_jump_interval: float = 2.0  # Seconds between sheep
var time_since_last_sheep: float = 0.0
var current_sheep_progress: float = 0.0  # 0.0 to 1.0
var sheep_jump_duration: float = 1.0  # How long the jump animation takes

# Input timing
var can_count_sheep: bool = false
var perfect_window_start: float = 0.45  # Jump peak window
var perfect_window_end: float = 0.55
var good_window_start: float = 0.35
var good_window_end: float = 0.65

# Difficulty settings
var difficulty: String = "normal"

# Visual feedback
var feedback_timer: float = 0.0
var feedback_duration: float = 1.0

func _ready() -> void:
	hide()
	_load_difficulty_settings()
	print("[SheepMinigame] Ready")

func _load_difficulty_settings() -> void:
	"""Load difficulty from SleepManager"""
	if SleepManager:
		difficulty = SleepManager.minigame_difficulty

	match difficulty:
		"easy":
			sheep_jump_interval = 2.5
			perfect_window_start = 0.40
			perfect_window_end = 0.60
			good_window_start = 0.30
			good_window_end = 0.70
			total_sheep_to_count = 15

		"normal":
			sheep_jump_interval = 2.0
			perfect_window_start = 0.45
			perfect_window_end = 0.55
			good_window_start = 0.35
			good_window_end = 0.65
			total_sheep_to_count = 20

		"hard":
			sheep_jump_interval = 1.5
			perfect_window_start = 0.47
			perfect_window_end = 0.53
			good_window_start = 0.38
			good_window_end = 0.62
			total_sheep_to_count = 25

	print("[SheepMinigame] Difficulty: %s" % difficulty)

func start_minigame() -> void:
	"""Start the counting sheep mini-game"""
	print("[SheepMinigame] Starting mini-game...")

	# Reset state
	sheep_counted = 0
	current_sheep_index = 0
	calm_level = 50.0
	is_active = true
	time_since_last_sheep = 0.0
	current_sheep_progress = 0.0
	feedback_timer = 0.0

	# Update UI
	_update_ui()
	show()

	# Ensure sheep and fence are visible
	if sheep_sprite:
		sheep_sprite.show()
		print("[SheepMinigame] Sheep visible:", sheep_sprite.visible)
	if fence:
		fence.show()

	# Show instructions briefly
	if instructions_label:
		instructions_label.text = "Press SPACE when sheep jump over fence!\nCount %d sheep to sleep well." % total_sheep_to_count
		instructions_label.show()
		await get_tree().create_timer(3.0).timeout
		if instructions_label:
			instructions_label.hide()

func _process(delta: float) -> void:
	if not is_active:
		return

	# Update feedback timer
	if feedback_timer > 0.0:
		feedback_timer -= delta
		if feedback_timer <= 0.0 and feedback_label:
			feedback_label.hide()

	# Update sheep spawning
	time_since_last_sheep += delta

	if time_since_last_sheep >= sheep_jump_interval:
		# Start next sheep
		_spawn_sheep()
		time_since_last_sheep = 0.0
		current_sheep_progress = 0.0

	# Update current sheep jump progress
	if current_sheep_index < total_sheep_to_count:
		current_sheep_progress = time_since_last_sheep / sheep_jump_duration
		current_sheep_progress = clamp(current_sheep_progress, 0.0, 1.0)

		# Update visual state
		_update_sheep_animation(current_sheep_progress)
		_update_timing_indicator(current_sheep_progress)

		# Check if in counting window
		can_count_sheep = (current_sheep_progress >= good_window_start and
						   current_sheep_progress <= good_window_end)

func _unhandled_input(event: InputEvent) -> void:
	if not is_active:
		return

	# Count sheep on SPACE press
	if event.is_action_pressed("ui_accept"):  # SPACE key
		_attempt_count_sheep()

func _spawn_sheep() -> void:
	"""Spawn a new sheep to jump"""
	current_sheep_index += 1

	if current_sheep_index > total_sheep_to_count:
		_end_minigame()
		return

	print("[SheepMinigame] Sheep #%d jumping..." % current_sheep_index)

	# Start sheep animation
	if sheep_sprite:
		sheep_sprite.play("jump")

func _attempt_count_sheep() -> void:
	"""Player attempts to count a sheep"""
	if not can_count_sheep:
		# Clicked outside timing window
		_give_feedback("Miss", Color.GRAY, -5.0)
		return

	# Check timing quality
	var timing_quality = _check_timing()

	match timing_quality:
		"perfect":
			sheep_counted += 1
			_give_feedback("Perfect! 🐑", Color.GOLD, 3.0)
			calm_level += 3.0

		"good":
			sheep_counted += 1
			_give_feedback("Good", Color.LIGHT_GREEN, 1.5)
			calm_level += 1.5

		"ok":
			sheep_counted += 1
			_give_feedback("OK", Color.LIGHT_BLUE, 0.5)
			calm_level += 0.5

		"miss":
			_give_feedback("Miss", Color.ORANGE_RED, -2.0)
			calm_level -= 2.0

	# Clamp calm level
	calm_level = clamp(calm_level, 0.0, 100.0)

	# Update UI
	_update_ui()

	# Reset for next sheep
	can_count_sheep = false

func _check_timing() -> String:
	"""Check how well-timed the input was"""
	if current_sheep_progress >= perfect_window_start and current_sheep_progress <= perfect_window_end:
		return "perfect"
	elif current_sheep_progress >= good_window_start and current_sheep_progress <= good_window_end:
		return "good"
	else:
		return "ok"

func _give_feedback(text: String, color: Color, calm_change: float) -> void:
	"""Show visual feedback for player input"""
	if feedback_label:
		feedback_label.text = text
		if calm_change > 0:
			feedback_label.text += " +%.1f%%" % calm_change
		elif calm_change < 0:
			feedback_label.text += " %.1f%%" % calm_change

		feedback_label.add_theme_color_override("font_color", color)
		feedback_label.show()
		feedback_timer = feedback_duration

	print("[SheepMinigame] %s (calm change: %.1f%%)" % [text, calm_change])

func _update_sheep_animation(progress: float) -> void:
	"""Update sheep sprite position based on jump progress"""
	if not sheep_sprite:
		return

	# Simple arc jump (parabola) - sheep travels across full screen
	var jump_height = 120.0
	var horizontal_distance = 500.0  # Much wider travel distance

	# Start from far left (-250) to far right (+250)
	var x = progress * horizontal_distance - (horizontal_distance / 2)
	var y = -jump_height * (4.0 * progress * (1.0 - progress))  # Parabola

	# Update ColorRect position (offset values relative to center anchor)
	var sheep_width = 100.0
	var sheep_height = 60.0

	sheep_sprite.offset_left = x - (sheep_width / 2)
	sheep_sprite.offset_right = x + (sheep_width / 2)
	sheep_sprite.offset_top = y - (sheep_height / 2)
	sheep_sprite.offset_bottom = y + (sheep_height / 2)

	# Debug output
	print("[Sheep Animation] #%d progress=%.2f, x=%.1f, y=%.1f, offsets: L=%.1f R=%.1f T=%.1f B=%.1f, visible=%s" % [
		current_sheep_index, progress, x, y,
		sheep_sprite.offset_left, sheep_sprite.offset_right,
		sheep_sprite.offset_top, sheep_sprite.offset_bottom,
		sheep_sprite.visible
	])

func _update_timing_indicator(progress: float) -> void:
	"""Update the timing indicator to show current position"""
	if not timing_indicator:
		return

	# Move indicator needle/marker based on progress
	# This will be a visual element showing where in the timing window we are

func _update_ui() -> void:
	"""Update all UI elements"""
	if calm_meter:
		calm_meter.value = calm_level

	if sheep_counter_label:
		sheep_counter_label.text = "Sheep: %d / %d" % [sheep_counted, total_sheep_to_count]

func _end_minigame() -> void:
	"""End the mini-game and return results"""
	is_active = false

	print("[SheepMinigame] Mini-game complete!")
	print("  Sheep counted: %d / %d" % [sheep_counted, total_sheep_to_count])
	print("  Final calm level: %.1f%%" % calm_level)

	# Calculate final calm percentage (accounting for missed sheep)
	var counting_accuracy = float(sheep_counted) / float(total_sheep_to_count)
	var final_calm = calm_level * counting_accuracy

	print("  Counting accuracy: %.1f%%" % (counting_accuracy * 100))
	print("  Final calm (adjusted): %.1f%%" % final_calm)

	# Emit completion signal
	minigame_completed.emit(final_calm)

	# Hide after a delay to show final state
	await get_tree().create_timer(2.0).timeout
	hide()

func skip_minigame() -> void:
	"""Skip the mini-game and give default result"""
	var default_calm = randf_range(30.0, 40.0)
	minigame_completed.emit(default_calm)
	hide()
