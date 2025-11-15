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

func _ready() -> void:
	print("HUD ready")

	# Add to hud group for easy access
	add_to_group("hud")

	# Create time controls
	_create_time_controls()

	# Create bag prompt
	_create_bag_prompt()

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

	# Initial update
	_update_display()
	_update_time_control_buttons()

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
