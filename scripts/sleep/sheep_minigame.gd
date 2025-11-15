extends CanvasLayer

# SheepMinigame - Endless runner game for sleep quality
# Sheep runs forward, fences come at them, press SPACE to jump over fences

# Signals
signal minigame_completed(calm_percentage: float)

# Node references
@onready var calm_meter: ProgressBar = $GameContainer/UI/CalmMeter
@onready var distance_label: Label = $GameContainer/UI/DistanceLabel
@onready var instructions_label: Label = $GameContainer/UI/Instructions
@onready var sheep_sprite: ColorRect = $GameContainer/GameArea/Sheep
@onready var game_area: Control = $GameContainer/GameArea
@onready var feedback_label: Label = $GameContainer/UI/FeedbackLabel

# Game state
var is_active: bool = false
var is_jumping: bool = false
var is_game_over: bool = false

# Scoring
var distance_traveled: float = 0.0
var fences_cleared: int = 0

# Movement
var base_speed: float = 200.0  # pixels per second
var current_speed: float = 200.0
var speed_increase_rate: float = 10.0  # pixels/sec increase per second
var max_speed: float = 500.0

# Jumping
var jump_velocity: float = -400.0
var gravity: float = 1200.0
var sheep_y_velocity: float = 0.0
var sheep_ground_y: float = 0.0
var jump_height: float = 100.0

# Fences
var fences: Array = []
var fence_spawn_timer: float = 0.0
var fence_spawn_interval: float = 2.0  # Start with 2 seconds between fences
var min_spawn_interval: float = 0.8  # Minimum time between fences

# Difficulty settings
var difficulty: String = "normal"

# Visual feedback
var feedback_timer: float = 0.0
var feedback_duration: float = 1.0

# Scoring thresholds for calm percentage
var max_distance_for_perfect: float = 1000.0  # 1000m = 100% calm

func _ready() -> void:
	hide()
	_load_difficulty_settings()
	print("[SheepMinigame] Ready - Endless runner mode")

func _load_difficulty_settings() -> void:
	"""Load difficulty from SleepManager"""
	if SleepManager:
		difficulty = SleepManager.minigame_difficulty

	match difficulty:
		"easy":
			base_speed = 150.0
			speed_increase_rate = 5.0
			fence_spawn_interval = 2.5
			min_spawn_interval = 1.2
			max_distance_for_perfect = 800.0

		"normal":
			base_speed = 200.0
			speed_increase_rate = 10.0
			fence_spawn_interval = 2.0
			min_spawn_interval = 0.8
			max_distance_for_perfect = 1000.0

		"hard":
			base_speed = 250.0
			speed_increase_rate = 15.0
			fence_spawn_interval = 1.5
			min_spawn_interval = 0.6
			max_distance_for_perfect = 1200.0

	print("[SheepMinigame] Difficulty: %s" % difficulty)

func start_minigame() -> void:
	"""Start the endless runner mini-game"""
	print("[SheepMinigame] Starting endless runner...")

	# Reset state
	distance_traveled = 0.0
	fences_cleared = 0
	current_speed = base_speed
	is_active = true
	is_jumping = false
	is_game_over = false
	sheep_y_velocity = 0.0
	fence_spawn_timer = 0.0
	feedback_timer = 0.0
	fences.clear()

	# Position sheep at bottom of game area (like Chrome Dino)
	if sheep_sprite:
		# Ground is at the bottom of the game area (y=100 in 200px tall area = bottom)
		sheep_ground_y = 80.0  # Y position when on ground (relative to center of 200px area)
		_position_sheep(-150.0, sheep_ground_y)  # Left side of screen
		sheep_sprite.show()

	# Update UI
	_update_ui()
	show()

	# Show instructions
	if instructions_label:
		instructions_label.text = "Press SPACE to jump over fences!\nDon't hit the fences!"
		instructions_label.show()
		await get_tree().create_timer(3.0).timeout
		if instructions_label:
			instructions_label.hide()

func _process(delta: float) -> void:
	if not is_active or is_game_over:
		return

	# Update feedback timer
	if feedback_timer > 0.0:
		feedback_timer -= delta
		if feedback_timer <= 0.0 and feedback_label:
			feedback_label.hide()

	# Update distance
	distance_traveled += current_speed * delta

	# Increase speed over time
	current_speed = min(current_speed + speed_increase_rate * delta, max_speed)

	# Decrease spawn interval over time (spawn fences more frequently)
	fence_spawn_interval = max(fence_spawn_interval - (0.05 * delta), min_spawn_interval)

	# Update sheep jumping physics
	_update_sheep_physics(delta)

	# Spawn fences
	_update_fence_spawning(delta)

	# Move and check fences
	_update_fences(delta)

	# Update UI
	_update_ui()

func _input(event: InputEvent) -> void:
	if not is_active or is_game_over:
		return

	# Jump on SPACE press
	if event.is_action_pressed("ui_accept") and not is_jumping:
		_jump()
		get_viewport().set_input_as_handled()

func _jump() -> void:
	"""Make the sheep jump"""
	if is_jumping:
		return

	is_jumping = true
	sheep_y_velocity = jump_velocity
	print("[SheepMinigame] Sheep jumping!")

func _update_sheep_physics(delta: float) -> void:
	"""Update sheep vertical position (jumping)"""
	if not sheep_sprite:
		return

	# Apply gravity
	sheep_y_velocity += gravity * delta

	# Calculate new Y position
	var current_y = sheep_sprite.offset_top + (sheep_sprite.offset_bottom - sheep_sprite.offset_top) / 2.0
	var new_y = current_y + sheep_y_velocity * delta

	# Check if landed
	if new_y >= sheep_ground_y:
		new_y = sheep_ground_y
		sheep_y_velocity = 0.0
		is_jumping = false

	# Update position
	_position_sheep(0.0, new_y)

func _position_sheep(x: float, y: float) -> void:
	"""Position the sheep sprite (like Chrome Dino)"""
	if not sheep_sprite:
		return

	var sheep_width = 60.0
	var sheep_height = 50.0

	# Position sheep so bottom aligns with ground
	sheep_sprite.offset_left = x - (sheep_width / 2)
	sheep_sprite.offset_right = x + (sheep_width / 2)
	sheep_sprite.offset_top = y - sheep_height + 30.0  # Top of sheep
	sheep_sprite.offset_bottom = y + 30.0  # Bottom on ground

func _update_fence_spawning(delta: float) -> void:
	"""Spawn new fences"""
	fence_spawn_timer += delta

	if fence_spawn_timer >= fence_spawn_interval:
		_spawn_fence()
		fence_spawn_timer = 0.0

func _spawn_fence() -> void:
	"""Create a new fence at the right side of screen (like Chrome Dino cactus)"""
	if not game_area:
		return

	var fence_node = ColorRect.new()
	fence_node.color = Color(0.545, 0.271, 0.075, 1)  # Brown

	# Position at right edge, ON THE GROUND
	var start_x = 300.0  # Right edge of game area (600px wide, centered at 0)
	var fence_width = 20.0
	var fence_height = 50.0

	# Place fence on ground, aligned with sheep ground level
	fence_node.offset_left = start_x - (fence_width / 2)
	fence_node.offset_right = start_x + (fence_width / 2)
	fence_node.offset_top = sheep_ground_y - fence_height + 30.0  # Bottom aligns with ground
	fence_node.offset_bottom = sheep_ground_y + 30.0  # Ground level

	game_area.add_child(fence_node)
	fences.append(fence_node)

func _update_fences(delta: float) -> void:
	"""Move fences and check collisions"""
	var fences_to_remove = []

	for fence_node in fences:
		if not is_instance_valid(fence_node):
			continue

		# Move fence left
		var move_amount = current_speed * delta
		fence_node.offset_left -= move_amount
		fence_node.offset_right -= move_amount

		# Check if fence is past sheep (cleared)
		if fence_node.offset_right < -50.0 and fence_node not in fences_to_remove:
			fences_cleared += 1
			_give_feedback("+1 Fence!", Color.GREEN_YELLOW)
			fences_to_remove.append(fence_node)
			continue

		# Check collision with sheep
		if _check_fence_collision(fence_node):
			print("[SheepMinigame] HIT A FENCE! Game Over!")
			_game_over()
			return

	# Remove cleared fences
	for fence_node in fences_to_remove:
		fences.erase(fence_node)
		fence_node.queue_free()

func _check_fence_collision(fence_node: ColorRect) -> bool:
	"""Check if sheep collides with fence"""
	if not sheep_sprite or not fence_node:
		return false

	# Simple AABB collision
	var sheep_left = sheep_sprite.offset_left
	var sheep_right = sheep_sprite.offset_right
	var sheep_top = sheep_sprite.offset_top
	var sheep_bottom = sheep_sprite.offset_bottom

	var fence_left = fence_node.offset_left
	var fence_right = fence_node.offset_right
	var fence_top = fence_node.offset_top
	var fence_bottom = fence_node.offset_bottom

	# Check if rectangles overlap
	if sheep_right > fence_left and sheep_left < fence_right:
		if sheep_bottom > fence_top and sheep_top < fence_bottom:
			return true

	return false

func _game_over() -> void:
	"""End the game"""
	is_game_over = true
	is_active = false

	_give_feedback("Game Over!", Color.RED)

	# Calculate calm percentage based on distance
	var calm_percentage = min((distance_traveled / max_distance_for_perfect) * 100.0, 100.0)

	print("[SheepMinigame] Game Over! Distance: %.1fm, Fences: %d, Calm: %.1f%%" % [distance_traveled, fences_cleared, calm_percentage])

	# Wait a moment then emit completion
	await get_tree().create_timer(2.0).timeout
	minigame_completed.emit(calm_percentage)

func _give_feedback(text: String, color: Color) -> void:
	"""Show feedback text"""
	if feedback_label:
		feedback_label.text = text
		feedback_label.add_theme_color_override("font_color", color)
		feedback_label.show()
		feedback_timer = feedback_duration

func _update_ui() -> void:
	"""Update all UI elements"""
	# Update distance display
	if distance_label:
		distance_label.text = "Distance: %.0fm | Fences: %d" % [distance_traveled, fences_cleared]

	# Update calm meter (based on current distance)
	if calm_meter:
		var calm_pct = min((distance_traveled / max_distance_for_perfect) * 100.0, 100.0)
		calm_meter.value = calm_pct
