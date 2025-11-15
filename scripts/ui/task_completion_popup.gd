## TaskCompletionPopup
## Full-screen celebration popup shown when a task is completed
extends Control

## Signals
signal popup_closed
signal view_unlocks_pressed

## Node references from scene
@onready var popup_panel: PanelContainer = $PopupPanel
@onready var task_name_label: Label = $PopupPanel/VBox/TaskNameLabel
@onready var task_desc_label: Label = $PopupPanel/VBox/TaskDescLabel
@onready var star_reward_label: Label = $PopupPanel/VBox/StarRewardLabel
@onready var star_change_label: Label = $PopupPanel/VBox/StarChangeLabel
@onready var unlocks_label: RichTextLabel = $PopupPanel/VBox/UnlocksLabel
@onready var awesome_button: Button = $PopupPanel/VBox/ButtonHBox/AwesomeButton
@onready var view_unlocks_button: Button = $PopupPanel/VBox/ButtonHBox/ViewUnlocksButton

## Stored task data
var completed_task: BakeryTask
var old_star_rating: float
var new_star_rating: float


func _ready() -> void:
	# Start hidden
	visible = false
	mouse_filter = MOUSE_FILTER_IGNORE

	# Connect buttons
	if awesome_button:
		awesome_button.pressed.connect(_on_awesome_pressed)
	if view_unlocks_button:
		view_unlocks_button.pressed.connect(_on_view_unlocks_pressed)

	print("TaskCompletionPopup ready")


func show_completion(task: BakeryTask, old_stars: float, new_stars: float) -> void:
	"""Display the task completion popup"""
	completed_task = task
	old_star_rating = old_stars
	new_star_rating = new_stars

	# Update content
	_update_content()

	# Show the popup
	visible = true
	mouse_filter = MOUSE_FILTER_STOP

	# Play animation/effects
	_play_entrance_animation()


func _update_content() -> void:
	"""Update popup content with current task data"""
	if not completed_task:
		return

	# Task name
	if task_name_label:
		task_name_label.text = "\"%s\"" % completed_task.task_name

	# Task description
	if task_desc_label:
		task_desc_label.text = completed_task.task_description

	# Star reward
	if star_reward_label:
		star_reward_label.text = "★ +%.1f STARS!" % completed_task.star_reward

	# Star change
	if star_change_label:
		var old_visual = _get_star_visual(old_star_rating)
		var new_visual = _get_star_visual(new_star_rating)
		star_change_label.text = "%s → %s" % [old_visual, new_visual]

	# Unlocks
	if unlocks_label:
		if completed_task.unlocks.size() > 0:
			var unlocks_text = "[center]"
			for unlock in completed_task.unlocks:
				var unlock_name = _format_unlock_name(unlock)
				unlocks_text += "• %s\n" % unlock_name
			unlocks_text += "[/center]"
			unlocks_label.text = unlocks_text
		else:
			unlocks_label.text = "[center][i]No new unlocks[/i][/center]"


func _format_unlock_name(unlock_id: String) -> String:
	"""Format unlock ID into readable name"""
	# Replace underscores with spaces and capitalize
	var formatted = unlock_id.replace("_", " ").capitalize()

	# Add icons/prefixes based on type
	if unlock_id.begins_with("recipe_group_"):
		return "📖 " + formatted.replace("Recipe Group ", "")
	elif unlock_id.begins_with("equipment_"):
		return "🛠️ " + formatted.replace("Equipment ", "")
	elif unlock_id.begins_with("story_"):
		return "📜 " + formatted.replace("Story ", "")
	else:
		return "✨ " + formatted


func _get_star_visual(rating: float) -> String:
	"""Convert star rating to visual representation"""
	var full_stars = int(rating)
	var has_half = (rating - full_stars) >= 0.5
	var empty_stars = 5 - full_stars - (1 if has_half else 0)

	var result = ""
	for i in full_stars:
		result += "★"
	if has_half:
		result += "⯨"
	for i in empty_stars:
		result += "☆"

	return result


func _play_entrance_animation() -> void:
	"""Play entrance animation (scale/fade in)"""
	# Simple scale animation
	popup_panel.scale = Vector2(0.5, 0.5)
	popup_panel.modulate.a = 0.0

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup_panel, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(popup_panel, "modulate:a", 1.0, 0.3)

	# TODO: Add particle effects (confetti, sparkles)


func _on_awesome_pressed() -> void:
	"""Close button pressed"""
	_close_popup()


func _on_view_unlocks_pressed() -> void:
	"""View unlocks button pressed"""
	view_unlocks_pressed.emit()
	_close_popup()


func _close_popup() -> void:
	"""Close the popup with animation"""
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup_panel, "scale", Vector2(0.8, 0.8), 0.2)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)

	await tween.finished

	visible = false
	mouse_filter = MOUSE_FILTER_IGNORE
	popup_closed.emit()
