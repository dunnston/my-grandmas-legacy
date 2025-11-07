extends Node

# RecipeManager - Singleton for managing recipes and crafting data
# Stores all recipe information, ingredients, times, and prices

# Signals
signal recipe_unlocked(recipe_id: String)

# Recipe data structure
# Each recipe contains:
# - id: unique identifier
# - name: display name
# - ingredients: Dictionary of ingredient_id -> quantity needed
# - mixing_time: seconds to mix
# - baking_time: seconds to bake
# - base_price: selling price
# - unlocked: whether player has access to it
# - category: recipe category (bread, pastry, cake, etc.)

var recipes: Dictionary = {}
var unlocked_recipes: Array[String] = []

func _ready() -> void:
	print("RecipeManager initialized")
	_initialize_starter_recipes()

func _initialize_starter_recipes() -> void:
	"""Initialize the 3 starter recipes from GDD"""

	# White Bread (simple and quick)
	register_recipe({
		"id": "white_bread",
		"name": "White Bread",
		"category": "bread",
		"ingredients": {
			"flour": 2,
			"water": 1,
			"yeast": 1,
			"salt": 1
		},
		"mixing_time": 60.0,  # 60 seconds to mix
		"baking_time": 300.0,  # 5 minutes to bake (game time)
		"base_price": 15.0,
		"quality_price_multiplier": 1.0,  # Can be adjusted based on quality
		"description": "Classic white bread. Simple and reliable.",
		"grandma_note": "The foundation of any good bakery, dear. Don't rush the rise!"
	})

	# Chocolate Chip Cookies (fast seller)
	register_recipe({
		"id": "chocolate_chip_cookies",
		"name": "Chocolate Chip Cookies",
		"category": "cookie",
		"ingredients": {
			"flour": 1,
			"sugar": 1,
			"butter": 1,
			"eggs": 1,
			"chocolate_chips": 2
		},
		"mixing_time": 45.0,  # 45 seconds to mix
		"baking_time": 180.0,  # 3 minutes to bake
		"base_price": 12.0,
		"quality_price_multiplier": 1.0,
		"description": "Everyone's favorite! Warm, gooey, and delicious.",
		"grandma_note": "Add a pinch of love... and maybe an extra chocolate chip!"
	})

	# Blueberry Muffins (morning favorite)
	register_recipe({
		"id": "blueberry_muffins",
		"name": "Blueberry Muffins",
		"category": "muffin",
		"ingredients": {
			"flour": 2,
			"sugar": 1,
			"eggs": 1,
			"milk": 1,
			"blueberries": 2,
			"butter": 1
		},
		"mixing_time": 50.0,  # 50 seconds to mix
		"baking_time": 240.0,  # 4 minutes to bake
		"base_price": 18.0,
		"quality_price_multiplier": 1.0,
		"description": "Fluffy muffins bursting with fresh blueberries.",
		"grandma_note": "Fresh berries make all the difference. Don't overmix!"
	})

	# Unlock all starter recipes
	unlock_recipe("white_bread")
	unlock_recipe("chocolate_chip_cookies")
	unlock_recipe("blueberry_muffins")

	print("Starter recipes initialized: 3 recipes loaded")

func register_recipe(recipe_data: Dictionary) -> void:
	"""Register a new recipe in the system"""
	if not recipe_data.has("id"):
		push_error("Recipe missing 'id' field")
		return

	var recipe_id: String = recipe_data["id"]
	recipe_data["unlocked"] = false  # Default to locked
	recipes[recipe_id] = recipe_data
	print("Recipe registered: ", recipe_data.get("name", recipe_id))

func unlock_recipe(recipe_id: String) -> bool:
	"""Unlock a recipe for player use"""
	if not recipes.has(recipe_id):
		push_warning("Attempted to unlock unknown recipe: ", recipe_id)
		return false

	if is_recipe_unlocked(recipe_id):
		print("Recipe already unlocked: ", recipe_id)
		return false

	recipes[recipe_id]["unlocked"] = true
	unlocked_recipes.append(recipe_id)
	print("Recipe unlocked: ", recipes[recipe_id]["name"])
	recipe_unlocked.emit(recipe_id)
	return true

func is_recipe_unlocked(recipe_id: String) -> bool:
	"""Check if a recipe is unlocked"""
	if not recipes.has(recipe_id):
		return false
	return recipes[recipe_id].get("unlocked", false)

func get_recipe(recipe_id: String) -> Dictionary:
	"""Get recipe data by ID"""
	if recipes.has(recipe_id):
		return recipes[recipe_id]
	push_warning("Unknown recipe: ", recipe_id)
	return {}

func get_all_unlocked_recipes() -> Array[Dictionary]:
	"""Get all recipes the player has unlocked"""
	var unlocked: Array[Dictionary] = []
	for recipe_id in unlocked_recipes:
		if recipes.has(recipe_id):
			unlocked.append(recipes[recipe_id])
	return unlocked

func get_recipes_by_category(category: String) -> Array[Dictionary]:
	"""Get all unlocked recipes in a specific category"""
	var filtered: Array[Dictionary] = []
	for recipe_id in unlocked_recipes:
		if recipes.has(recipe_id) and recipes[recipe_id].get("category", "") == category:
			filtered.append(recipes[recipe_id])
	return filtered

func get_recipe_ingredients(recipe_id: String) -> Dictionary:
	"""Get ingredients dictionary for a recipe"""
	var recipe: Dictionary = get_recipe(recipe_id)
	return recipe.get("ingredients", {})

func get_recipe_cost(recipe_id: String) -> float:
	"""Calculate the ingredient cost of a recipe"""
	var recipe: Dictionary = get_recipe(recipe_id)
	if recipe.is_empty():
		return 0.0

	var total_cost: float = 0.0
	var ingredients: Dictionary = recipe.get("ingredients", {})

	for ingredient_id in ingredients:
		var quantity: int = ingredients[ingredient_id]
		var price: float = EconomyManager.get_ingredient_price(ingredient_id)
		total_cost += price * quantity

	return total_cost

func get_recipe_profit(recipe_id: String) -> float:
	"""Calculate the profit margin of a recipe (price - cost)"""
	var recipe: Dictionary = get_recipe(recipe_id)
	if recipe.is_empty():
		return 0.0

	var sell_price: float = recipe.get("base_price", 0.0)
	var cost: float = get_recipe_cost(recipe_id)
	return sell_price - cost

func can_craft_recipe(recipe_id: String, available_ingredients: Dictionary) -> bool:
	"""Check if player has enough ingredients to craft a recipe"""
	var ingredients_needed: Dictionary = get_recipe_ingredients(recipe_id)

	for ingredient_id in ingredients_needed:
		var needed: int = ingredients_needed[ingredient_id]
		var available: int = available_ingredients.get(ingredient_id, 0)

		if available < needed:
			return false

	return true

# Save/Load support
func get_save_data() -> Dictionary:
	return {
		"unlocked_recipes": unlocked_recipes
	}

func load_save_data(data: Dictionary) -> void:
	if data.has("unlocked_recipes"):
		unlocked_recipes = data["unlocked_recipes"]
		# Update recipe unlock status
		for recipe_id in recipes:
			recipes[recipe_id]["unlocked"] = recipe_id in unlocked_recipes
		print("Recipes loaded: %d unlocked" % unlocked_recipes.size())
