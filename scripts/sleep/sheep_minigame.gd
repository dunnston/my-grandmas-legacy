extends CanvasLayer

# SheepMinigame - Endless runner game for sleep quality
# Sheep runs forward, bushes come at them, press SPACE to jump over bushes

# Signals
signal minigame_completed(calm_percentage: float)

# Node references
@onready var calm_meter: ProgressBar = $GameContainer/UI/CalmMeter
@onready var distance_label: Label = $GameContainer/UI/DistanceLabel
@onready var instructions_label: Label = $GameContainer/UI/Instructions
@onready var sheep_sprite: Sprite2D = $GameContainer/GameArea/Sheep
@onready var game_area: Node2D = $GameContainer/GameArea
@onready var feedback_label: Label = $GameContainer/UI/FeedbackLabel
@onready var bg1: Sprite2D = $GameContainer/GameArea/Background1
@onready var bg2: Sprite2D = $GameContainer/GameArea/Background2

# Preloaded textures
var run_texture: Texture2D
var jump_texture: Texture2D
var bush_texture: Texture2D

# Game state
var is_active: bool = false
var is_jumping: bool = false
var is_game_over: bool = false

# Scoring
var distance_traveled: float = 0.0
var bushes_cleared: int = 0

# Movement
var base_speed: float = 200.0  # pixels per second
var current_speed: float = 200.0
var speed_increase_rate: float = 10.0  # pixels/sec increase per second
var max_speed: float = 500.0

# Jumping
var jump_velocity: float = -750.0  # Lower jump height
var gravity: float = 1200.0  # Lower gravity for more airtime (floatier)
var sheep_y_velocity: float = 0.0
var sheep_ground_y: float = 0.0
var sheep_x: float = 150.0  # Fixed X position
var sheep_y: float = 500.0  # Current Y position

# Animation
var current_animation: String = "run"
var animation_frame: int = 0
var animation_timer: float = 0.0
var animation_speed: float = 12.0  # frames per second
var run_frame_count: int = 36  # 6x6 grid
var jump_frame_count: int = 36  # 6x6 grid (was incorrectly set to 30)

# Background scrolling
var bg_scroll_offset: float = 0.0
var bg_width: float = 1920.0  # Will be set from actual texture

# Bushes
var bushes: Array = []
var bush_spawn_timer: float = 0.0
var bush_spawn_interval: float = 3.5  # Start with 3.5 seconds between bushes
var min_spawn_interval: float = 1.5  # Minimum time between bushes

# Difficulty settings
var difficulty: String = "normal"

# Visual feedback
var feedback_timer: float = 0.0
var feedback_duration: float = 1.0

# Scoring thresholds for calm percentage
var max_distance_for_perfect: float = 1000.0  # 1000m = 100% calm

func _ready() -> void:
	hide()
	_load_textures()
	_load_difficulty_settings()
	print("[SheepMinigame] Ready - Endless runner mode with sprites")

func _load_textures() -> void:
	"""Preload all textures"""
	run_texture = load("res://assets/sprites/sheep-run.png")
	jump_texture = load("res://assets/sprites/sheep-jump.png")
	bush_texture = load("res://assets/enviroment/bush.png")

func _load_difficulty_settings() -> void:
	"""Load difficulty from SleepManager"""
	if SleepManager:
		difficulty = SleepManager.minigame_difficulty

	match difficulty:
		"easy":
			base_speed = 150.0
			speed_increase_rate = 5.0
			bush_spawn_interval = 4.0
			min_spawn_interval = 2.0
			max_distance_for_perfect = 800.0

		"normal":
			base_speed = 200.0
			speed_increase_rate = 10.0
			bush_spawn_interval = 3.5
			min_spawn_interval = 1.5
			max_distance_for_perfect = 1000.0

		"hard":
			base_speed = 250.0
			speed_increase_rate = 15.0
			bush_spawn_interval = 3.0
			min_spawn_interval = 1.0
			max_distance_for_perfect = 1200.0

	print("[SheepMinigame] Difficulty: %s" % difficulty)

func start_minigame() -> void:
	"""Start the endless runner mini-game"""
	print("[SheepMinigame] Starting endless runner...")

	# Reset state
	distance_traveled = 0.0
	bushes_cleared = 0
	current_speed = base_speed
	is_active = true
	is_jumping = false
	is_game_over = false
	sheep_y_velocity = 0.0
	bush_spawn_timer = 0.0
	feedback_timer = 0.0
	animation_frame = 0
	animation_timer = 0.0
	bg_scroll_offset = 0.0
	bushes.clear()

	# Get viewport size
	var viewport_size = get_viewport().get_visible_rect().size

	# Get background width from texture and scale to fit viewport height
	if bg1 and bg1.texture and bg2:
		var texture_width = bg1.texture.get_width()
		var texture_height = bg1.texture.get_height()
		var viewport_width = viewport_size.x
		var viewport_height = viewport_size.y

		# Calculate scale to fit viewport height
		var scale_factor = viewport_height / texture_height
		bg1.scale = Vector2(scale_factor, scale_factor)
		bg2.scale = Vector2(scale_factor, scale_factor)

		# Calculate scaled texture width for positioning
		var scaled_texture_width = texture_width * scale_factor

		# Use viewport width as bg_width if texture is narrower than viewport
		bg_width = max(scaled_texture_width, viewport_width)

		# Ensure both backgrounds have the same texture
		if not bg2.texture:
			bg2.texture = bg1.texture

		# Position both backgrounds for seamless scrolling
		bg1.position = Vector2(0, 0)
		bg2.position = Vector2(scaled_texture_width, 0)
		bg1.visible = true
		bg2.visible = true
		bg1.centered = false
		bg2.centered = false

		print("[SheepMinigame] Background setup:")
		print("  - Texture size: %dx%d" % [texture_width, texture_height])
		print("  - Viewport size: %dx%d" % [viewport_width, viewport_height])
		print("  - Scale factor: %.2f" % scale_factor)
		print("  - Scaled width: %.0f" % scaled_texture_width)
		print("  - BG1 pos: ", bg1.position, " scale: ", bg1.scale)
		print("  - BG2 pos: ", bg2.position, " scale: ", bg2.scale)
	else:
		print("[SheepMinigame] ERROR: Background texture not loaded!")
		if not bg1:
			print("  - bg1 is null")
		elif not bg1.texture:
			print("  - bg1.texture is null")
		if not bg2:
			print("  - bg2 is null")

	# Position sheep at bottom of screen
	if sheep_sprite:
		sheep_ground_y = viewport_size.y - 50.0  # 50px from bottom
		sheep_x = 150.0  # Fixed X position on left side
		sheep_y = sheep_ground_y
		sheep_sprite.texture = run_texture
		sheep_sprite.hframes = 6
		sheep_sprite.vframes = 6
		sheep_sprite.scale = Vector2(0.4, 0.4)  # Scale down sheep
		current_animation = "run"
		sheep_sprite.frame = 0
		_position_sheep(sheep_x, sheep_y)
		sheep_sprite.show()

		print("[Sheep Setup]")
		print("  Ground Y: ", sheep_ground_y)
		print("  Sheep sprite position: ", sheep_sprite.position)
		print("  Sheep scale: ", sheep_sprite.scale)
		var frame_height = (run_texture.get_height() / 6) * 0.4
		print("  Frame height: ", frame_height)
		print("  Feet should be at Y: ", sheep_ground_y)

	# Update UI
	_update_ui()
	show()

	# Show instructions
	if instructions_label:
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

	# Increase speed over time (accelerates faster as game progresses)
	var speed_multiplier = 1.0 + (distance_traveled / 2000.0)  # Speed up based on distance
	var effective_speed_increase = speed_increase_rate * speed_multiplier
	current_speed = min(current_speed + effective_speed_increase * delta, max_speed)

	# Decrease spawn interval over time (spawn bushes more frequently)
	bush_spawn_interval = max(bush_spawn_interval - (0.08 * delta), min_spawn_interval)

	# Scroll background
	_update_background_scroll(delta)

	# Update sheep animation
	_update_sheep_animation(delta)

	# Update sheep jumping physics
	_update_sheep_physics(delta)

	# Spawn bushes
	_update_bush_spawning(delta)

	# Move and check bushes
	_update_bushes(delta)

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
	current_animation = "jump"
	animation_frame = 0

	# Switch to jump spritesheet - MUST set frames before setting texture!
	sheep_sprite.hframes = 6
	sheep_sprite.vframes = 6  # Changed from 5 to 6 - sprite is 6x6 grid
	sheep_sprite.texture = jump_texture
	sheep_sprite.frame = 0

	# Disable region - it was causing issues
	sheep_sprite.region_enabled = false

	if jump_texture:
		print("[SheepMinigame] Jump texture info:")
		print("  - Texture size: %dx%d" % [jump_texture.get_width(), jump_texture.get_height()])
		print("  - Frame grid: %dx%d = %d total frames" % [sheep_sprite.hframes, sheep_sprite.vframes, sheep_sprite.hframes * sheep_sprite.vframes])
		print("  - Individual frame size: %.1fx%.1f" % [jump_texture.get_width() / sheep_sprite.hframes, jump_texture.get_height() / sheep_sprite.vframes])
		print("  - Current frame: %d" % sheep_sprite.frame)

func _update_background_scroll(delta: float) -> void:
	"""Scroll the background to simulate movement - seamless infinite loop"""
	if not bg1 or not bg2:
		print("[SheepMinigame] ERROR: Background sprites not found!")
		return

	if not bg1.visible or not bg2.visible:
		print("[SheepMinigame] ERROR: Backgrounds not visible!")
		bg1.visible = true
		bg2.visible = true

	# Get actual scaled texture width (accounting for scale)
	var texture_width = bg1.texture.get_width() * bg1.scale.x if bg1.texture else bg_width

	# Scroll at 50% of game speed for parallax effect
	var scroll_speed = current_speed * 0.5
	var scroll_amount = scroll_speed * delta

	# Move both backgrounds left
	bg1.position.x -= scroll_amount
	bg2.position.x -= scroll_amount

	# Debug output every 120 frames
	if Engine.get_process_frames() % 120 == 0:
		var viewport_width = get_viewport().get_visible_rect().size.x
		print("[BG Scroll] BG1: %.0f to %.0f | BG2: %.0f to %.0f | Screen: 0 to %.0f" % [
			bg1.position.x,
			bg1.position.x + texture_width,
			bg2.position.x,
			bg2.position.x + texture_width,
			viewport_width
		])

	# Simple leapfrog: when a background goes completely off left edge, move it to the right
	# Use actual scaled texture width
	if bg1.position.x + texture_width < 0:
		bg1.position.x = bg2.position.x + texture_width
		print("[BG Scroll] BG1 looped to right side! New pos: %.1f" % bg1.position.x)

	if bg2.position.x + texture_width < 0:
		bg2.position.x = bg1.position.x + texture_width
		print("[BG Scroll] BG2 looped to right side! New pos: %.1f" % bg2.position.x)

func _update_sheep_animation(delta: float) -> void:
	"""Update sprite animation frames"""
	if not sheep_sprite:
		return

	animation_timer += delta
	var frame_duration = 1.0 / animation_speed

	if animation_timer >= frame_duration:
		animation_timer -= frame_duration

		if current_animation == "run":
			animation_frame = (animation_frame + 1) % run_frame_count
			sheep_sprite.frame = animation_frame
		elif current_animation == "jump":
			# Play jump animation once, then hold last frame
			if animation_frame < jump_frame_count - 1:
				animation_frame += 1
				sheep_sprite.frame = animation_frame

func _update_sheep_physics(delta: float) -> void:
	"""Update sheep vertical position (jumping)"""
	if not sheep_sprite:
		return

	# Apply gravity
	sheep_y_velocity += gravity * delta

	# Calculate new Y position
	sheep_y += sheep_y_velocity * delta

	# Check if landed
	if sheep_y >= sheep_ground_y:
		sheep_y = sheep_ground_y
		sheep_y_velocity = 0.0
		if is_jumping:
			is_jumping = false
			current_animation = "run"
			animation_frame = 0

			# Switch back to run spritesheet - set frames BEFORE texture!
			sheep_sprite.hframes = 6
			sheep_sprite.vframes = 6
			sheep_sprite.texture = run_texture
			sheep_sprite.frame = 0

	# Update position (keep X fixed!)
	_position_sheep(sheep_x, sheep_y)

func _position_sheep(x: float, y: float) -> void:
	"""Position the sheep sprite"""
	if not sheep_sprite:
		return

	# Sprite2D uses center position, so adjust Y for bottom alignment (account for scale)
	var frame_height = (sheep_sprite.texture.get_height() / sheep_sprite.vframes) * sheep_sprite.scale.y if sheep_sprite.texture else 60
	sheep_sprite.position = Vector2(x, y - frame_height / 2.0)

func _update_bush_spawning(delta: float) -> void:
	"""Spawn new bushes with variable timing"""
	bush_spawn_timer += delta

	if bush_spawn_timer >= bush_spawn_interval:
		_spawn_bush()
		bush_spawn_timer = 0.0

		# Add random variation to next spawn interval (±0.5 seconds)
		var next_interval_variation = randf_range(-0.5, 0.5)
		var varied_interval = max(bush_spawn_interval + next_interval_variation, min_spawn_interval)
		bush_spawn_interval = varied_interval

func _spawn_bush() -> void:
	"""Create a new bush at the right side of screen with random variation"""
	if not game_area or not bush_texture:
		return

	var bush_sprite = Sprite2D.new()
	bush_sprite.texture = bush_texture

	# Random scale variation (0.12 to 0.15 for variety - all sizes are jumpable)
	var random_scale = randf_range(0.12, 0.15)
	bush_sprite.scale = Vector2(random_scale, random_scale)

	# Get viewport width for spawn position
	var viewport_width = get_viewport().get_visible_rect().size.x

	# Position at right edge of screen on ground
	var bush_width = bush_texture.get_width() * random_scale
	var bush_height = bush_texture.get_height() * random_scale

	# Random vertical offset for variety (-5 to +15 pixels)
	var vertical_variation = randf_range(-5.0, 15.0)
	var ground_offset = 10.0 + vertical_variation

	# Position bush so its BOTTOM is at ground level
	bush_sprite.position = Vector2(viewport_width + bush_width / 2.0, sheep_ground_y - bush_height / 2.0 + ground_offset)

	game_area.add_child(bush_sprite)
	bushes.append(bush_sprite)

func _update_bushes(delta: float) -> void:
	"""Move bushes and check collisions"""
	var bushes_to_remove = []

	for bush_sprite in bushes:
		if not is_instance_valid(bush_sprite):
			continue

		# Move bush left
		var move_amount = current_speed * delta
		bush_sprite.position.x -= move_amount

		# Check if bush is past sheep (cleared)
		if bush_sprite.position.x < -100 and bush_sprite not in bushes_to_remove:
			bushes_cleared += 1
			_give_feedback("+1 Bush!", Color.GREEN_YELLOW)
			bushes_to_remove.append(bush_sprite)
			continue

		# Check collision with sheep
		if _check_bush_collision(bush_sprite):
			print("[SheepMinigame] HIT A BUSH! Game Over!")
			_game_over()
			return

	# Remove cleared bushes
	for bush_sprite in bushes_to_remove:
		bushes.erase(bush_sprite)
		bush_sprite.queue_free()

func _check_bush_collision(bush_sprite: Sprite2D) -> bool:
	"""Check if sheep's FEET collide with bush (not the whole body)"""
	if not sheep_sprite or not bush_sprite:
		return false

	# Get sprite bounds (account for scaling)
	var sheep_frame_width = (sheep_sprite.texture.get_width() / sheep_sprite.hframes) * sheep_sprite.scale.x if sheep_sprite.texture else 80
	var sheep_frame_height = (sheep_sprite.texture.get_height() / sheep_sprite.vframes) * sheep_sprite.scale.y if sheep_sprite.texture else 60

	# Only check the BOTTOM 30% of the sheep (feet area)
	var sheep_bottom_y = sheep_sprite.position.y + sheep_frame_height / 2.0
	var feet_height = sheep_frame_height * 0.3  # Only bottom 30%

	var sheep_feet_rect = Rect2(
		sheep_sprite.position.x - sheep_frame_width / 2.0,
		sheep_bottom_y - feet_height,
		sheep_frame_width,
		feet_height
	)

	# Get bush texture dimensions
	var bush_width = bush_sprite.texture.get_width() * bush_sprite.scale.x
	var bush_height = bush_sprite.texture.get_height() * bush_sprite.scale.y

	# Use larger collision box (70% of texture) and shift it DOWN since the actual
	# bush graphic is in the bottom portion of the texture (transparent space at top)
	var collision_scale = 0.7
	var actual_bush_width = bush_width * collision_scale
	var actual_bush_height = bush_height * collision_scale

	# Offset the collision box down by 20% of texture height to align with actual bush graphic
	var vertical_offset = bush_height * 0.2

	var bush_rect = Rect2(
		bush_sprite.position.x - actual_bush_width / 2.0,
		bush_sprite.position.y - actual_bush_height / 2.0 + vertical_offset,
		actual_bush_width,
		actual_bush_height
	)

	# Check if sheep's feet overlap with bush
	return sheep_feet_rect.intersects(bush_rect)

func _game_over() -> void:
	"""End the game"""
	is_game_over = true
	is_active = false

	_give_feedback("Game Over!", Color.RED)

	# Calculate calm percentage based on distance
	var calm_percentage = min((distance_traveled / max_distance_for_perfect) * 100.0, 100.0)

	print("[SheepMinigame] Game Over! Distance: %.1fm, Bushes: %d, Calm: %.1f%%" % [distance_traveled, bushes_cleared, calm_percentage])

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
		distance_label.text = "Distance: %.0fm | Bushes: %d" % [distance_traveled, bushes_cleared]

	# Update calm meter (based on current distance)
	if calm_meter:
		var calm_pct = min((distance_traveled / max_distance_for_perfect) * 100.0, 100.0)
		calm_meter.value = calm_pct
