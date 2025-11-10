extends CanvasLayer

# PackageUI - Shows contents of delivered package and allows item pickup

# Signals
signal ui_closed

# Node references
@onready var panel: Panel = $Panel
@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var contents_container: VBoxContainer = $Panel/VBoxContainer/ScrollContainer/ContentsContainer
@onready var close_button: Button = $Panel/VBoxContainer/ButtonsHBox/CloseButton
@onready var take_all_button: Button = $Panel/VBoxContainer/ButtonsHBox/TakeAllButton

func _ready() -> void:
	# Connect buttons
	if close_button:
		close_button.pressed.connect(_on_close_pressed)

	if take_all_button:
		take_all_button.pressed.connect(_on_take_all_pressed)

	# Pause game while UI is open
	GameManager.pause_game()

	# Populate contents
	_populate_contents()

	print("Package UI opened")

func _populate_contents() -> void:
	"""Display all items in the package"""
	if not contents_container:
		return

	# Clear existing children
	for child in contents_container.get_children():
		child.queue_free()

	# Get package contents
	var contents: Dictionary = DeliveryManager.get_package_contents()

	if contents.size() == 0:
		# Package is empty
		var empty_label: Label = Label.new()
		empty_label.text = "Package is empty!"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		contents_container.add_child(empty_label)

		# Disable take all button
		if take_all_button:
			take_all_button.disabled = true

		return

	# Add helpful description
	var desc_label: Label = Label.new()
	desc_label.text = "Items will be added to your inventory. You can then store ingredients or place equipment."
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	contents_container.add_child(desc_label)

	# Add spacer
	var spacer: Control = Control.new()
	spacer.custom_minimum_size.y = 10
	contents_container.add_child(spacer)

	# Add item rows
	for item_id in contents:
		var quantity: int = contents[item_id]
		_add_item_row(item_id, quantity)

func _add_item_row(item_id: String, quantity: int) -> void:
	"""Add a row for a package item"""
	var hbox: HBoxContainer = HBoxContainer.new()
	contents_container.add_child(hbox)

	# Item name
	var name_label: Label = Label.new()
	name_label.text = item_id.capitalize().replace("_", " ")
	name_label.custom_minimum_size.x = 300
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 16)
	hbox.add_child(name_label)

	# Quantity
	var quantity_label: Label = Label.new()
	quantity_label.text = "x%d" % quantity
	quantity_label.custom_minimum_size.x = 60
	quantity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hbox.add_child(quantity_label)

	# Take button
	var take_button: Button = Button.new()
	take_button.text = "Take to Inventory"
	take_button.custom_minimum_size.x = 150
	take_button.pressed.connect(_on_take_item.bind(item_id))
	hbox.add_child(take_button)

func _on_take_item(item_id: String) -> void:
	"""Take a single item from the package"""
	var contents: Dictionary = DeliveryManager.get_package_contents()
	var quantity: int = contents.get(item_id, 0)

	if quantity > 0:
		# Take the item
		DeliveryManager.take_item_from_package(item_id, quantity)

		# Refresh display
		_populate_contents()

		# Check if package is now empty
		if DeliveryManager.get_package_contents().size() == 0:
			print("All items taken from package!")
			_close_ui()

func _on_take_all_pressed() -> void:
	"""Take all items from package at once"""
	DeliveryManager.take_all_from_package()

	print("All items moved to player inventory!")
	_close_ui()

func _on_close_pressed() -> void:
	"""Close the UI"""
	_close_ui()

func _close_ui() -> void:
	"""Close the package UI"""
	# Resume game
	GameManager.resume_game()

	# Emit signal
	ui_closed.emit()

	# Remove from tree
	queue_free()

	print("Package UI closed")
