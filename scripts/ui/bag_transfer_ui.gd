class_name BagTransferUI
extends Control

# BagTransferUI - Transfer items from holding inventory to shopping bag
# Left side: Bag inventory
# Right side: Holding inventory

signal transfer_completed()

# UI elements
var main_panel: Panel = null
var bag_container: VBoxContainer = null
var holding_container: VBoxContainer = null

# Inventories
var bag_inventory_id: String = ""
var holding_inventory_id: String = ""

# Button tracking
var bag_buttons: Array[Button] = []
var holding_buttons: Array[Button] = []

func _ready() -> void:
	print("BagTransferUI: _ready() called")

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
	print("BagTransferUI: Ready and hidden")

func _create_ui() -> void:
	"""Create the transfer UI"""
	# Main panel (centered)
	main_panel = Panel.new()
	main_panel.custom_minimum_size = Vector2(700, 500)
	main_panel.anchor_left = 0.5
	main_panel.anchor_top = 0.5
	main_panel.anchor_right = 0.5
	main_panel.anchor_bottom = 0.5
	main_panel.offset_left = -350
	main_panel.offset_top = -250
	main_panel.offset_right = 350
	main_panel.offset_bottom = 250

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
	main_panel.add_theme_stylebox_override("panel", style)
	add_child(main_panel)

	# Title
	var title = Label.new()
	title.text = "BAG ITEMS"
	title.add_theme_font_size_override("font_size", 28)
	title.position = Vector2(20, 10)
	main_panel.add_child(title)

	# Instructions
	var instructions = Label.new()
	instructions.text = "Click items in your hands to add them to the bag"
	instructions.position = Vector2(20, 50)
	main_panel.add_child(instructions)

	# Content area
	var content_hbox = HBoxContainer.new()
	content_hbox.position = Vector2(20, 90)
	content_hbox.size = Vector2(660, 350)
	content_hbox.add_theme_constant_override("separation", 20)
	main_panel.add_child(content_hbox)

	# Left side: Bag
	var left_vbox = VBoxContainer.new()
	left_vbox.custom_minimum_size = Vector2(320, 350)
	content_hbox.add_child(left_vbox)

	var bag_label = Label.new()
	bag_label.text = "Shopping Bag"
	bag_label.add_theme_font_size_override("font_size", 20)
	left_vbox.add_child(bag_label)

	bag_container = VBoxContainer.new()
	bag_container.custom_minimum_size = Vector2(320, 300)
	left_vbox.add_child(bag_container)

	# Right side: Holding inventory
	var right_vbox = VBoxContainer.new()
	right_vbox.custom_minimum_size = Vector2(320, 350)
	content_hbox.add_child(right_vbox)

	var holding_label = Label.new()
	holding_label.text = "In Your Hands"
	holding_label.add_theme_font_size_override("font_size", 20)
	right_vbox.add_child(holding_label)

	holding_container = VBoxContainer.new()
	holding_container.custom_minimum_size = Vector2(320, 300)
	right_vbox.add_child(holding_container)

	# Close button
	var close_button = Button.new()
	close_button.text = "Done (ESC)"
	close_button.position = Vector2(20, 450)
	close_button.custom_minimum_size = Vector2(660, 40)
	close_button.pressed.connect(_on_close_pressed)
	main_panel.add_child(close_button)

func show_transfer(from_inventory: String, to_inventory: String) -> void:
	"""Show transfer UI"""
	print("BagTransferUI: show_transfer() called")
	print("  From: ", from_inventory, " To: ", to_inventory)

	holding_inventory_id = from_inventory
	bag_inventory_id = to_inventory

	print("  Refreshing displays...")
	_refresh_displays()

	print("  Making UI visible...")
	show()

	# Release mouse so player can click buttons
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	print("  ✓ BagTransferUI visible: ", visible)
	print("  ✓ Mouse released for UI interaction")

func _refresh_displays() -> void:
	"""Refresh both inventory displays"""
	_refresh_bag()
	_refresh_holding()

func _refresh_bag() -> void:
	"""Refresh bag inventory display"""
	# Clear ALL children from container
	for child in bag_container.get_children():
		bag_container.remove_child(child)
		child.queue_free()
	bag_buttons.clear()

	# Get inventory
	var inventory = InventoryManager.get_inventory(bag_inventory_id)

	if inventory.is_empty():
		var empty_label = Label.new()
		empty_label.text = "  (empty)"
		empty_label.modulate = Color(0.6, 0.6, 0.6)
		bag_container.add_child(empty_label)
	else:
		for item_id in inventory:
			var quantity = inventory[item_id]
			var recipe = RecipeManager.get_recipe(item_id) if RecipeManager else {}
			var item_name = recipe.get("name", item_id)

			var item_label = Label.new()
			item_label.text = "  %dx %s" % [quantity, item_name]
			item_label.add_theme_font_size_override("font_size", 16)
			bag_container.add_child(item_label)

func _refresh_holding() -> void:
	"""Refresh holding inventory display"""
	# Clear ALL children from container
	for child in holding_container.get_children():
		holding_container.remove_child(child)
		child.queue_free()
	holding_buttons.clear()

	# Get inventory
	var inventory = InventoryManager.get_inventory(holding_inventory_id)

	if inventory.is_empty():
		var empty_label = Label.new()
		empty_label.text = "  (empty)"
		empty_label.modulate = Color(0.6, 0.6, 0.6)
		holding_container.add_child(empty_label)
	else:
		for item_id in inventory:
			var quantity = inventory[item_id]
			var recipe = RecipeManager.get_recipe(item_id) if RecipeManager else {}
			var item_name = recipe.get("name", item_id)

			var button = Button.new()
			button.text = "%dx %s →" % [quantity, item_name]
			button.custom_minimum_size = Vector2(300, 40)
			button.pressed.connect(_on_item_clicked.bind(item_id))
			holding_container.add_child(button)
			holding_buttons.append(button)

func _on_item_clicked(item_id: String) -> void:
	"""Transfer item from holding to bag"""
	if InventoryManager.transfer_item(holding_inventory_id, bag_inventory_id, item_id, 1):
		print("Moved 1x %s to bag" % item_id)
		_refresh_displays()
	else:
		print("Failed to transfer %s" % item_id)

func _on_close_pressed() -> void:
	"""Close the transfer UI"""
	hide()

	# Re-capture mouse for camera control
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	print("BagTransferUI: Closed, mouse re-captured for camera")

	transfer_completed.emit()

func _input(event: InputEvent) -> void:
	"""Handle ESC to close"""
	if visible and event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
