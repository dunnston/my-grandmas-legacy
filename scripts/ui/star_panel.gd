## StarPanel
## Displays current star rating and active task progress
extends PanelContainer

## Node references
@onready var star_label: Label = $VBox/StarLabel
@onready var task_name_label: Label = $VBox/TaskNameLabel
@onready var task_progress_label: Label = $VBox/TaskProgressLabel
@onready var view_tasks_button: Button = $VBox/ViewTasksButton

## Signals
signal view_tasks_pressed


func _ready() -> void:
	# Style the panel
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.9)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(1.0, 0.8, 0.0, 0.8)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	add_theme_stylebox_override("panel", style)

	# Style labels
	if star_label:
		star_label.add_theme_font_size_override("font_size", 18)
		star_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))

	if $VBox/TaskHeader:
		$VBox/TaskHeader.add_theme_font_size_override("font_size", 12)
		$VBox/TaskHeader.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))

	if task_name_label:
		task_name_label.add_theme_font_size_override("font_size", 14)
		task_name_label.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))

	if task_progress_label:
		task_progress_label.add_theme_font_size_override("font_size", 12)
		task_progress_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))

	if view_tasks_button:
		view_tasks_button.custom_minimum_size = Vector2(0, 30)
		view_tasks_button.pressed.connect(_on_view_tasks_pressed)

	# Connect to TaskManager signals
	if TaskManager:
		TaskManager.star_rating_changed.connect(_on_star_rating_changed)
		TaskManager.task_progress_updated.connect(_on_task_progress_updated)
		TaskManager.task_completed.connect(_on_task_completed)

	# Initial update
	update_display()


func update_display() -> void:
	"""Update the star rating and task progress display"""
	if not TaskManager:
		return

	# Update star rating
	var star_rating: float = TaskManager.get_star_rating()
	var star_text: String = _get_star_visual(star_rating)
	if star_label:
		star_label.text = "%s (%.1f Stars)" % [star_text, star_rating]

	# Update current task
	var main_tasks = TaskManager.get_main_progression_tasks()
	var current_task: BakeryTask = null

	# Find the first incomplete main task that's unlocked
	for task in main_tasks:
		if not task.is_completed and task.can_start(star_rating):
			current_task = task
			break

	if current_task and task_name_label and task_progress_label:
		task_name_label.text = "\"%s\"" % current_task.task_name
		var progress_text = current_task.get_progress_text()
		var progress_pct = current_task.get_progress_percentage() * 100.0

		# Create a simple text progress bar
		var bar_width = 10
		var filled = int(progress_pct / 100.0 * bar_width)
		var empty = bar_width - filled
		var bar = "█".repeat(filled) + "░".repeat(empty)

		task_progress_label.text = "%s\n%s %.0f%%" % [progress_text, bar, progress_pct]
	elif task_name_label and task_progress_label:
		task_name_label.text = "All tasks complete!"
		task_progress_label.text = "You're a Master Baker!"


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


func _on_star_rating_changed(_new_rating: float, _old_rating: float) -> void:
	"""Called when star rating changes"""
	update_display()


func _on_task_progress_updated(_task_id: String, _current: int, _required: int) -> void:
	"""Called when a task's progress is updated"""
	update_display()


func _on_task_completed(_task: BakeryTask) -> void:
	"""Called when a task is completed"""
	update_display()


func _on_view_tasks_pressed() -> void:
	"""View tasks button pressed"""
	view_tasks_pressed.emit()
