extends Control

# Quick Inventory Panel - Shows player inventory on Tab key press
# Displays all items currently in player's inventory with quantities

# Node references
@onready var panel: Panel = $Panel
@onready var title_label: Label = $Panel/MarginContainer/VBox/TitleLabel
@onready var inventory_grid: GridContainer = $Panel/MarginContainer/VBox/ScrollContainer/InventoryGrid
@onready var close_button: Button = $Panel/MarginContainer/VBox/CloseButton

# State
var is_visible: bool = false

func _ready() -> void:
	print("QuickInventory ready")

	# Start hidden
	hide()

	# Connect to UIManager signals
	if UIManager:
		UIManager.quick_inventory_toggled.connect(_on_ui_manager_toggle)

	# Connect close button
	if close_button:
		close_button.pressed.connect(_on_close_pressed)

	# Listen for inventory changes
	if InventoryManager:
		InventoryManager.inventory_changed.connect(_on_inventory_changed)

func _on_ui_manager_toggle(is_open: bool) -> void:
	"""Called when UIManager toggles quick inventory"""
	is_visible = is_open
	if is_open:
		show_inventory()
	else:
		hide_inventory()

func _unhandled_input(event: InputEvent) -> void:
	# Allow ESC to close if visible
	if visible and event.is_action_pressed("ui_cancel"):
		# Update UIManager state when closing via ESC
		if UIManager:
			UIManager.quick_inventory_open = false
		hide_inventory()
		get_viewport().set_input_as_handled()
		return

func toggle_inventory() -> void:
	"""Toggle inventory visibility"""
	is_visible = !is_visible

	if is_visible:
		show_inventory()
	else:
		hide_inventory()

func show_inventory() -> void:
	"""Show inventory panel and refresh contents"""
	print("QuickInventory: Showing")
	z_index = 100  # Ensure it appears on top
	show()
	refresh_inventory()

	# Release mouse for UI interaction
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# Pause game time when inventory is open (optional)
	# GameManager.pause_time()

func hide_inventory() -> void:
	"""Hide inventory panel"""
	print("QuickInventory: Hiding")
	hide()

	# Re-capture mouse for gameplay
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# Resume game time (optional)
	# GameManager.resume_time()

func refresh_inventory() -> void:
	"""Refresh inventory display with current items"""
	if not inventory_grid:
		return

	# Clear existing items
	for child in inventory_grid.get_children():
		child.queue_free()

	# Get current inventory
	var inventory: Dictionary = InventoryManager.get_inventory("player")

	if inventory.is_empty():
		# Show "empty" message
		var empty_label := Label.new()
		empty_label.text = "Inventory is empty"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		inventory_grid.add_child(empty_label)
		return

	# Add each item to grid
	for item_id in inventory.keys():
		var quantity: int = inventory[item_id]
		_add_inventory_item(item_id, quantity)

func _add_inventory_item(item_id: String, quantity: int) -> void:
	"""Add an inventory item to the grid"""
	var item_container := VBoxContainer.new()
	item_container.custom_minimum_size = Vector2(100, 80)

	# Item name label
	var name_label := Label.new()
	name_label.text = _get_item_display_name(item_id)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item_container.add_child(name_label)

	# Quantity label
	var qty_label := Label.new()
	qty_label.text = "x%d" % quantity
	qty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	qty_label.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7))
	item_container.add_child(qty_label)

	# Add separator
	var separator := HSeparator.new()
	item_container.add_child(separator)

	inventory_grid.add_child(item_container)

func _get_item_display_name(item_id: String) -> String:
	"""Convert item_id to display name"""
	# Check if it's an ingredient
	var ingredients: Dictionary = RecipeManager.get_all_ingredients()
	if ingredients.has(item_id):
		return ingredients[item_id].get("name", item_id.capitalize())

	# Check if it's a recipe/baked good
	var recipes: Dictionary = RecipeManager.get_all_recipes()
	if recipes.has(item_id):
		return recipes[item_id].get("name", item_id.capitalize())

	# Fallback: capitalize the ID
	return item_id.replace("_", " ").capitalize()

func _on_close_pressed() -> void:
	"""Close button pressed"""
	hide_inventory()

func _on_inventory_changed(inventory_id: String) -> void:
	"""Called when inventory changes - refresh if visible"""
	# Only refresh if the player inventory changed
	if inventory_id == "player" and is_visible:
		refresh_inventory()
