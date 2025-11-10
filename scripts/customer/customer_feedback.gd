extends Node3D

# CustomerFeedback - Visual feedback system for customers
# Shows speech bubbles, emojis, and other indicators above customer's head
# Attach to customer as a child node

# Visual indicator types
enum IndicatorType {
	NONE,
	SPEECH_BUBBLE,   # Ready for checkout
	HAPPY_EMOJI,     # 😊 Fast + Accurate service
	NEUTRAL_EMOJI,   # 😐 Medium speed or 1 error
	SAD_EMOJI        # ☹️ Slow or multiple errors
}

# Node references (created dynamically)
var speech_bubble: Sprite3D = null
var emoji_sprite: Sprite3D = null

# Current state
var current_indicator: IndicatorType = IndicatorType.NONE
var indicator_height: float = 2.5  # How high above customer head

# Animation state
var bob_time: float = 0.0
var bob_speed: float = 2.0
var bob_amount: float = 0.2

func _ready() -> void:
	_create_feedback_visuals()
	hide_all_indicators()

func _process(delta: float) -> void:
	# Animate bobbing motion for visible indicators
	if current_indicator != IndicatorType.NONE:
		bob_time += delta * bob_speed
		var offset = sin(bob_time) * bob_amount

		if speech_bubble and speech_bubble.visible:
			speech_bubble.position.y = indicator_height + offset
		if emoji_sprite and emoji_sprite.visible:
			emoji_sprite.position.y = indicator_height + offset

func _create_feedback_visuals() -> void:
	"""Create Sprite3D nodes for visual feedback"""

	# Create speech bubble sprite
	speech_bubble = Sprite3D.new()
	speech_bubble.name = "SpeechBubble"
	speech_bubble.pixel_size = 0.01
	speech_bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	speech_bubble.no_depth_test = true  # Always visible through walls
	speech_bubble.position = Vector3(0, indicator_height, 0)
	speech_bubble.visible = false
	add_child(speech_bubble)

	# Create emoji sprite
	emoji_sprite = Sprite3D.new()
	emoji_sprite.name = "EmojiSprite"
	emoji_sprite.pixel_size = 0.01
	emoji_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	emoji_sprite.no_depth_test = true
	emoji_sprite.position = Vector3(0, indicator_height, 0)
	emoji_sprite.visible = false
	add_child(emoji_sprite)

	print("Customer feedback visuals created")

func show_speech_bubble() -> void:
	"""Show speech bubble to indicate customer is ready for checkout"""
	hide_all_indicators()
	current_indicator = IndicatorType.SPEECH_BUBBLE

	if speech_bubble:
		# Create simple speech bubble texture
		var bubble_texture = _create_speech_bubble_texture()
		speech_bubble.texture = bubble_texture
		speech_bubble.visible = true
		print("Showing speech bubble indicator")

func show_emoji(emoji_type: IndicatorType) -> void:
	"""Show emoji based on customer satisfaction"""
	hide_all_indicators()
	current_indicator = emoji_type

	if emoji_sprite:
		var emoji_texture = _create_emoji_texture(emoji_type)
		emoji_sprite.texture = emoji_texture
		emoji_sprite.visible = true
		print("Showing emoji: ", IndicatorType.keys()[emoji_type])

func hide_all_indicators() -> void:
	"""Hide all visual indicators"""
	current_indicator = IndicatorType.NONE
	if speech_bubble:
		speech_bubble.visible = false
	if emoji_sprite:
		emoji_sprite.visible = false

func show_satisfaction_emoji(satisfaction_score: float, had_errors: bool, transaction_time: float) -> void:
	"""Show appropriate emoji based on transaction performance
	Args:
		satisfaction_score: 0-100 score
		had_errors: Whether any errors occurred
		transaction_time: Total time in seconds
	"""
	var emoji_type: IndicatorType = IndicatorType.NEUTRAL_EMOJI

	# Determine emoji based on performance
	# Fast + Accurate (< 30 sec, no errors): Happy 😊
	# Medium speed OR 1 error (30-60 sec): Neutral 😐
	# Slow OR multiple errors (> 60 sec or 2+ errors): Sad ☹️

	if transaction_time < 30.0 and not had_errors:
		emoji_type = IndicatorType.HAPPY_EMOJI
	elif transaction_time > 60.0 or had_errors:
		emoji_type = IndicatorType.SAD_EMOJI
	else:
		emoji_type = IndicatorType.NEUTRAL_EMOJI

	show_emoji(emoji_type)

	# Auto-hide after 2 seconds
	await get_tree().create_timer(2.0).timeout
	hide_all_indicators()

# Texture creation methods (procedural generation)
func _create_speech_bubble_texture() -> ImageTexture:
	"""Create a simple speech bubble texture"""
	var size = 128
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)

	# Fill with white circle for speech bubble
	for y in range(size):
		for x in range(size):
			var dx = x - size / 2
			var dy = y - size / 2
			var dist = sqrt(dx * dx + dy * dy)

			# Main bubble circle
			if dist < size / 2.5:
				image.set_pixel(x, y, Color.WHITE)
			# Small tail triangle at bottom
			elif y > size * 0.7 and y < size * 0.9 and x > size * 0.4 and x < size * 0.6:
				image.set_pixel(x, y, Color.WHITE)
			else:
				image.set_pixel(x, y, Color(0, 0, 0, 0))

	return ImageTexture.create_from_image(image)

func _create_emoji_texture(emoji_type: IndicatorType) -> ImageTexture:
	"""Create simple emoji textures procedurally"""
	var size = 128
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)

	var face_color = Color.YELLOW
	var detail_color = Color.BLACK

	# Draw base circle (face)
	for y in range(size):
		for x in range(size):
			var dx = x - size / 2
			var dy = y - size / 2
			var dist = sqrt(dx * dx + dy * dy)

			if dist < size / 2.2:
				image.set_pixel(x, y, face_color)
			else:
				image.set_pixel(x, y, Color(0, 0, 0, 0))

	# Draw facial features based on emoji type
	match emoji_type:
		IndicatorType.HAPPY_EMOJI:
			_draw_happy_face(image, size, detail_color)
		IndicatorType.NEUTRAL_EMOJI:
			_draw_neutral_face(image, size, detail_color)
		IndicatorType.SAD_EMOJI:
			_draw_sad_face(image, size, detail_color)

	return ImageTexture.create_from_image(image)

func _draw_happy_face(image: Image, size: int, color: Color) -> void:
	"""Draw happy face features 😊"""
	# Eyes (two dots)
	_draw_circle(image, size / 2 - 25, size / 2 - 15, 8, color)
	_draw_circle(image, size / 2 + 25, size / 2 - 15, 8, color)

	# Smile (arc)
	for i in range(-30, 31):
		var x = size / 2 + i
		var y = size / 2 + 10 + abs(i) * 0.3
		_draw_circle(image, x, y, 4, color)

func _draw_neutral_face(image: Image, size: int, color: Color) -> void:
	"""Draw neutral face features 😐"""
	# Eyes (two dots)
	_draw_circle(image, size / 2 - 25, size / 2 - 15, 8, color)
	_draw_circle(image, size / 2 + 25, size / 2 - 15, 8, color)

	# Straight mouth (line)
	for i in range(-25, 26):
		var x = size / 2 + i
		var y = size / 2 + 20
		_draw_circle(image, x, y, 4, color)

func _draw_sad_face(image: Image, size: int, color: Color) -> void:
	"""Draw sad face features ☹️"""
	# Eyes (two dots)
	_draw_circle(image, size / 2 - 25, size / 2 - 15, 8, color)
	_draw_circle(image, size / 2 + 25, size / 2 - 15, 8, color)

	# Frown (inverted arc)
	for i in range(-30, 31):
		var x = size / 2 + i
		var y = size / 2 + 35 - abs(i) * 0.3
		_draw_circle(image, x, y, 4, color)

func _draw_circle(image: Image, cx: float, cy: float, radius: float, color: Color) -> void:
	"""Helper to draw a filled circle"""
	for y in range(int(cy - radius), int(cy + radius + 1)):
		for x in range(int(cx - radius), int(cx + radius + 1)):
			if x >= 0 and x < image.get_width() and y >= 0 and y < image.get_height():
				var dx = x - cx
				var dy = y - cy
				if sqrt(dx * dx + dy * dy) <= radius:
					image.set_pixel(x, y, color)
