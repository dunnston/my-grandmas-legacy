extends Control

# Recipe Book Panel - Shows all recipes (unlocked and locked) on R key press
# Displays recipe details, ingredients, grandmother's notes

# Node references
@onready var panel: Panel = $Panel
@onready var title_label: Label = $Panel/MarginContainer/VBox/TitleLabel
@onready var recipe_list: VBoxContainer = $Panel/MarginContainer/VBox/HSplit/RecipeList/ScrollContainer/VBox
@onready var recipe_details: VBoxContainer = $Panel/MarginContainer/VBox/HSplit/RecipeDetails
@onready var close_button: Button = $Panel/MarginContainer/VBox/CloseButton

# Recipe detail labels
@onready var detail_name: Label = $Panel/MarginContainer/VBox/HSplit/RecipeDetails/DetailName
@onready var detail_tier: Label = $Panel/MarginContainer/VBox/HSplit/RecipeDetails/DetailTier
@onready var detail_price: Label = $Panel/MarginContainer/VBox/HSplit/RecipeDetails/DetailPrice
@onready var detail_time: Label = $Panel/MarginContainer/VBox/HSplit/RecipeDetails/DetailTime
@onready var detail_ingredients: RichTextLabel = $Panel/MarginContainer/VBox/HSplit/RecipeDetails/ScrollContainer/IngredientsList
@onready var detail_notes: RichTextLabel = $Panel/MarginContainer/VBox/HSplit/RecipeDetails/ScrollContainer2/GrandmasNotes

# State
var is_visible: bool = false
var selected_recipe_id: String = ""

func _ready() -> void:
	print("RecipeBook ready")

	# Start hidden
	hide()

	# Connect to UIManager signals
	if UIManager:
		UIManager.recipe_book_toggled.connect(_on_ui_manager_toggle)

	# Connect close button
	if close_button:
		close_button.pressed.connect(_on_close_pressed)

	# Listen for progression changes (new recipes unlocked)
	if ProgressionManager:
		ProgressionManager.milestone_reached.connect(_on_milestone_reached)

func _on_ui_manager_toggle(is_open: bool) -> void:
	"""Called when UIManager toggles recipe book"""
	is_visible = is_open
	if is_open:
		show_recipe_book()
	else:
		hide_recipe_book()

func _unhandled_input(event: InputEvent) -> void:
	# Allow ESC to close if visible
	if visible and event.is_action_pressed("ui_cancel"):
		# Update UIManager state when closing via ESC
		if UIManager:
			UIManager.recipe_book_open = false
		hide_recipe_book()
		get_viewport().set_input_as_handled()
		return

func toggle_recipe_book() -> void:
	"""Toggle recipe book visibility"""
	is_visible = !is_visible

	if is_visible:
		show_recipe_book()
	else:
		hide_recipe_book()

func show_recipe_book() -> void:
	"""Show recipe book panel and refresh contents"""
	print("RecipeBook: Showing")
	z_index = 100  # Ensure it appears on top
	show()
	refresh_recipe_list()

	# Release mouse for UI interaction
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func hide_recipe_book() -> void:
	"""Hide recipe book panel"""
	print("RecipeBook: Hiding")
	hide()

	# Re-capture mouse for gameplay
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func refresh_recipe_list() -> void:
	"""Refresh recipe list with all recipes"""
	if not recipe_list:
		return

	# Clear existing recipes
	for child in recipe_list.get_children():
		child.queue_free()

	# Get all recipes
	var all_recipes: Dictionary = RecipeManager.get_all_recipes()
	var unlocked_recipes: Array = ProgressionManager.get_unlocked_recipes()

	# Sort by tier then name
	var sorted_recipe_ids: Array = all_recipes.keys()
	sorted_recipe_ids.sort_custom(_sort_recipes)

	# Add each recipe to list
	for recipe_id in sorted_recipe_ids:
		var recipe: Dictionary = all_recipes[recipe_id]
		var is_unlocked: bool = recipe_id in unlocked_recipes

		_add_recipe_button(recipe_id, recipe, is_unlocked)

	# Select first recipe if nothing selected
	if selected_recipe_id == "" and not sorted_recipe_ids.is_empty():
		_select_recipe(sorted_recipe_ids[0])

func _add_recipe_button(recipe_id: String, recipe: Dictionary, is_unlocked: bool) -> void:
	"""Add a recipe button to the list"""
	var button := Button.new()

	# Format button text
	var recipe_name: String = recipe.get("name", recipe_id.capitalize())
	var tier_name: String = recipe.get("unlock_tier", "Starter")

	if is_unlocked:
		button.text = recipe_name
	else:
		button.text = "🔒 " + recipe_name
		button.disabled = false  # Allow viewing locked recipes
		button.modulate = Color(0.6, 0.6, 0.6)

	# Connect button
	button.pressed.connect(func(): _select_recipe(recipe_id))

	# Add to list
	recipe_list.add_child(button)

func _select_recipe(recipe_id: String) -> void:
	"""Select and display recipe details"""
	selected_recipe_id = recipe_id

	var all_recipes: Dictionary = RecipeManager.get_all_recipes()
	if not all_recipes.has(recipe_id):
		return

	var recipe: Dictionary = all_recipes[recipe_id]
	var is_unlocked: bool = recipe_id in ProgressionManager.get_unlocked_recipes()

	# Update detail labels
	if detail_name:
		detail_name.text = recipe.get("name", recipe_id.capitalize())

	if detail_tier:
		var tier: String = recipe.get("unlock_tier", "Starter")
		detail_tier.text = "Unlock Tier: " + tier

	if detail_price:
		var sell_price: float = recipe.get("sell_price", 0.0)
		detail_price.text = "Sell Price: $%.2f" % sell_price

	if detail_time:
		var prep_time: float = recipe.get("prep_time_seconds", 0)
		var bake_time: float = recipe.get("bake_time_seconds", 0)
		detail_time.text = "Time: %.0fs prep + %.0fs bake" % [prep_time, bake_time]

	# Update ingredients list
	if detail_ingredients:
		if is_unlocked:
			detail_ingredients.text = _format_ingredients(recipe.get("ingredients", {}))
		else:
			detail_ingredients.text = "[color=gray]🔒 Unlock to see ingredients[/color]"

	# Update grandmother's notes
	if detail_notes:
		if is_unlocked:
			var notes: String = recipe.get("grandmas_notes", "No notes available.")
			detail_notes.text = "[i]" + notes + "[/i]"
		else:
			detail_notes.text = "[color=gray]🔒 Unlock to read Grandma's notes[/color]"

func _format_ingredients(ingredients: Dictionary) -> String:
	"""Format ingredients dictionary as rich text"""
	if ingredients.is_empty():
		return "[color=gray]No ingredients needed[/color]"

	var text := "[b]Ingredients:[/b]\n"
	for ingredient_id in ingredients.keys():
		var quantity: int = ingredients[ingredient_id]
		var ingredient_name: String = ingredient_id.replace("_", " ").capitalize()

		# Get actual ingredient name if available
		var all_ingredients: Dictionary = RecipeManager.get_all_ingredients()
		if all_ingredients.has(ingredient_id):
			ingredient_name = all_ingredients[ingredient_id].get("name", ingredient_name)

		text += "• %s x%d\n" % [ingredient_name, quantity]

	return text

func _sort_recipes(a: String, b: String) -> bool:
	"""Sort recipes by tier then name"""
	var all_recipes: Dictionary = RecipeManager.get_all_recipes()
	var recipe_a: Dictionary = all_recipes.get(a, {})
	var recipe_b: Dictionary = all_recipes.get(b, {})

	# Define tier order
	var tier_order := {
		"Starter": 0,
		"Basic Pastries": 1,
		"Artisan Breads": 2,
		"Special Occasion Cakes": 3,
		"Grandma's Secret Recipes": 4,
		"International Treats": 5,
		"Legendary Bakes": 6
	}

	var tier_a: int = tier_order.get(recipe_a.get("unlock_tier", "Starter"), 999)
	var tier_b: int = tier_order.get(recipe_b.get("unlock_tier", "Starter"), 999)

	if tier_a != tier_b:
		return tier_a < tier_b

	# Same tier, sort alphabetically
	return recipe_a.get("name", a) < recipe_b.get("name", b)

func _on_close_pressed() -> void:
	"""Close button pressed"""
	hide_recipe_book()

func _on_milestone_reached(_milestone_id: String, _threshold: float) -> void:
	"""Called when a new milestone is reached - refresh if visible"""
	if is_visible:
		refresh_recipe_list()
