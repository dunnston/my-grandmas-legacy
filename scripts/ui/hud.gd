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

func _ready() -> void:
	print("HUD ready")

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
