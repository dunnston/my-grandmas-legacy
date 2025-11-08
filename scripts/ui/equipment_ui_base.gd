extends Control
class_name EquipmentUIBase

# Base class for all equipment UI windows
# Displays equipment inventory on left, player inventory on right
# Children override interaction behavior

signal item_transferred(from_inventory: String, to_inventory: String, item_id: String)
signal ui_closed()

# References (to be set by children or in _ready)
var equipment_inventory_id: String = ""
var player_inventory_id: String = ""

# UI Components
@onready var panel: Panel = $Panel
@onready var equipment_container: VBoxContainer = $Panel/HBoxContainer/EquipmentSide/ItemList
@onready var player_container: VBoxContainer = $Panel/HBoxContainer/PlayerSide/ItemList
@onready var equipment_label: Label = $Panel/HBoxContainer/EquipmentSide/Label
@onready var player_label: Label = $Panel/HBoxContainer/PlayerSide/Label
@onready var close_button: Button = $Panel/CloseButton

# Item button cache
var equipment_buttons: Array[Button] = []
var player_buttons: Array[Button] = []

func _ready() -> void:
	visible = false

	if close_button:
		close_button.pressed.connect(_on_close_pressed)

	print("EquipmentUIBase ready")

func open_ui(equipment_inv_id: String, player_inv_id: String) -> void:
	"""Open the equipment UI with specified inventories"""
	equipment_inventory_id = equipment_inv_id
	player_inventory_id = player_inv_id

	visible = true
	_refresh_inventories()

	# Capture mouse
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func close_ui() -> void:
	"""Close the equipment UI"""
	visible = false
	ui_closed.emit()

func _on_close_pressed() -> void:
	close_ui()

func _refresh_inventories() -> void:
	"""Refresh both inventory displays"""
	_refresh_equipment_inventory()
	_refresh_player_inventory()

func _refresh_equipment_inventory() -> void:
	"""Refresh equipment inventory display - override in children"""
	# Clear existing buttons
	for button in equipment_buttons:
		button.queue_free()
	equipment_buttons.clear()

	# Get inventory
	var inventory = InventoryManager.get_inventory(equipment_inventory_id)

	# Create button for each item
	for item_id in inventory:
		var quantity = inventory[item_id]
		if quantity > 0:
			var button = _create_item_button(item_id, quantity)
			button.pressed.connect(_on_equipment_item_clicked.bind(item_id))
			equipment_container.add_child(button)
			equipment_buttons.append(button)

func _refresh_player_inventory() -> void:
	"""Refresh player inventory display"""
	# Clear existing buttons
	for button in player_buttons:
		button.queue_free()
	player_buttons.clear()

	# Get inventory
	var inventory = InventoryManager.get_inventory(player_inventory_id)

	# Create button for each item
	for item_id in inventory:
		var quantity = inventory[item_id]
		if quantity > 0:
			var button = _create_item_button(item_id, quantity)
			button.pressed.connect(_on_player_item_clicked.bind(item_id))
			player_container.add_child(button)
			player_buttons.append(button)

func _create_item_button(item_id: String, quantity: int) -> Button:
	"""Create a button for an inventory item"""
	var button = Button.new()
	button.text = "%s x%d" % [_get_item_display_name(item_id), quantity]
	button.custom_minimum_size = Vector2(200, 40)
	return button

func _get_item_display_name(item_id: String) -> String:
	"""Get display name for an item"""
	# Try to get recipe name
	if RecipeManager:
		var recipe = RecipeManager.get_recipe(item_id)
		if not recipe.is_empty():
			return recipe.get("name", item_id.capitalize())

	# Fallback to capitalized ID
	return item_id.replace("_", " ").capitalize()

# Virtual methods - override in children
func _on_equipment_item_clicked(item_id: String) -> void:
	"""Called when equipment item is clicked - override in children"""
	pass

func _on_player_item_clicked(item_id: String) -> void:
	"""Called when player item is clicked - override in children"""
	pass

# Keyboard handling
func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_E:
			close_ui()
			accept_event()
