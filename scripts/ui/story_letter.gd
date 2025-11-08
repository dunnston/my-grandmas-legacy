extends Control

# Story Letter Popup - Displays grandmother's letters at milestone moments
# Beautiful, emotional presentation of story beats

# Node references
@onready var panel: Panel = $Panel
@onready var letter_title: Label = $Panel/MarginContainer/VBox/LetterTitle
@onready var letter_content: RichTextLabel = $Panel/MarginContainer/VBox/ScrollContainer/LetterContent
@onready var close_button: Button = $Panel/MarginContainer/VBox/CloseButton
@onready var signature: Label = $Panel/MarginContainer/VBox/Signature

# Animation
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	print("StoryLetter ready")

	# Start hidden
	hide()

	# Connect close button
	if close_button:
		close_button.pressed.connect(_on_close_pressed)

	# Connect to StoryManager signal
	if StoryManager:
		StoryManager.story_beat_triggered.connect(_on_story_beat)

func show_letter(beat_id: String, letter_data: Dictionary) -> void:
	"""Display a grandmother's letter"""
	print("StoryLetter: Showing letter for beat_id '%s'" % beat_id)

	# Set letter content
	if letter_title:
		letter_title.text = letter_data.get("title", "A Letter from Grandma")

	if letter_content:
		# Letter text is in "letter" key from StoryManager
		var letter_text: String = letter_data.get("letter", "")
		letter_content.text = letter_text

	if signature:
		# Signature is part of the letter text in StoryManager, so we can hide this or use a default
		signature.text = ""  # Already included in letter text

	# Pause game time during letter
	if GameManager:
		GameManager.pause_time()

	# Show with animation
	show()
	if animation_player and animation_player.has_animation("fade_in"):
		animation_player.play("fade_in")

func _on_close_pressed() -> void:
	"""Close button pressed"""
	hide_letter()

func hide_letter() -> void:
	"""Hide the letter"""
	print("StoryLetter: Hiding")

	# Resume game time
	GameManager.resume_time()

	# Hide with animation
	if animation_player and animation_player.has_animation("fade_out"):
		animation_player.play("fade_out")
		await animation_player.animation_finished

	hide()

func _on_story_beat(beat_id: String) -> void:
	"""Called when a story beat is triggered"""
	var letter_data: Dictionary = StoryManager.get_letter(beat_id)

	if not letter_data.is_empty():
		show_letter(beat_id, letter_data)
	else:
		print("StoryLetter: No letter found for beat_id '%s'" % beat_id)

# Allow ESC key to close
func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
		return
