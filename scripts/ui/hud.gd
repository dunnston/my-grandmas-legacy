extends CanvasLayer

# HUD - Heads-up display showing game state and shop controls

# Node references
@onready var day_label: Label = $Panel/VBox/DayLabel
@onready var phase_label: Label = $Panel/VBox/PhaseLabel
@onready var cash_label: Label = $Panel/VBox/CashLabel
@onready var time_label: Label = $Panel/VBox/TimeLabel

@onready var button_container: HBoxContainer = $Panel/VBox/ButtonContainer
@onready var start_business_button: Button = $Panel/VBox/ButtonContainer/StartBusinessButton
@onready var end_business_button: Button = $Panel/VBox/ButtonContainer/EndBusinessButton

# Time control buttons (will be created dynamically)
var time_control_container: HBoxContainer
var pause_button: Button
var speed_1x_button: Button
var speed_2x_button: Button
var speed_3x_button: Button

# Equipment UI Manager
var equipment_ui_manager: Node

# Bag prompt
var bag_prompt_label: Label = null

# Star display
var star_panel: PanelContainer
var star_label: Label
var task_name_label: Label
var task_progress_label: Label

# Task completion popup
var task_completion_popup: Control

# Task menu
var task_menu: Control
var view_tasks_button: Button

func _ready() -> void:
	print("HUD ready")

	# Add to hud group for easy access
	add_to_group("hud")

	# Create time controls
	_create_time_controls()

	# Create bag prompt
	_create_bag_prompt()

	# Create star display
	_create_star_display()

	# Create task completion popup
	_create_task_completion_popup()

	# Create task menu
	_create_task_menu()

	# Create and setup equipment UI manager
	equipment_ui_manager = preload("res://scripts/ui/equipment_ui_manager.gd").new()
	add_child(equipment_ui_manager)
	equipment_ui_manager.setup_uis(self)

	# Connect buttons
	if start_business_button:
		start_business_button.pressed.connect(_on_start_business_pressed)

	if end_business_button:
		end_business_button.pressed.connect(_on_end_business_pressed)

	# Connect to manager signals
	GameManager.shop_state_changed.connect(_on_shop_state_changed)
	GameManager.day_changed.connect(_on_day_changed)
	GameManager.time_scale_changed.connect(_on_time_scale_changed)
	EconomyManager.money_changed.connect(_on_money_changed)

	if TaskManager:
		TaskManager.star_rating_changed.connect(_on_star_rating_changed)
		TaskManager.task_progress_updated.connect(_on_task_progress_updated)
		TaskManager.task_completed.connect(_on_task_completed)

	# Initial update
	_update_display()
	_update_time_control_buttons()
	_update_star_display()

func _process(_delta: float) -> void:
	# Update time display
	if time_label:
		var time_scale_indicator = ""
		if GameManager.is_game_paused():
			time_scale_indicator = " [PAUSED]"
		else:
			var scale = GameManager.get_time_scale()
			if scale > 1.0:
				time_scale_indicator = " [%.0fx]" % scale
		time_label.text = "Time: " + GameManager.get_game_time_formatted() + time_scale_indicator

func _update_display() -> void:
	"""Update all HUD elements"""
	if day_label:
		day_label.text = "Day %d" % GameManager.get_current_day()

	if phase_label:
		var shop_status: String = "OPEN" if GameManager.is_shop_open() else "CLOSED"
		var time_of_day: String = GameManager.get_time_of_day_string()
		phase_label.text = "Shop: %s (%s)" % [shop_status, time_of_day]

	if cash_label:
		cash_label.text = "Cash: $%.2f" % EconomyManager.get_current_cash()

	_update_buttons()

func _update_buttons() -> void:
	"""Show/hide shop control buttons based on current state"""
	var is_open: bool = GameManager.is_shop_open()

	if start_business_button:
		start_business_button.text = "Open Shop"
		start_business_button.visible = not is_open

	if end_business_button:
		end_business_button.text = "Close Shop"
		end_business_button.visible = is_open

func show_phase_info(phase_name: String, description: String) -> void:
	"""Show phase information (called by bakery script)"""
	print("HUD: %s - %s" % [phase_name, description])

func _on_shop_state_changed(_is_open: bool) -> void:
	"""Called when shop state changes"""
	_update_display()

func _on_day_changed(_new_day: int) -> void:
	"""Called when day changes"""
	_update_display()

func _on_money_changed(_new_amount: float) -> void:
	"""Called when money changes"""
	if cash_label:
		cash_label.text = "Cash: $%.2f" % EconomyManager.get_current_cash()

func _on_time_scale_changed(_new_scale: float) -> void:
	"""Called when time scale changes"""
	_update_time_control_buttons()

func _on_start_business_pressed() -> void:
	"""Open shop button pressed"""
	print("HUD: Opening shop")
	GameManager.open_shop()

func _on_end_business_pressed() -> void:
	"""Close shop button pressed"""
	print("HUD: Closing shop")
	GameManager.close_shop()

# ============================================================================
# TIME CONTROLS
# ============================================================================

func _create_time_controls() -> void:
	"""Create time control buttons (pause, 1x, 2x, 3x)"""
	time_control_container = HBoxContainer.new()
	time_control_container.name = "TimeControlContainer"

	var label = Label.new()
	label.text = "Time: "
	label.add_theme_font_size_override("font_size", 16)
	time_control_container.add_child(label)

	pause_button = Button.new()
	pause_button.text = "Pause"
	pause_button.custom_minimum_size = Vector2(80, 30)
	pause_button.pressed.connect(_on_pause_pressed)
	time_control_container.add_child(pause_button)

	speed_1x_button = Button.new()
	speed_1x_button.text = "1x"
	speed_1x_button.custom_minimum_size = Vector2(50, 30)
	speed_1x_button.pressed.connect(_on_speed_1x_pressed)
	time_control_container.add_child(speed_1x_button)

	speed_2x_button = Button.new()
	speed_2x_button.text = "2x"
	speed_2x_button.custom_minimum_size = Vector2(50, 30)
	speed_2x_button.pressed.connect(_on_speed_2x_pressed)
	time_control_container.add_child(speed_2x_button)

	speed_3x_button = Button.new()
	speed_3x_button.text = "3x"
	speed_3x_button.custom_minimum_size = Vector2(50, 30)
	speed_3x_button.pressed.connect(_on_speed_3x_pressed)
	time_control_container.add_child(speed_3x_button)

	var vbox = $Panel/VBox
	if vbox and time_label:
		var time_label_index = time_label.get_index()
		vbox.add_child(time_control_container)
		vbox.move_child(time_control_container, time_label_index + 1)

	print("HUD: Time controls created")

func _update_time_control_buttons() -> void:
	"""Update visual state of time control buttons"""
	var is_paused = GameManager.is_game_paused()
	var time_scale = GameManager.get_time_scale()

	if pause_button:
		pause_button.modulate = Color.WHITE if is_paused else Color(0.7, 0.7, 0.7)

	if speed_1x_button:
		speed_1x_button.modulate = Color.WHITE if (not is_paused and time_scale == 1.0) else Color(0.7, 0.7, 0.7)

	if speed_2x_button:
		speed_2x_button.modulate = Color.WHITE if (not is_paused and time_scale == 2.0) else Color(0.7, 0.7, 0.7)

	if speed_3x_button:
		speed_3x_button.modulate = Color.WHITE if (not is_paused and time_scale == 3.0) else Color(0.7, 0.7, 0.7)

func _on_pause_pressed() -> void:
	"""Pause button pressed"""
	if GameManager.is_game_paused():
		GameManager.resume_game()
		print("HUD: Game resumed")
	else:
		GameManager.pause_game()
		print("HUD: Game paused")

func _on_speed_1x_pressed() -> void:
	"""1x speed button pressed"""
	GameManager.resume_game()
	GameManager.set_time_scale(1.0)
	print("HUD: Time scale set to 1x")

func _on_speed_2x_pressed() -> void:
	"""2x speed button pressed"""
	GameManager.resume_game()
	GameManager.set_time_scale(2.0)
	print("HUD: Time scale set to 2x")

func _on_speed_3x_pressed() -> void:
	"""3x speed button pressed"""
	GameManager.resume_game()
	GameManager.set_time_scale(3.0)
	print("HUD: Time scale set to 3x")

func get_equipment_ui_manager() -> Node:
	"""Get the equipment UI manager instance"""
	return equipment_ui_manager

func _create_bag_prompt() -> void:
	"""Create the bag prompt label"""
	bag_prompt_label = Label.new()
	bag_prompt_label.name = "BagPrompt"
	bag_prompt_label.text = "[B] Put Items in Bag"
	bag_prompt_label.add_theme_font_size_override("font_size", 24)
	bag_prompt_label.anchor_left = 0.5
	bag_prompt_label.anchor_top = 1.0
	bag_prompt_label.anchor_right = 0.5
	bag_prompt_label.anchor_bottom = 1.0
	bag_prompt_label.offset_left = -150
	bag_prompt_label.offset_top = -100
	bag_prompt_label.offset_right = 150
	bag_prompt_label.offset_bottom = -50
	bag_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bag_prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(1, 1, 0, 1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	bag_prompt_label.add_theme_stylebox_override("normal", style)
	bag_prompt_label.add_theme_color_override("font_color", Color(1, 1, 0.5, 1))
	add_child(bag_prompt_label)
	bag_prompt_label.hide()

func show_bag_prompt() -> void:
	"""Show the bag prompt"""
	if bag_prompt_label:
		bag_prompt_label.show()

func hide_bag_prompt() -> void:
	"""Hide the bag prompt"""
	if bag_prompt_label:
		bag_prompt_label.hide()

# ============================================================================
# STAR DISPLAY
# ============================================================================

func _create_star_display() -> void:
	"""Create the star rating and task progress display"""
	# Create a panel container for the star display
	star_panel = PanelContainer.new()
	star_panel.name = "StarPanel"

	# Position in top-right corner (below any existing UI)
	star_panel.anchor_left = 1.0
	star_panel.anchor_top = 0.0
	star_panel.anchor_right = 1.0
	star_panel.anchor_bottom = 0.0
	star_panel.offset_left = -260
	star_panel.offset_top = 120  # Moved down to avoid overlap
	star_panel.offset_right = -10
	star_panel.offset_bottom = 320  # Increased height slightly
	star_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN

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
	star_panel.add_theme_stylebox_override("panel", style)

	# Create VBox for content
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	star_panel.add_child(vbox)

	# Star rating label
	star_label = Label.new()
	star_label.name = "StarLabel"
	star_label.text = "★★★★★ (0.0 Stars)"
	star_label.add_theme_font_size_override("font_size", 18)
	star_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
	star_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(star_label)

	# Separator
	var separator = HSeparator.new()
	vbox.add_child(separator)

	# Current task label
	var current_task_header = Label.new()
	current_task_header.text = "CURRENT TASK:"
	current_task_header.add_theme_font_size_override("font_size", 12)
	current_task_header.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(current_task_header)

	# Task name
	task_name_label = Label.new()
	task_name_label.name = "TaskNameLabel"
	task_name_label.text = "No active task"
	task_name_label.add_theme_font_size_override("font_size", 14)
	task_name_label.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
	task_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(task_name_label)

	# Task progress
	task_progress_label = Label.new()
	task_progress_label.name = "TaskProgressLabel"
	task_progress_label.text = ""
	task_progress_label.add_theme_font_size_override("font_size", 12)
	task_progress_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(task_progress_label)

	# View Tasks button
	view_tasks_button = Button.new()
	view_tasks_button.text = "View All Tasks [T]"
	view_tasks_button.custom_minimum_size = Vector2(0, 30)
	view_tasks_button.pressed.connect(_on_view_tasks_pressed)
	vbox.add_child(view_tasks_button)

	add_child(star_panel)
	print("HUD: Star display created")


func _update_star_display() -> void:
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
	# Full stars
	for i in full_stars:
		result += "★"
	# Half star
	if has_half:
		result += "⯨"  # or "☆" as a simpler half-star
	# Empty stars
	for i in empty_stars:
		result += "☆"

	return result


func _on_star_rating_changed(_new_rating: float, _old_rating: float) -> void:
	"""Called when star rating changes"""
	_update_star_display()


func _on_task_progress_updated(_task_id: String, _current: int, _required: int) -> void:
	"""Called when a task's progress is updated"""
	_update_star_display()


func _on_task_completed(task: BakeryTask) -> void:
	"""Called when a task is completed"""
	# Show the celebration popup
	if task_completion_popup:
		var old_rating = TaskManager.get_star_rating() - task.star_reward
		var new_rating = TaskManager.get_star_rating()
		task_completion_popup.show_completion(task, old_rating, new_rating)

	# Update the star display
	_update_star_display()


func _create_task_completion_popup() -> void:
	"""Create the task completion celebration popup"""
	var popup_script = load("res://scripts/ui/task_completion_popup.gd")
	if popup_script:
		task_completion_popup = popup_script.new()
		task_completion_popup.name = "TaskCompletionPopup"
		add_child(task_completion_popup)
		print("HUD: Task completion popup created")
	else:
		push_error("Failed to load task_completion_popup.gd")


func _create_task_menu() -> void:
	"""Create the task menu"""
	var menu_script = load("res://scripts/ui/task_menu.gd")
	if menu_script:
		task_menu = menu_script.new()
		task_menu.name = "TaskMenu"
		add_child(task_menu)
		print("HUD: Task menu created")
	else:
		push_error("Failed to load task_menu.gd")


func _on_view_tasks_pressed() -> void:
	"""Open the task menu"""
	if task_menu and task_menu.has_method("show_menu"):
		task_menu.show_menu()


func _unhandled_input(event: InputEvent) -> void:
	"""Handle hotkey to open task menu"""
	if event.is_action_pressed("ui_focus_next"):  # Tab key, we'll use T
		# Check for 'T' key
		if event is InputEventKey and event.keycode == KEY_T and not event.is_echo():
			if task_menu and task_menu.has_method("show_menu"):
				task_menu.show_menu()
				get_viewport().set_input_as_handled()
