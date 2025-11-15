## TaskMenu
## Panel showing all tasks, progress, and rewards
extends Control

## Signals
signal task_menu_closed

## Node references
var panel: PanelContainer
var tabs: TabContainer
var main_tasks_scroll: ScrollContainer
var main_tasks_vbox: VBoxContainer
var close_button: Button

## Currently selected task
var selected_task: BakeryTask = null


func _ready() -> void:
	visible = false
	mouse_filter = MOUSE_FILTER_IGNORE

	_build_ui()

	# Connect to TaskManager signals
	if TaskManager:
		TaskManager.task_progress_updated.connect(_on_task_progress_updated)
		TaskManager.task_completed.connect(_on_task_completed)
		TaskManager.star_rating_changed.connect(_on_star_rating_changed)


func show_menu() -> void:
	"""Show the task menu"""
	_refresh_task_display()
	visible = true
	mouse_filter = MOUSE_FILTER_STOP


func hide_menu() -> void:
	"""Hide the task menu"""
	visible = false
	mouse_filter = MOUSE_FILTER_IGNORE
	task_menu_closed.emit()


func _build_ui() -> void:
	"""Build the task menu UI"""
	# Semi-transparent overlay
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.5)
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.mouse_filter = MOUSE_FILTER_STOP
	add_child(overlay)

	# Center panel - use margins for better positioning
	panel = PanelContainer.new()
	panel.anchor_left = 0.0
	panel.anchor_top = 0.0
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = 100
	panel.offset_top = 50
	panel.offset_right = -100
	panel.offset_bottom = -50

	# Style
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	panel_style.border_width_left = 3
	panel_style.border_width_right = 3
	panel_style.border_width_top = 3
	panel_style.border_width_bottom = 3
	panel_style.border_color = Color(1.0, 0.8, 0.0, 0.8)
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	panel_style.content_margin_left = 20
	panel_style.content_margin_right = 20
	panel_style.content_margin_top = 20
	panel_style.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", panel_style)

	add_child(panel)

	# Main VBox
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 10)
	panel.add_child(main_vbox)

	# Header
	var header_hbox = HBoxContainer.new()
	main_vbox.add_child(header_hbox)

	var title = Label.new()
	title.text = "TASKS & PROGRESSION"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(title)

	# Star rating display
	var star_label = Label.new()
	star_label.name = "StarRatingLabel"
	star_label.text = "★★★★★ 0.0 / 5.0"
	star_label.add_theme_font_size_override("font_size", 24)
	star_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
	header_hbox.add_child(star_label)

	var sep1 = HSeparator.new()
	main_vbox.add_child(sep1)

	# Tab container for different task categories
	tabs = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(tabs)

	# Main Tasks Tab
	main_tasks_scroll = ScrollContainer.new()
	main_tasks_scroll.name = "Main Progression"
	main_tasks_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.add_child(main_tasks_scroll)

	main_tasks_vbox = VBoxContainer.new()
	main_tasks_vbox.add_theme_constant_override("separation", 10)
	main_tasks_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_tasks_scroll.add_child(main_tasks_vbox)

	# Close button
	close_button = Button.new()
	close_button.text = "Close [ESC]"
	close_button.custom_minimum_size = Vector2(200, 50)
	close_button.pressed.connect(hide_menu)
	main_vbox.add_child(close_button)

	print("TaskMenu UI built")


func _refresh_task_display() -> void:
	"""Refresh the display of all tasks"""
	if not TaskManager:
		return

	# Update star rating
	var star_label = panel.find_child("StarRatingLabel", true, false)
	if star_label and star_label is Label:
		var rating = TaskManager.get_star_rating()
		var star_visual = _get_star_visual(rating)
		star_label.text = "%s %.1f / 5.0" % [star_visual, rating]

	# Clear existing task cards
	for child in main_tasks_vbox.get_children():
		child.queue_free()

	# Add main progression tasks
	var main_tasks = TaskManager.get_main_progression_tasks()
	for task in main_tasks:
		_add_task_card(task)


func _add_task_card(task: BakeryTask) -> void:
	"""Add a task card to the display"""
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 120)

	# Card style based on completion status
	var card_style = StyleBoxFlat.new()
	if task.is_completed:
		card_style.bg_color = Color(0.1, 0.3, 0.1, 0.7)  # Green tint
		card_style.border_color = Color(0.3, 0.8, 0.3, 0.8)
	elif task.can_start(TaskManager.get_star_rating()):
		card_style.bg_color = Color(0.15, 0.15, 0.25, 0.7)  # Active
		card_style.border_color = Color(0.5, 0.7, 1.0, 0.8)
	else:
		card_style.bg_color = Color(0.1, 0.1, 0.1, 0.5)  # Locked
		card_style.border_color = Color(0.3, 0.3, 0.3, 0.5)

	card_style.border_width_left = 2
	card_style.border_width_right = 2
	card_style.border_width_top = 2
	card_style.border_width_bottom = 2
	card_style.corner_radius_top_left = 5
	card_style.corner_radius_top_right = 5
	card_style.corner_radius_bottom_left = 5
	card_style.corner_radius_bottom_right = 5
	card_style.content_margin_left = 15
	card_style.content_margin_right = 15
	card_style.content_margin_top = 10
	card_style.content_margin_bottom = 10
	card.add_theme_stylebox_override("panel", card_style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	card.add_child(vbox)

	# Header: Task name and status
	var header_hbox = HBoxContainer.new()
	vbox.add_child(header_hbox)

	var task_name = Label.new()
	task_name.text = task.task_name
	task_name.add_theme_font_size_override("font_size", 20)
	task_name.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	task_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(task_name)

	var status = Label.new()
	status.text = task.get_status_display()
	status.add_theme_font_size_override("font_size", 16)
	if task.is_completed:
		status.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
	elif task.can_start(TaskManager.get_star_rating()):
		status.add_theme_color_override("font_color", Color(0.5, 0.7, 1.0))
	else:
		status.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	header_hbox.add_child(status)

	# Description
	var desc = Label.new()
	desc.text = task.task_description
	desc.add_theme_font_size_override("font_size", 14)
	desc.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc)

	# Progress bar (if not completed and unlocked)
	if not task.is_completed and task.can_start(TaskManager.get_star_rating()):
		var progress_hbox = HBoxContainer.new()
		vbox.add_child(progress_hbox)

		var progress_label = Label.new()
		progress_label.text = "Progress: " + task.get_progress_text()
		progress_label.add_theme_font_size_override("font_size", 14)
		progress_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		progress_hbox.add_child(progress_label)

		progress_hbox.add_child(Control.new())  # Spacer

		var progress_pct = Label.new()
		progress_pct.text = "%.0f%%" % (task.get_progress_percentage() * 100.0)
		progress_pct.add_theme_font_size_override("font_size", 14)
		progress_pct.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		progress_hbox.add_child(progress_pct)

		# Visual progress bar
		var progress_bar_bg = ColorRect.new()
		progress_bar_bg.custom_minimum_size = Vector2(0, 8)
		progress_bar_bg.color = Color(0.2, 0.2, 0.2, 0.8)
		vbox.add_child(progress_bar_bg)

		var progress_bar_fill = ColorRect.new()
		progress_bar_fill.custom_minimum_size = Vector2(0, 8)
		progress_bar_fill.color = Color(0.3, 0.8, 1.0, 0.9)
		progress_bar_fill.anchor_right = task.get_progress_percentage()
		progress_bar_bg.add_child(progress_bar_fill)

	# Rewards
	var rewards_hbox = HBoxContainer.new()
	vbox.add_child(rewards_hbox)

	var reward_icon = Label.new()
	reward_icon.text = "⭐"
	reward_icon.add_theme_font_size_override("font_size", 16)
	rewards_hbox.add_child(reward_icon)

	var reward_text = Label.new()
	reward_text.text = "Reward: +%.1f Stars" % task.star_reward
	reward_text.add_theme_font_size_override("font_size", 14)
	reward_text.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	rewards_hbox.add_child(reward_text)

	# Show unlocks if any
	if task.unlocks.size() > 0:
		rewards_hbox.add_child(Label.new())  # Spacer

		var unlocks_label = Label.new()
		unlocks_label.text = " | Unlocks: " + str(task.unlocks.size()) + " items"
		unlocks_label.add_theme_font_size_override("font_size", 12)
		unlocks_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		rewards_hbox.add_child(unlocks_label)

	main_tasks_vbox.add_child(card)


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


func _input(event: InputEvent) -> void:
	"""Handle input for closing menu"""
	if visible and event.is_action_pressed("ui_cancel"):
		hide_menu()
		get_viewport().set_input_as_handled()


func _on_task_progress_updated(_task_id: String, _current: int, _required: int) -> void:
	"""Refresh when task progress updates"""
	if visible:
		_refresh_task_display()


func _on_task_completed(_task: BakeryTask) -> void:
	"""Refresh when task completes"""
	if visible:
		_refresh_task_display()


func _on_star_rating_changed(_new_rating: float, _old_rating: float) -> void:
	"""Refresh when stars change"""
	if visible:
		_refresh_task_display()
