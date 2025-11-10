extends CanvasLayer

# HUD - Heads-up display showing game state and phase controls

# Node references
@onready var day_label: Label = $Panel/VBox/DayLabel
@onready var phase_label: Label = $Panel/VBox/PhaseLabel
@onready var cash_label: Label = $Panel/VBox/CashLabel
@onready var time_label: Label = $Panel/VBox/TimeLabel

@onready var button_container: HBoxContainer = $Panel/VBox/ButtonContainer
@onready var start_business_button: Button = $Panel/VBox/ButtonContainer/StartBusinessButton
@onready var end_business_button: Button = $Panel/VBox/ButtonContainer/EndBusinessButton

# Equipment UI Manager
var equipment_ui_manager: Node

# Bag prompt
var bag_prompt_label: Label = null

func _ready() -> void:
	print("HUD ready")

	# Add to hud group for easy access
	add_to_group("hud")

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
	GameManager.phase_changed.connect(_on_phase_changed)
	GameManager.day_changed.connect(_on_day_changed)
	EconomyManager.money_changed.connect(_on_money_changed)

	# Initial update
	_update_display()

func _process(_delta: float) -> void:
	# Update time display
	if time_label:
		time_label.text = "Time: " + GameManager.get_game_time_formatted()

func _update_display() -> void:
	"""Update all HUD elements"""
	if day_label:
		day_label.text = "Day %d" % GameManager.get_current_day()

	if phase_label:
		var phase_name: String = GameManager.Phase.keys()[GameManager.get_current_phase()]
		phase_label.text = "Phase: " + phase_name

	if cash_label:
		cash_label.text = "Cash: $%.2f" % EconomyManager.get_current_cash()

	_update_buttons()

func _update_buttons() -> void:
	"""Show/hide phase transition buttons based on current phase"""
	var current_phase: GameManager.Phase = GameManager.get_current_phase()

	if start_business_button:
		start_business_button.visible = (current_phase == GameManager.Phase.BAKING)

	if end_business_button:
		end_business_button.visible = (current_phase == GameManager.Phase.BUSINESS)

func show_phase_info(phase_name: String, description: String) -> void:
	"""Show phase information (called by bakery script)"""
	print("HUD: %s - %s" % [phase_name, description])
	# Could show a temporary popup here

func _on_phase_changed(_new_phase: GameManager.Phase) -> void:
	"""Called when game phase changes"""
	_update_display()

func _on_day_changed(_new_day: int) -> void:
	"""Called when day changes"""
	_update_display()

func _on_money_changed(_new_amount: float) -> void:
	"""Called when money changes"""
	if cash_label:
		cash_label.text = "Cash: $%.2f" % EconomyManager.get_current_cash()

func _on_start_business_pressed() -> void:
	"""Start business phase button pressed"""
	print("HUD: Starting Business phase")
	GameManager.start_business_phase()

func _on_end_business_pressed() -> void:
	"""End business phase button pressed"""
	print("HUD: Ending Business phase")
	GameManager.start_cleanup_phase()

# Equipment UI access
func get_equipment_ui_manager() -> Node:
	"""Get the equipment UI manager instance"""
	return equipment_ui_manager

# Bag prompt functions
func _create_bag_prompt() -> void:
	"""Create the bag prompt label"""
	bag_prompt_label = Label.new()
	bag_prompt_label.name = "BagPrompt"
	bag_prompt_label.text = "[B] Put Items in Bag"
	bag_prompt_label.add_theme_font_size_override("font_size", 24)

	# Position at bottom-center of screen
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

	# Style it
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(1, 1, 0, 1)  # Yellow border
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	bag_prompt_label.add_theme_stylebox_override("normal", style)

	# Set text color to yellow
	bag_prompt_label.add_theme_color_override("font_color", Color(1, 1, 0.5, 1))

	add_child(bag_prompt_label)
	bag_prompt_label.hide()

func show_bag_prompt() -> void:
	"""Show the bag prompt"""
	print("HUD: show_bag_prompt() called, label exists: ", bag_prompt_label != null)
	if bag_prompt_label:
		bag_prompt_label.show()
		print("HUD: Bag prompt is now visible: ", bag_prompt_label.visible)
	else:
		print("HUD: ERROR - bag_prompt_label is null!")

func hide_bag_prompt() -> void:
	"""Hide the bag prompt"""
	if bag_prompt_label:
		bag_prompt_label.hide()
