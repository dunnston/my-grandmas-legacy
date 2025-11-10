class_name CheckoutUI
extends Control

# CheckoutUI - Interactive checkout interface for serving customers
# Shows customer's desired items, shopping bag, transaction total, and payment mini-game

# Signals
signal checkout_completed(transaction_time: float, had_errors: bool)
signal checkout_cancelled()

# Payment methods
enum PaymentMethod {
	CASH,
	CARD
}

# Checkout state
enum CheckoutState {
	GATHERING_ITEMS,  # Player collecting items from display case
	BAGGING_ITEMS,    # Player adding items to shopping bag
	PAYMENT,          # Payment mini-game
	COMPLETED         # Transaction finished
}

# Node references (UI elements - created dynamically)
var main_panel: Panel = null
var customer_items_list: VBoxContainer = null
var shopping_bag_container: VBoxContainer = null
var transaction_total_label: Label = null
var display_case_access_button: Button = null
var add_to_bag_button: Button = null
var proceed_to_payment_button: Button = null

# Payment UI (created when needed)
var payment_panel: Panel = null
var cash_payment_ui: Control = null
var card_payment_ui: Control = null

# State
var current_state: CheckoutState = CheckoutState.GATHERING_ITEMS
var current_customer: Node3D = null
var customer_desired_items: Array[Dictionary] = []
var bagged_items: Dictionary = {}  # {item_id: quantity}
var transaction_total: float = 0.0
var transaction_start_time: float = 0.0
var error_count: int = 0

# Payment state
var payment_method: PaymentMethod = PaymentMethod.CASH
var amount_due: float = 0.0
var amount_given: float = 0.0
var change_needed: float = 0.0
var player_change_amount: float = 0.0

# Card drag state
var card_dragging: bool = false
var card_drag_offset: Vector2 = Vector2.ZERO

# Player carry inventory
var player_carry_inventory: Dictionary = {}  # Temporary holding area

# UI theming
var panel_style: StyleBoxFlat = null

# Helper function for creating StyleBoxFlat (Godot 4.x compatible)
func _create_styled_panel(bg_color: Color, border_color: Color, border_width: int = 2, corner_radius: int = 8) -> StyleBoxFlat:
	"""Helper to create StyleBoxFlat with Godot 4.x syntax"""
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	# Set border widths individually
	style.border_width_left = border_width
	style.border_width_right = border_width
	style.border_width_top = border_width
	style.border_width_bottom = border_width
	style.border_color = border_color
	# Set corner radius individually
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.corner_radius_bottom_right = corner_radius
	return style

func _ready() -> void:
	print("Checkout UI _ready() called")
	_create_ui()
	hide()  # Hidden by default
	print("Checkout UI initialized and hidden")

func _process(_delta: float) -> void:
	"""Update button states based on carry inventory"""
	if not visible or current_state != CheckoutState.GATHERING_ITEMS:
		return

	# Enable "Add to Bag" button if carry inventory has items
	if add_to_bag_button:
		var carry_inv = InventoryManager.get_inventory("player_carry")
		add_to_bag_button.disabled = carry_inv.is_empty()

func _create_ui() -> void:
	"""Create the complete checkout UI"""
	print("_create_ui() starting...")

	# Create panel background style using helper
	panel_style = _create_styled_panel(
		Color(0.2, 0.2, 0.25, 0.95),  # bg_color
		Color(0.4, 0.4, 0.5),          # border_color
		2,                              # border_width
		8                               # corner_radius
	)
	print("Panel style created")

	# Main panel (centered, large)
	main_panel = Panel.new()
	main_panel.name = "MainPanel"
	main_panel.custom_minimum_size = Vector2(800, 600)
	# Center the panel properly
	main_panel.anchor_left = 0.5
	main_panel.anchor_top = 0.5
	main_panel.anchor_right = 0.5
	main_panel.anchor_bottom = 0.5
	main_panel.offset_left = -400  # Half of width
	main_panel.offset_top = -300   # Half of height
	main_panel.offset_right = 400  # Half of width
	main_panel.offset_bottom = 300 # Half of height
	main_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(main_panel)

	# Title label
	var title = Label.new()
	if not title:
		push_error("Failed to create title Label!")
		return
	title.text = "CHECKOUT"
	title.add_theme_font_size_override("font_size", 32)
	title.position = Vector2(20, 10)
	main_panel.add_child(title)
	print("Title label created")

	# Main content area (HBoxContainer for left/right split)
	var content_hbox = HBoxContainer.new()
	content_hbox.position = Vector2(20, 60)
	content_hbox.size = Vector2(760, 480)
	content_hbox.add_theme_constant_override("separation", 20)
	main_panel.add_child(content_hbox)

	# LEFT SIDE: Customer wants & Shopping bag
	var left_vbox = VBoxContainer.new()
	left_vbox.custom_minimum_size = Vector2(350, 480)
	left_vbox.add_theme_constant_override("separation", 10)
	content_hbox.add_child(left_vbox)

	# Customer wants list
	var customer_wants_label = Label.new()
	customer_wants_label.text = "Customer Wants:"
	customer_wants_label.add_theme_font_size_override("font_size", 20)
	left_vbox.add_child(customer_wants_label)

	customer_items_list = VBoxContainer.new()
	customer_items_list.custom_minimum_size = Vector2(350, 180)
	left_vbox.add_child(customer_items_list)

	# Shopping bag section
	var bag_label = Label.new()
	bag_label.text = "Shopping Bag:"
	bag_label.add_theme_font_size_override("font_size", 20)
	left_vbox.add_child(bag_label)

	shopping_bag_container = VBoxContainer.new()
	shopping_bag_container.custom_minimum_size = Vector2(350, 180)
	left_vbox.add_child(shopping_bag_container)

	# RIGHT SIDE: Transaction info & Actions
	var right_vbox = VBoxContainer.new()
	right_vbox.custom_minimum_size = Vector2(370, 480)
	right_vbox.add_theme_constant_override("separation", 15)
	content_hbox.add_child(right_vbox)

	# Transaction total
	transaction_total_label = Label.new()
	transaction_total_label.text = "Total: $0.00"
	transaction_total_label.add_theme_font_size_override("font_size", 28)
	transaction_total_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
	right_vbox.add_child(transaction_total_label)

	# Instructions label
	var instructions = Label.new()
	instructions.text = "1. Walk to Display Case and press [E]\n2. Select items customer wants\n3. Return and add items to bag\n4. Proceed to payment"
	instructions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instructions.custom_minimum_size.y = 100
	right_vbox.add_child(instructions)

	# Action buttons
	display_case_access_button = Button.new()
	display_case_access_button.text = "Access Display Case [E]"
	display_case_access_button.custom_minimum_size = Vector2(0, 50)
	display_case_access_button.disabled = true
	display_case_access_button.pressed.connect(_on_display_case_access_pressed)
	right_vbox.add_child(display_case_access_button)

	add_to_bag_button = Button.new()
	add_to_bag_button.text = "Add to Shopping Bag"
	add_to_bag_button.custom_minimum_size = Vector2(0, 50)
	add_to_bag_button.disabled = true
	add_to_bag_button.pressed.connect(_on_add_to_bag_pressed)
	right_vbox.add_child(add_to_bag_button)

	proceed_to_payment_button = Button.new()
	proceed_to_payment_button.text = "Proceed to Payment"
	proceed_to_payment_button.custom_minimum_size = Vector2(0, 60)
	proceed_to_payment_button.add_theme_font_size_override("font_size", 24)
	proceed_to_payment_button.disabled = true
	proceed_to_payment_button.pressed.connect(_on_proceed_to_payment_pressed)
	right_vbox.add_child(proceed_to_payment_button)

	# Cancel button at bottom
	var cancel_button = Button.new()
	cancel_button.text = "Cancel (ESC)"
	cancel_button.position = Vector2(20, 550)
	cancel_button.custom_minimum_size = Vector2(150, 40)
	cancel_button.pressed.connect(_on_cancel_pressed)
	main_panel.add_child(cancel_button)

	print("Checkout UI created")

func start_checkout(customer: Node3D) -> void:
	"""Begin checkout process with a customer"""
	print("=== start_checkout() called ===")
	print("Customer: ", customer)
	print("Main panel exists: ", main_panel != null)

	if not customer or not customer.has_method("get_selected_items"):
		push_error("Invalid customer for checkout")
		return

	current_customer = customer
	customer_desired_items = customer.get_selected_items()
	print("Customer wants ", customer_desired_items.size(), " items")

	bagged_items.clear()
	player_carry_inventory.clear()
	transaction_total = 0.0
	error_count = 0
	current_state = CheckoutState.GATHERING_ITEMS

	# Start timer
	transaction_start_time = Time.get_ticks_msec() / 1000.0

	# Populate customer wants list
	_update_customer_wants_display()
	_update_shopping_bag_display()
	_update_transaction_total()

	# Enable carry inventory
	InventoryManager.create_inventory("player_carry")

	# Show UI
	print("About to show checkout UI...")
	show()
	print("Checkout UI visible: ", visible)
	print("Checkout started with ", customer.customer_id)

func _update_customer_wants_display() -> void:
	"""Display what the customer wants to buy"""
	if not customer_items_list:
		push_error("customer_items_list is null! UI not created properly")
		return

	# Clear existing
	for child in customer_items_list.get_children():
		child.queue_free()

	# Add each desired item
	for item_data in customer_desired_items:
		var item_id: String = item_data["item_id"]
		var quantity: int = item_data["quantity"]

		# Get recipe info
		var recipe = RecipeManager.get_recipe(item_id) if RecipeManager else {}
		var item_name = recipe.get("name", item_id)
		var price = recipe.get("base_price", 0.0)

		# Check if already bagged
		var bagged_qty = bagged_items.get(item_id, 0)
		var status_text = ""
		if bagged_qty >= quantity:
			status_text = " ✓"
		elif bagged_qty > 0:
			status_text = " (%d/%d)" % [bagged_qty, quantity]

		var item_label = Label.new()
		item_label.text = "  %dx %s ($%.2f each)%s" % [quantity, item_name, price, status_text]
		item_label.add_theme_font_size_override("font_size", 16)
		customer_items_list.add_child(item_label)

func _update_shopping_bag_display() -> void:
	"""Display items currently in shopping bag"""
	if not shopping_bag_container:
		push_error("shopping_bag_container is null! UI not created properly")
		return

	# Clear existing
	for child in shopping_bag_container.get_children():
		child.queue_free()

	if bagged_items.is_empty():
		var empty_label = Label.new()
		empty_label.text = "  (empty)"
		empty_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		shopping_bag_container.add_child(empty_label)
	else:
		for item_id in bagged_items:
			var quantity = bagged_items[item_id]
			var recipe = RecipeManager.get_recipe(item_id) if RecipeManager else {}
			var item_name = recipe.get("name", item_id)

			var item_label = Label.new()
			item_label.text = "  %dx %s" % [quantity, item_name]
			item_label.add_theme_font_size_override("font_size", 16)
			item_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
			shopping_bag_container.add_child(item_label)

func _update_transaction_total() -> void:
	"""Update transaction total display"""
	if not transaction_total_label:
		push_error("transaction_total_label is null! UI not created properly")
		return

	transaction_total = 0.0

	for item_id in bagged_items:
		var quantity = bagged_items[item_id]
		var recipe = RecipeManager.get_recipe(item_id) if RecipeManager else {}
		var price = recipe.get("base_price", 0.0)

		# Check for quality-adjusted price
		var metadata = InventoryManager.get_item_metadata("display_case", item_id)
		if metadata.has("quality_data") and QualityManager:
			price = QualityManager.get_price_for_quality(price, metadata.quality_data)

		transaction_total += price * quantity

	transaction_total_label.text = "Total: $%.2f" % transaction_total

	# Enable payment button if all items bagged
	_check_if_ready_for_payment()

func _check_if_ready_for_payment() -> void:
	"""Check if all customer items are bagged"""
	var all_items_bagged = true

	for item_data in customer_desired_items:
		var item_id = item_data["item_id"]
		var needed_qty = item_data["quantity"]
		var bagged_qty = bagged_items.get(item_id, 0)

		if bagged_qty < needed_qty:
			all_items_bagged = false
			break

	proceed_to_payment_button.disabled = not all_items_bagged

func _on_display_case_access_pressed() -> void:
	"""Player wants to access display case (not implemented in this UI)"""
	# This would be handled by player walking to display case and pressing E
	# Just a visual reminder button
	print("Walk to display case and press [E] to access items")

func _on_add_to_bag_pressed() -> void:
	"""Add items from carry inventory to shopping bag"""
	var carry_inv = InventoryManager.get_inventory("player_carry")

	if carry_inv.is_empty():
		print("Carry inventory is empty - collect items from display case first")
		return

	# Transfer items from carry to bag
	for item_id in carry_inv:
		var quantity = carry_inv[item_id]

		# Add to bagged items
		if bagged_items.has(item_id):
			bagged_items[item_id] += quantity
		else:
			bagged_items[item_id] = quantity

		print("Added %dx %s to shopping bag" % [quantity, item_id])

	# Clear carry inventory
	InventoryManager.clear_inventory("player_carry")

	# Update displays
	_update_customer_wants_display()
	_update_shopping_bag_display()
	_update_transaction_total()

func _on_proceed_to_payment_pressed() -> void:
	"""Move to payment mini-game"""
	current_state = CheckoutState.PAYMENT

	# Hide main UI temporarily
	main_panel.visible = false

	# Randomly select payment method (70% cash, 30% card)
	var rand = randf()
	payment_method = PaymentMethod.CASH if rand < 0.7 else PaymentMethod.CARD

	# Show appropriate payment UI
	if payment_method == PaymentMethod.CASH:
		_show_cash_payment_ui()
	else:
		_show_card_payment_ui()

func _on_cancel_pressed() -> void:
	"""Cancel checkout"""
	_cleanup_checkout()
	checkout_cancelled.emit()
	hide()

func _cleanup_checkout() -> void:
	"""Clean up checkout state"""
	current_customer = null
	customer_desired_items.clear()
	bagged_items.clear()
	player_carry_inventory.clear()
	transaction_total = 0.0

	# Remove carry inventory
	if InventoryManager:
		InventoryManager.clear_inventory("player_carry")

	# Hide payment UI if visible
	if payment_panel:
		payment_panel.queue_free()
		payment_panel = null

	main_panel.visible = true

# ============================================================================
# PAYMENT MINI-GAMES
# ============================================================================

func _show_cash_payment_ui() -> void:
	"""Show cash payment mini-game"""
	# Create payment panel
	payment_panel = Panel.new()
	payment_panel.name = "CashPaymentPanel"
	payment_panel.custom_minimum_size = Vector2(600, 500)
	payment_panel.set_anchors_preset(Control.PRESET_CENTER)
	payment_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(payment_panel)

	# Title
	var title = Label.new()
	title.text = "CASH PAYMENT"
	title.add_theme_font_size_override("font_size", 32)
	title.position = Vector2(20, 10)
	payment_panel.add_child(title)

	# Amount due
	var amount_label = Label.new()
	amount_label.text = "Amount Due: $%.2f" % transaction_total
	amount_label.add_theme_font_size_override("font_size", 24)
	amount_label.position = Vector2(20, 60)
	payment_panel.add_child(amount_label)

	# Customer gives (randomize realistic amounts)
	amount_due = transaction_total
	amount_given = _calculate_realistic_payment(amount_due)

	var given_label = Label.new()
	given_label.text = "Customer Gives: $%.2f" % amount_given
	given_label.add_theme_font_size_override("font_size", 24)
	given_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
	given_label.position = Vector2(20, 100)
	payment_panel.add_child(given_label)

	# Change needed
	change_needed = amount_given - amount_due

	var change_label = Label.new()
	change_label.text = "Change Needed: $%.2f" % change_needed
	change_label.add_theme_font_size_override("font_size", 24)
	change_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3))
	change_label.position = Vector2(20, 140)
	payment_panel.add_child(change_label)

	# Player's change selection
	var player_change_label = Label.new()
	player_change_label.name = "PlayerChangeLabel"
	player_change_label.text = "Your Change: $0.00"
	player_change_label.add_theme_font_size_override("font_size", 20)
	player_change_label.position = Vector2(20, 190)
	payment_panel.add_child(player_change_label)

	# Bill/coin buttons
	var bills_label = Label.new()
	bills_label.text = "Select Bills and Coins:"
	bills_label.position = Vector2(20, 230)
	payment_panel.add_child(bills_label)

	# Create bill/coin buttons in a grid
	var denominations = [
		{"value": 10.0, "label": "$10"},
		{"value": 5.0, "label": "$5"},
		{"value": 1.0, "label": "$1"},
		{"value": 0.25, "label": "25¢"},
		{"value": 0.10, "label": "10¢"},
		{"value": 0.05, "label": "5¢"},
		{"value": 0.01, "label": "1¢"}
	]

	player_change_amount = 0.0
	var x_pos = 20
	var y_pos = 270

	for denom in denominations:
		var btn = Button.new()
		btn.text = denom.label
		btn.position = Vector2(x_pos, y_pos)
		btn.custom_minimum_size = Vector2(75, 50)
		btn.pressed.connect(_on_cash_denomination_pressed.bind(denom.value, player_change_label))
		payment_panel.add_child(btn)

		x_pos += 85
		if x_pos > 500:
			x_pos = 20
			y_pos += 60

	# Clear button
	var clear_btn = Button.new()
	clear_btn.text = "Clear"
	clear_btn.position = Vector2(20, 400)
	clear_btn.custom_minimum_size = Vector2(100, 40)
	clear_btn.pressed.connect(_on_clear_change_pressed.bind(player_change_label))
	payment_panel.add_child(clear_btn)

	# Confirm button
	var confirm_btn = Button.new()
	confirm_btn.text = "Confirm Change"
	confirm_btn.position = Vector2(140, 400)
	confirm_btn.custom_minimum_size = Vector2(200, 40)
	confirm_btn.pressed.connect(_on_confirm_change_pressed)
	payment_panel.add_child(confirm_btn)

func _calculate_realistic_payment(amount: float) -> float:
	"""Calculate a realistic payment amount (rounds up to next bill)"""
	if amount < 5.0:
		return 5.0
	elif amount < 10.0:
		return 10.0
	elif amount < 20.0:
		return 20.0
	elif amount < 50.0:
		# Round up to nearest $5
		return ceil(amount / 5.0) * 5.0
	else:
		# Round up to nearest $10
		return ceil(amount / 10.0) * 10.0

func _on_cash_denomination_pressed(value: float, label: Label) -> void:
	"""Add denomination to player's change selection"""
	player_change_amount += value
	label.text = "Your Change: $%.2f" % player_change_amount
	print("Added $%.2f (Total: $%.2f)" % [value, player_change_amount])

func _on_clear_change_pressed(label: Label) -> void:
	"""Clear player's change selection"""
	player_change_amount = 0.0
	label.text = "Your Change: $0.00"
	print("Cleared change selection")

func _on_confirm_change_pressed() -> void:
	"""Check if player's change is correct"""
	var tolerance = 0.01  # 1 cent tolerance for floating point

	if abs(player_change_amount - change_needed) < tolerance:
		print("✓ Correct change!")
		_complete_payment(true)
	else:
		print("✗ Incorrect change! Needed $%.2f, gave $%.2f" % [change_needed, player_change_amount])
		error_count += 1

		# Show error message
		var error_label = Label.new()
		error_label.text = "Incorrect! Try again."
		error_label.add_theme_color_override("font_color", Color.RED)
		error_label.position = Vector2(360, 410)
		payment_panel.add_child(error_label)

		# Let them try again
		player_change_amount = 0.0
		var player_change_label = payment_panel.get_node("PlayerChangeLabel")
		if player_change_label:
			player_change_label.text = "Your Change: $0.00"

func _show_card_payment_ui() -> void:
	"""Show card swipe mini-game"""
	# Create payment panel
	payment_panel = Panel.new()
	payment_panel.name = "CardPaymentPanel"
	payment_panel.custom_minimum_size = Vector2(600, 400)
	payment_panel.set_anchors_preset(Control.PRESET_CENTER)
	payment_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(payment_panel)

	# Title
	var title = Label.new()
	title.text = "CARD PAYMENT"
	title.add_theme_font_size_override("font_size", 32)
	title.position = Vector2(20, 10)
	payment_panel.add_child(title)

	# Amount
	var amount_label = Label.new()
	amount_label.text = "Amount: $%.2f" % transaction_total
	amount_label.add_theme_font_size_override("font_size", 24)
	amount_label.position = Vector2(20, 60)
	payment_panel.add_child(amount_label)

	# Instructions
	var instructions = Label.new()
	instructions.text = "Click and drag the card through the reader"
	instructions.position = Vector2(20, 110)
	instructions.add_theme_font_size_override("font_size", 18)
	payment_panel.add_child(instructions)

	# Card reader area (visual target)
	var reader_panel = Panel.new()
	reader_panel.name = "CardReader"
	reader_panel.position = Vector2(200, 160)
	reader_panel.size = Vector2(200, 100)
	var reader_style = _create_styled_panel(
		Color(0.1, 0.1, 0.15),  # bg_color
		Color(0.3, 0.3, 0.4),   # border_color
		3,                       # border_width
		0                        # corner_radius (rectangular reader)
	)
	reader_panel.add_theme_stylebox_override("panel", reader_style)
	payment_panel.add_child(reader_panel)

	var reader_label = Label.new()
	reader_label.text = "SWIPE HERE"
	reader_label.position = Vector2(50, 40)
	reader_panel.add_child(reader_label)

	# Card (draggable)
	var card = Button.new()
	card.name = "Card"
	card.text = "💳 CARD"
	card.position = Vector2(50, 160)
	card.size = Vector2(100, 60)
	card.flat = false
	payment_panel.add_child(card)

	# Set up drag and drop
	card.mouse_entered.connect(_on_card_mouse_entered.bind(card))
	card.gui_input.connect(_on_card_gui_input.bind(card, reader_panel))

func _on_card_mouse_entered(card: Button) -> void:
	card.modulate = Color(1.2, 1.2, 1.2)

func _on_card_gui_input(event: InputEvent, card: Button, reader: Panel) -> void:
	"""Handle card drag and drop"""
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				card_dragging = true
				card_drag_offset = event.position
				card.modulate = Color(1.5, 1.5, 0.8)
			else:
				card_dragging = false
				card.modulate = Color.WHITE

				# Check if card is over reader
				var card_rect = Rect2(card.global_position, card.size)
				var reader_rect = Rect2(reader.global_position, reader.size)

				if card_rect.intersects(reader_rect):
					print("✓ Card swiped successfully!")
					_process_card_swipe(reader)
				else:
					# Snap back
					card.position = Vector2(50, 160)

	elif event is InputEventMouseMotion and card_dragging:
		card.position += event.relative

func _process_card_swipe(reader: Panel) -> void:
	"""Animate card processing"""
	var processing_label = Label.new()
	processing_label.text = "Processing..."
	processing_label.position = Vector2(220, 170)
	processing_label.add_theme_font_size_override("font_size", 20)
	payment_panel.add_child(processing_label)

	# Wait 1 second
	await get_tree().create_timer(1.0).timeout

	processing_label.text = "✓ APPROVED!"
	processing_label.add_theme_color_override("font_color", Color.GREEN)

	# Wait another second
	await get_tree().create_timer(1.0).timeout

	_complete_payment(false)

func _complete_payment(is_cash: bool) -> void:
	"""Complete the payment and finish checkout"""
	# Calculate transaction time
	var transaction_time = (Time.get_ticks_msec() / 1000.0) - transaction_start_time
	var had_errors = error_count > 0

	print("Payment complete! Time: %.1fs, Errors: %d" % [transaction_time, error_count])

	# Remove items from display case
	for item_id in bagged_items:
		var quantity = bagged_items[item_id]
		InventoryManager.remove_item("display_case", item_id, quantity)

	# Add money to economy
	if EconomyManager:
		EconomyManager.add_money(transaction_total, "Sale")

	# Update customer
	if current_customer and current_customer.has_method("complete_purchase"):
		current_customer.complete_purchase(transaction_time, had_errors)

	# Emit completion signal
	checkout_completed.emit(transaction_time, had_errors)

	# Clean up and close
	_cleanup_checkout()
	hide()

	print("Checkout UI closed")
