extends Control

# PricingPanel - UI for setting custom prices for recipes
# GDD Section 4.2.4, Lines 278-286
# Allows players to strategically set prices, customers check tolerance

signal price_changed(recipe_id: String, new_price: float)

# UI Components (to be set in scene or connected in _ready)
@onready var recipe_list: VBoxContainer = $Panel/ScrollContainer/RecipeList
@onready var close_button: Button = $Panel/CloseButton if has_node("Panel/CloseButton") else null

# Recipe row scene (created dynamically)
var recipe_row_template: PackedScene = null

func _ready() -> void:
	# Hide by default
	visible = false

	# Connect close button
	if close_button:
		close_button.pressed.connect(_on_close_pressed)

	print("PricingPanel ready")

func open_panel() -> void:
	"""Open the pricing panel and refresh recipe list"""
	visible = true
	_refresh_recipe_list()
	print("Pricing panel opened")

func close_panel() -> void:
	"""Close the pricing panel"""
	visible = false
	print("Pricing panel closed")

func _on_close_pressed() -> void:
	close_panel()

func _refresh_recipe_list() -> void:
	"""Refresh the list of recipes with current prices"""
	if not recipe_list:
		return

	# Clear existing rows
	for child in recipe_list.get_children():
		child.queue_free()

	# Get all unlocked recipes
	var unlocked_recipes = RecipeManager.get_all_unlocked_recipes()

	for recipe in unlocked_recipes:
		_add_recipe_row(recipe)

func _add_recipe_row(recipe: Dictionary) -> void:
	"""Add a row for one recipe"""
	var row = HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 40)

	# Recipe name label
	var name_label = Label.new()
	name_label.text = recipe.name
	name_label.custom_minimum_size = Vector2(200, 0)
	row.add_child(name_label)

	# Base price label
	var base_price = recipe.get("base_price", 0.0)
	var base_label = Label.new()
	base_label.text = "Base: $%.2f" % base_price
	base_label.custom_minimum_size = Vector2(100, 0)
	row.add_child(base_label)

	# Cost label (ingredient cost)
	var cost = RecipeManager.get_recipe_cost(recipe.id)
	var cost_label = Label.new()
	cost_label.text = "Cost: $%.2f" % cost
	cost_label.custom_minimum_size = Vector2(100, 0)
	cost_label.modulate = Color(0.8, 0.8, 0.8)
	row.add_child(cost_label)

	# Current price input (SpinBox)
	var price_input = SpinBox.new()
	price_input.custom_minimum_size = Vector2(120, 0)
	price_input.min_value = cost * 0.5  # Can't go below 50% of cost (prevents losses)
	price_input.max_value = base_price * 3.0  # Can't go above 3x base price
	price_input.step = 0.5
	price_input.suffix = "$"
	price_input.allow_greater = false
	price_input.allow_lesser = false

	# Set current value (player price or base price)
	var current_price = RecipeManager.get_effective_price(recipe.id)
	price_input.value = current_price

	price_input.value_changed.connect(_on_price_changed.bind(recipe.id))
	row.add_child(price_input)

	# Profit indicator
	var profit = current_price - cost
	var profit_label = Label.new()
	profit_label.text = "Profit: $%.2f" % profit
	profit_label.custom_minimum_size = Vector2(100, 0)

	if profit > 0:
		profit_label.modulate = Color(0.2, 0.8, 0.2)  # Green
	else:
		profit_label.modulate = Color(0.8, 0.2, 0.2)  # Red

	row.add_child(profit_label)

	# Reset button
	var reset_button = Button.new()
	reset_button.text = "Reset"
	reset_button.custom_minimum_size = Vector2(60, 0)
	reset_button.pressed.connect(_on_reset_price.bind(recipe.id))
	row.add_child(reset_button)

	recipe_list.add_child(row)

func _on_price_changed(new_price: float, recipe_id: String) -> void:
	"""Called when player changes a recipe price"""
	RecipeManager.set_player_price(recipe_id, new_price)
	price_changed.emit(recipe_id, new_price)

	# Refresh to update profit display
	_refresh_recipe_list()

func _on_reset_price(recipe_id: String) -> void:
	"""Reset a recipe to its base price"""
	RecipeManager.clear_player_price(recipe_id)
	_refresh_recipe_list()

# Keyboard shortcut support
func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_P:
			close_panel()
			accept_event()
