class_name CustomerWantsUI
extends Control

# CustomerWantsUI - Simple popup showing what customer wants
# Non-modal, can be closed with ESC or clicking outside

signal ui_closed()

# UI elements
var panel: Panel = null
var items_list: VBoxContainer = null
var close_button: Button = null

# Data
var customer_items: Array[Dictionary] = []

func _ready() -> void:
	print("CustomerWantsUI: _ready() called")

	# Make this Control fill the viewport so anchors work
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0

	# Ensure it's on top of other UI elements
	z_index = 100

	_create_ui()
	hide()
	print("CustomerWantsUI: Ready and hidden")

func _create_ui() -> void:
	"""Create simple popup UI"""
	print("CustomerWantsUI: _create_ui() starting...")

	# Semi-transparent background that closes on click
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0, 0, 0, 0.5)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.gui_input.connect(_on_background_clicked)
	add_child(bg)
	print("  Background created")

	# Panel (top-right corner)
	panel = Panel.new()
	panel.name = "Panel"
	panel.custom_minimum_size = Vector2(300, 400)
	panel.anchor_left = 1.0
	panel.anchor_top = 0.0
	panel.anchor_right = 1.0
	panel.anchor_bottom = 0.0
	panel.offset_left = -320  # 300 width + 20 margin
	panel.offset_top = 20
	panel.offset_right = -20
	panel.offset_bottom = 420

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.25, 0.95)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.4, 0.4, 0.5)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	# Title
	var title = Label.new()
	title.text = "Customer Order"
	title.add_theme_font_size_override("font_size", 24)
	title.position = Vector2(20, 10)
	panel.add_child(title)

	# Instructions
	var instructions = Label.new()
	instructions.text = "Collect these items from the display case:"
	instructions.position = Vector2(20, 50)
	instructions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instructions.custom_minimum_size = Vector2(260, 40)
	panel.add_child(instructions)

	# Items list
	items_list = VBoxContainer.new()
	items_list.position = Vector2(20, 100)
	items_list.size = Vector2(260, 240)
	panel.add_child(items_list)
	print("  Items list created: ", items_list)

	# Close button
	close_button = Button.new()
	close_button.text = "OK (ESC)"
	close_button.position = Vector2(20, 350)
	close_button.custom_minimum_size = Vector2(260, 40)
	close_button.pressed.connect(_on_close_pressed)
	panel.add_child(close_button)
	print("  Close button created")
	print("CustomerWantsUI: _create_ui() complete!")

func show_customer_wants(items: Array[Dictionary]) -> void:
	"""Display customer's desired items"""
	print("CustomerWantsUI: show_customer_wants() called with %d items" % items.size())

	if not items_list:
		push_error("items_list is null! UI not created properly")
		# Try to recreate UI
		_create_ui()
		if not items_list:
			push_error("Failed to create UI even after _create_ui()!")
			return

	customer_items = items
	print("  Clearing existing items from list...")

	# Clear existing items
	for child in items_list.get_children():
		child.queue_free()

	print("  Adding %d items to UI..." % customer_items.size())

	# Add each item
	for item_data in customer_items:
		var item_id: String = item_data["item_id"]
		var quantity: int = item_data["quantity"]

		# Get recipe info
		var recipe = RecipeManager.get_recipe(item_id) if RecipeManager else {}
		var item_name = recipe.get("name", item_id)

		var item_label = Label.new()
		item_label.text = "  • %dx %s" % [quantity, item_name]
		item_label.add_theme_font_size_override("font_size", 18)
		items_list.add_child(item_label)
		print("    Added: %dx %s" % [quantity, item_name])

	print("  Making UI visible...")
	show()
	print("  ✓ CustomerWantsUI is now visible: ", visible)

func _on_close_pressed() -> void:
	"""Close button clicked"""
	hide()
	ui_closed.emit()

func _on_background_clicked(event: InputEvent) -> void:
	"""Background clicked - close UI"""
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_close_pressed()

func _input(event: InputEvent) -> void:
	"""Handle ESC to close"""
	if visible and event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
