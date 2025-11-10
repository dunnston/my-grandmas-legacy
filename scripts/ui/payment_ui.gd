class_name PaymentUI
extends Control

# Payment UI - Interactive cash/card payment mini-game
# 70% cash (change making), 30% card (swipe)

signal payment_completed(transaction_time: float, had_errors: bool, success: bool)

enum PaymentMethod { CASH, CARD }

# UI elements
var main_panel: Panel = null
var title_label: Label = null
var content_container: VBoxContainer = null
var instruction_label: Label = null

# Cash payment UI
var cash_container: VBoxContainer = null
var amount_due_label: Label = null
var amount_given_label: Label = null
var change_needed_label: Label = null
var change_display_label: Label = null
var bills_coins_container: GridContainer = null
var submit_button: Button = null
var clear_button: Button = null

# Card payment UI
var card_container: VBoxContainer = null
var card_reader_label: Label = null
var swipe_button: Button = null
var processing_label: Label = null

# State
var payment_method: PaymentMethod
var amount_due: float = 0.0
var amount_given: float = 0.0
var change_needed: float = 0.0
var player_change: float = 0.0
var error_count: int = 0
var start_time: float = 0.0

# Bill/coin values
var denominations = [
	{"name": "$20", "value": 20.00},
	{"name": "$10", "value": 10.00},
	{"name": "$5", "value": 5.00},
	{"name": "$1", "value": 1.00},
	{"name": "Quarter", "value": 0.25},
	{"name": "Dime", "value": 0.10},
	{"name": "Nickel", "value": 0.05},
	{"name": "Penny", "value": 0.01}
]

func _ready() -> void:
	print("PaymentUI: _ready() called")

	# Fill viewport
	anchor_right = 1.0
	anchor_bottom = 1.0
	z_index = 100

	_create_ui()
	hide()
	print("PaymentUI: Ready and hidden")

func _create_ui() -> void:
	"""Create the payment UI"""
	# Main panel (centered)
	main_panel = Panel.new()
	main_panel.custom_minimum_size = Vector2(600, 500)
	main_panel.anchor_left = 0.5
	main_panel.anchor_top = 0.5
	main_panel.anchor_right = 0.5
	main_panel.anchor_bottom = 0.5
	main_panel.offset_left = -300
	main_panel.offset_top = -250
	main_panel.offset_right = 300
	main_panel.offset_bottom = 250

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.25, 0.95)
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.4, 0.8, 0.4)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	main_panel.add_theme_stylebox_override("panel", style)
	add_child(main_panel)

	# Content
	content_container = VBoxContainer.new()
	content_container.position = Vector2(20, 20)
	content_container.size = Vector2(560, 460)
	main_panel.add_child(content_container)

	# Title
	title_label = Label.new()
	title_label.text = "PAYMENT"
	title_label.add_theme_font_size_override("font_size", 32)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_container.add_child(title_label)

	# Instructions
	instruction_label = Label.new()
	instruction_label.add_theme_font_size_override("font_size", 18)
	instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_container.add_child(instruction_label)

	# Space
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 20)
	content_container.add_child(spacer1)

func show_payment(total: float) -> void:
	"""Start payment mini-game"""
	print("PaymentUI: show_payment() called - Total: $%.2f" % total)

	amount_due = total
	error_count = 0
	player_change = 0.0
	start_time = Time.get_ticks_msec() / 1000.0

	# Randomly choose payment method (70% cash, 30% card)
	var rand = randf()
	payment_method = PaymentMethod.CASH if rand < 0.7 else PaymentMethod.CARD

	print("PaymentUI: Payment method: ", "CASH" if payment_method == PaymentMethod.CASH else "CARD")

	# Clear content
	for child in content_container.get_children():
		if child != title_label and child != instruction_label:
			content_container.remove_child(child)
			child.queue_free()

	if payment_method == PaymentMethod.CASH:
		_setup_cash_payment()
	else:
		_setup_card_payment()

	# Release mouse for UI interaction
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	show()

func _setup_cash_payment() -> void:
	"""Setup cash payment UI"""
	print("PaymentUI: Setting up cash payment")

	# Generate random amount given (must be >= amount due)
	var overpay_amounts = [0.0, 0.03, 0.50, 1.0, 5.0, 10.0, 20.0]
	amount_given = amount_due + overpay_amounts[randi() % overpay_amounts.size()]
	change_needed = amount_given - amount_due

	instruction_label.text = "Make change for the customer"

	# Amount display
	var info_vbox = VBoxContainer.new()
	info_vbox.custom_minimum_size = Vector2(560, 120)
	content_container.add_child(info_vbox)

	amount_due_label = Label.new()
	amount_due_label.text = "Amount Due: $%.2f" % amount_due
	amount_due_label.add_theme_font_size_override("font_size", 20)
	info_vbox.add_child(amount_due_label)

	amount_given_label = Label.new()
	amount_given_label.text = "Customer Gave: $%.2f" % amount_given
	amount_given_label.add_theme_font_size_override("font_size", 20)
	info_vbox.add_child(amount_given_label)

	change_needed_label = Label.new()
	change_needed_label.text = "Change Needed: $%.2f" % change_needed
	change_needed_label.add_theme_font_size_override("font_size", 24)
	change_needed_label.add_theme_color_override("font_color", Color(1, 1, 0.5))
	info_vbox.add_child(change_needed_label)

	change_display_label = Label.new()
	change_display_label.text = "Your Change: $0.00"
	change_display_label.add_theme_font_size_override("font_size", 20)
	change_display_label.add_theme_color_override("font_color", Color(0.7, 1.0, 0.7))
	info_vbox.add_child(change_display_label)

	# Bills and coins grid
	bills_coins_container = GridContainer.new()
	bills_coins_container.columns = 4
	bills_coins_container.add_theme_constant_override("h_separation", 10)
	bills_coins_container.add_theme_constant_override("v_separation", 10)
	content_container.add_child(bills_coins_container)

	for denom in denominations:
		var btn = Button.new()
		btn.text = denom["name"]
		btn.custom_minimum_size = Vector2(130, 50)
		btn.pressed.connect(_on_denomination_clicked.bind(denom["value"]))
		bills_coins_container.add_child(btn)

	# Buttons
	var button_hbox = HBoxContainer.new()
	button_hbox.add_theme_constant_override("separation", 10)
	content_container.add_child(button_hbox)

	clear_button = Button.new()
	clear_button.text = "Clear"
	clear_button.custom_minimum_size = Vector2(270, 50)
	clear_button.pressed.connect(_on_clear_pressed)
	button_hbox.add_child(clear_button)

	submit_button = Button.new()
	submit_button.text = "Submit Change"
	submit_button.custom_minimum_size = Vector2(270, 50)
	submit_button.pressed.connect(_on_submit_change_pressed)
	button_hbox.add_child(submit_button)

func _setup_card_payment() -> void:
	"""Setup card payment UI"""
	print("PaymentUI: Setting up card payment")

	instruction_label.text = "Swipe the customer's card"

	card_container = VBoxContainer.new()
	card_container.custom_minimum_size = Vector2(560, 300)
	content_container.add_child(card_container)

	# Amount
	var amount_label = Label.new()
	amount_label.text = "Amount Due: $%.2f" % amount_due
	amount_label.add_theme_font_size_override("font_size", 28)
	amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_container.add_child(amount_label)

	# Space
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 40)
	card_container.add_child(spacer2)

	# Card reader visual
	card_reader_label = Label.new()
	card_reader_label.text = "🔲 CARD READER 🔲"
	card_reader_label.add_theme_font_size_override("font_size", 24)
	card_reader_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_container.add_child(card_reader_label)

	# Space
	var spacer3 = Control.new()
	spacer3.custom_minimum_size = Vector2(0, 20)
	card_container.add_child(spacer3)

	# Swipe button
	swipe_button = Button.new()
	swipe_button.text = "SWIPE CARD"
	swipe_button.custom_minimum_size = Vector2(400, 80)
	swipe_button.add_theme_font_size_override("font_size", 24)
	swipe_button.pressed.connect(_on_swipe_card_pressed)

	# Center the button
	var button_center = CenterContainer.new()
	button_center.add_child(swipe_button)
	card_container.add_child(button_center)

	# Processing label (hidden initially)
	processing_label = Label.new()
	processing_label.text = ""
	processing_label.add_theme_font_size_override("font_size", 24)
	processing_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_container.add_child(processing_label)

func _on_denomination_clicked(value: float) -> void:
	"""Player clicked a bill/coin"""
	player_change += value
	_update_change_display()

func _update_change_display() -> void:
	"""Update the change display"""
	if change_display_label:
		change_display_label.text = "Your Change: $%.2f" % player_change

		# Color code
		if abs(player_change - change_needed) < 0.001:  # Correct!
			change_display_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.2))
		elif player_change > change_needed:
			change_display_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.2))
		else:
			change_display_label.add_theme_color_override("font_color", Color(0.7, 1.0, 0.7))

func _on_clear_pressed() -> void:
	"""Clear the change"""
	player_change = 0.0
	_update_change_display()

func _on_submit_change_pressed() -> void:
	"""Submit the change for verification"""
	print("PaymentUI: Checking change - Needed: $%.2f, Given: $%.2f" % [change_needed, player_change])

	# Check if correct (allow 1 cent tolerance for floating point)
	if abs(player_change - change_needed) < 0.01:
		print("  ✓ CORRECT!")
		_complete_payment(true)
	else:
		print("  ✗ INCORRECT!")
		error_count += 1

		# Show error
		var error_label = Label.new()
		error_label.text = "WRONG! Try again. (Error %d)" % error_count
		error_label.add_theme_font_size_override("font_size", 20)
		error_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
		error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		content_container.add_child(error_label)

		# Remove error message after 2 seconds
		await get_tree().create_timer(2.0).timeout
		if error_label:
			content_container.remove_child(error_label)
			error_label.queue_free()

		# Reset
		player_change = 0.0
		_update_change_display()

func _on_swipe_card_pressed() -> void:
	"""Player swiped the card"""
	print("PaymentUI: Card swiped")
	swipe_button.disabled = true

	# Show processing
	processing_label.text = "Processing..."
	await get_tree().create_timer(1.0).timeout

	processing_label.text = "APPROVED!"
	processing_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.2))

	await get_tree().create_timer(1.0).timeout

	_complete_payment(true)

func _complete_payment(success: bool) -> void:
	"""Payment mini-game complete"""
	var end_time = Time.get_ticks_msec() / 1000.0
	var transaction_time = end_time - start_time

	print("PaymentUI: Payment complete!")
	print("  Success: ", success)
	print("  Time: %.2f seconds" % transaction_time)
	print("  Errors: %d" % error_count)

	hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	payment_completed.emit(transaction_time, error_count > 0, success)
