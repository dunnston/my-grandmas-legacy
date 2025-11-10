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

# UI Components (get dynamically to support scene inheritance)
var panel: Panel = null
var equipment_container: VBoxContainer = null
var player_container: VBoxContainer = null
var equipment_label: Label = null
var player_label: Label = null
var close_button: Button = null

# Item button cache
var equipment_buttons: Array[Button] = []
var player_buttons: Array[Button] = []

func _ready() -> void:
	visible = false
	_get_ui_nodes()

	if close_button:
		close_button.pressed.connect(_on_close_pressed)

	print("EquipmentUIBase ready")

func _get_ui_nodes() -> void:
	"""Get UI node references - called in _ready to support scene inheritance"""
	panel = get_node_or_null("Panel")
	if panel:
		equipment_container = panel.get_node_or_null("HBoxContainer/EquipmentSide/ScrollContainer/ItemList")
		player_container = panel.get_node_or_null("HBoxContainer/PlayerSide/ScrollContainer/ItemList")
		equipment_label = panel.get_node_or_null("HBoxContainer/EquipmentSide/Label")
		player_label = panel.get_node_or_null("HBoxContainer/PlayerSide/Label")
		close_button = panel.get_node_or_null("CloseButton")

	if not equipment_container:
		push_error("EquipmentUIBase: Could not find equipment_container at Panel/HBoxContainer/EquipmentSide/ScrollContainer/ItemList")
	if not player_container:
		push_error("EquipmentUIBase: Could not find player_container at Panel/HBoxContainer/PlayerSide/ScrollContainer/ItemList")

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

	if not equipment_container:
		push_error("EquipmentUIBase: equipment_container is null! Scene structure may be incorrect.")
		return

	# Clear ALL children from container (including separators and other UI elements)
	for child in equipment_container.get_children():
		child.queue_free()

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

	if not player_container:
		push_error("EquipmentUIBase: player_container is null! Scene structure may be incorrect.")
		return

	# Clear ALL children from container (including any extra UI elements)
	for child in player_container.get_children():
		child.queue_free()

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
