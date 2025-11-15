## TaskCompletionPopup
## Full-screen celebration popup shown when a task is completed
extends Control

## Signals
signal popup_closed
signal view_unlocks_pressed

## Node references (created dynamically)
var overlay: ColorRect
var popup_panel: PanelContainer
var task_name_label: Label
var star_reward_label: Label
var star_change_label: Label
var unlocks_label: RichTextLabel
var awesome_button: Button
var view_unlocks_button: Button

## Stored task data
var completed_task: BakeryTask
var old_star_rating: float
var new_star_rating: float


func _ready() -> void:
	# Start hidden
	visible = false
	mouse_filter = MOUSE_FILTER_IGNORE


func show_completion(task: BakeryTask, old_stars: float, new_stars: float) -> void:
	"""Display the task completion popup"""
	completed_task = task
	old_star_rating = old_stars
	new_star_rating = new_stars

	# Build UI if not already built
	if not overlay:
		_build_ui()

	# Update content
	_update_content()

	# Show the popup
	visible = true
	mouse_filter = MOUSE_FILTER_STOP

	# Play animation/effects
	_play_entrance_animation()


func _build_ui() -> void:
	"""Build the popup UI structure"""
	# Semi-transparent overlay
	overlay = ColorRect.new()
	overlay.name = "Overlay"
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	add_child(overlay)

	# Center panel
	popup_panel = PanelContainer.new()
	popup_panel.name = "PopupPanel"
	popup_panel.anchor_left = 0.5
	popup_panel.anchor_top = 0.5
	popup_panel.anchor_right = 0.5
	popup_panel.anchor_bottom = 0.5
	popup_panel.offset_left = -300
	popup_panel.offset_top = -250
	popup_panel.offset_right = 300
	popup_panel.offset_bottom = 250
	popup_panel.grow_horizontal = GROW_DIRECTION_BOTH
	popup_panel.grow_vertical = GROW_DIRECTION_BOTH

	# Style the panel
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.15, 0.15, 0.2, 0.95)
	panel_style.border_width_left = 4
	panel_style.border_width_right = 4
	panel_style.border_width_top = 4
	panel_style.border_width_bottom = 4
	panel_style.border_color = Color(1.0, 0.8, 0.0, 1.0)
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel_style.corner_radius_bottom_right = 12
	panel_style.content_margin_left = 30
	panel_style.content_margin_right = 30
	panel_style.content_margin_top = 30
	panel_style.content_margin_bottom = 30
	popup_panel.add_theme_stylebox_override("panel", panel_style)

	add_child(popup_panel)

	# VBox for content
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	popup_panel.add_child(vbox)

	# Header: "TASK COMPLETED!"
	var header = Label.new()
	header.text = "TASK COMPLETED!"
	header.add_theme_font_size_override("font_size", 32)
	header.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(header)

	# Separator
	var sep1 = HSeparator.new()
	vbox.add_child(sep1)

	# Task name
	task_name_label = Label.new()
	task_name_label.text = "Task Name Here"
	task_name_label.add_theme_font_size_override("font_size", 24)
	task_name_label.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
	task_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(task_name_label)

	# Task description
	var task_desc_label = Label.new()
	task_desc_label.name = "TaskDescLabel"
	task_desc_label.text = "Task description here"
	task_desc_label.add_theme_font_size_override("font_size", 14)
	task_desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	task_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	task_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(task_desc_label)

	# Spacer
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer1)

	# Star reward
	star_reward_label = Label.new()
	star_reward_label.text = "★ +0.5 STARS!"
	star_reward_label.add_theme_font_size_override("font_size", 28)
	star_reward_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
	star_reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(star_reward_label)

	# Star change (old → new)
	star_change_label = Label.new()
	star_change_label.text = "★★★☆☆ → ★★★★☆"
	star_change_label.add_theme_font_size_override("font_size", 20)
	star_change_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
	star_change_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(star_change_label)

	# Spacer
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer2)

	# Unlocks header
	var unlocks_header = Label.new()
	unlocks_header.text = "UNLOCKED:"
	unlocks_header.add_theme_font_size_override("font_size", 18)
	unlocks_header.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	unlocks_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(unlocks_header)

	# Unlocks list (RichTextLabel for formatting)
	unlocks_label = RichTextLabel.new()
	unlocks_label.bbcode_enabled = true
	unlocks_label.fit_content = true
	unlocks_label.scroll_active = false
	unlocks_label.add_theme_font_size_override("normal_font_size", 16)
	unlocks_label.add_theme_color_override("default_color", Color(0.9, 1.0, 0.9))
	unlocks_label.custom_minimum_size = Vector2(0, 80)
	vbox.add_child(unlocks_label)

	# Spacer to push buttons to bottom
	var spacer3 = Control.new()
	spacer3.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer3)

	# Buttons
	var button_hbox = HBoxContainer.new()
	button_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	button_hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(button_hbox)

	awesome_button = Button.new()
	awesome_button.text = "Awesome!"
	awesome_button.custom_minimum_size = Vector2(150, 50)
	awesome_button.add_theme_font_size_override("font_size", 18)
	awesome_button.pressed.connect(_on_awesome_pressed)
	button_hbox.add_child(awesome_button)

	view_unlocks_button = Button.new()
	view_unlocks_button.text = "View Unlocks"
	view_unlocks_button.custom_minimum_size = Vector2(150, 50)
	view_unlocks_button.add_theme_font_size_override("font_size", 18)
	view_unlocks_button.pressed.connect(_on_view_unlocks_pressed)
	button_hbox.add_child(view_unlocks_button)

	print("TaskCompletionPopup UI built")


func _update_content() -> void:
	"""Update popup content with current task data"""
	if not completed_task:
		return

	# Task name
	if task_name_label:
		task_name_label.text = "\"%s\"" % completed_task.task_name

	# Task description
	var desc_label = popup_panel.find_child("TaskDescLabel", true, false)
	if desc_label and desc_label is Label:
		desc_label.text = completed_task.task_description

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
	tween.tween_property(popup_panel, "modulate:a", 0.0, 0.2)
	tween.tween_property(overlay, "modulate:a", 0.0, 0.2)

	await tween.finished

	visible = false
	mouse_filter = MOUSE_FILTER_IGNORE
	popup_closed.emit()
