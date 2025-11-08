extends Node

# RecipeManager - Singleton for managing recipes and crafting data
# Stores all recipe information, ingredients, times, and prices
#
# BALANCE CONFIG INTEGRATION:
# Recipe times and prices can be adjusted via BalanceConfig.
# Individual recipe values are multiplied by global multipliers from balance_config.gd

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
	_initialize_all_recipes()

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

func _initialize_all_recipes() -> void:
	"""Initialize all 27 recipes from GDD organized by unlock tiers"""

	# ============================================================
	# STARTER RECIPES (Available from Day 1)
	# ============================================================
	_initialize_starter_recipes()

	# ============================================================
	# BASIC PASTRIES ($500 unlock)
	# ============================================================

	# 4. Croissants
	register_recipe({
		"id": "croissants",
		"name": "Croissants",
		"category": "pastry",
		"unlock_milestone": 500,
		"ingredients": {
			"flour": 3,
			"butter": 3,
			"milk": 1,
			"eggs": 1,
			"yeast": 1
		},
		"mixing_time": 90.0,  # More complex lamination process
		"baking_time": 360.0,  # 6 minutes
		"base_price": 25.0,
		"quality_price_multiplier": 1.2,
		"description": "Buttery, flaky French pastries. A morning favorite.",
		"grandma_note": "Patience with the layers, dear. Cold butter is key!"
	})

	# 5. Danish Pastries
	register_recipe({
		"id": "danish_pastries",
		"name": "Danish Pastries",
		"category": "pastry",
		"unlock_milestone": 500,
		"ingredients": {
			"flour": 2,
			"butter": 2,
			"sugar": 2,
			"eggs": 1,
			"cream_cheese": 1,
			"fruit_filling": 1
		},
		"mixing_time": 75.0,
		"baking_time": 300.0,  # 5 minutes
		"base_price": 22.0,
		"quality_price_multiplier": 1.2,
		"description": "Sweet pastries with cream cheese and fruit filling.",
		"grandma_note": "Don't be shy with the filling - generous is good!"
	})

	# 6. Scones
	register_recipe({
		"id": "scones",
		"name": "Scones",
		"category": "pastry",
		"unlock_milestone": 500,
		"ingredients": {
			"flour": 2,
			"butter": 2,
			"sugar": 1,
			"milk": 1,
			"baking_powder": 1
		},
		"mixing_time": 40.0,  # Quick mixing
		"baking_time": 240.0,  # 4 minutes
		"base_price": 18.0,
		"quality_price_multiplier": 1.1,
		"description": "British teatime classic. Perfect with jam and cream.",
		"grandma_note": "Handle the dough gently - we want them tender, not tough!"
	})

	# 7. Cinnamon Rolls
	register_recipe({
		"id": "cinnamon_rolls",
		"name": "Cinnamon Rolls",
		"category": "pastry",
		"unlock_milestone": 500,
		"ingredients": {
			"flour": 3,
			"sugar": 2,
			"butter": 2,
			"milk": 1,
			"eggs": 1,
			"cinnamon": 2,
			"yeast": 1
		},
		"mixing_time": 80.0,
		"baking_time": 420.0,  # 7 minutes (rise + bake)
		"base_price": 28.0,
		"quality_price_multiplier": 1.3,
		"description": "Soft, gooey rolls swirled with cinnamon and sugar.",
		"grandma_note": "The smell alone will bring customers running!"
	})

	# ============================================================
	# ARTISAN BREADS ($2,000 unlock)
	# ============================================================

	# 8. Sourdough
	register_recipe({
		"id": "sourdough",
		"name": "Sourdough Bread",
		"category": "bread",
		"unlock_milestone": 2000,
		"ingredients": {
			"flour": 4,
			"water": 2,
			"salt": 1,
			"sourdough_starter": 2
		},
		"mixing_time": 120.0,  # Long fermentation time
		"baking_time": 600.0,  # 10 minutes
		"base_price": 35.0,
		"quality_price_multiplier": 1.5,
		"description": "Tangy artisan bread with a crispy crust.",
		"grandma_note": "Our starter is older than you! Treat it with respect."
	})

	# 9. Baguettes
	register_recipe({
		"id": "baguettes",
		"name": "French Baguettes",
		"category": "bread",
		"unlock_milestone": 2000,
		"ingredients": {
			"flour": 3,
			"water": 2,
			"yeast": 1,
			"salt": 1
		},
		"mixing_time": 70.0,
		"baking_time": 420.0,  # 7 minutes
		"base_price": 20.0,
		"quality_price_multiplier": 1.3,
		"description": "Classic French bread with a golden crust.",
		"grandma_note": "Score the top just right for that perfect crackle!"
	})

	# 10. Focaccia
	register_recipe({
		"id": "focaccia",
		"name": "Focaccia",
		"category": "bread",
		"unlock_milestone": 2000,
		"ingredients": {
			"flour": 3,
			"water": 2,
			"olive_oil": 2,
			"yeast": 1,
			"salt": 1,
			"herbs": 1
		},
		"mixing_time": 65.0,
		"baking_time": 360.0,  # 6 minutes
		"base_price": 24.0,
		"quality_price_multiplier": 1.2,
		"description": "Italian flatbread drizzled with olive oil and herbs.",
		"grandma_note": "Press those dimples deep - they hold the olive oil!"
	})

	# 11. Rye Bread
	register_recipe({
		"id": "rye_bread",
		"name": "Rye Bread",
		"category": "bread",
		"unlock_milestone": 2000,
		"ingredients": {
			"rye_flour": 3,
			"flour": 1,
			"water": 2,
			"yeast": 1,
			"salt": 1,
			"caraway_seeds": 1
		},
		"mixing_time": 80.0,
		"baking_time": 480.0,  # 8 minutes
		"base_price": 26.0,
		"quality_price_multiplier": 1.3,
		"description": "Dense, hearty bread with a distinctive flavor.",
		"grandma_note": "Your grandfather's favorite. Dense and delicious!"
	})

	# 12. Multigrain Loaf
	register_recipe({
		"id": "multigrain_loaf",
		"name": "Multigrain Loaf",
		"category": "bread",
		"unlock_milestone": 2000,
		"ingredients": {
			"flour": 2,
			"whole_wheat_flour": 2,
			"oats": 1,
			"seeds": 1,
			"water": 2,
			"yeast": 1,
			"honey": 1
		},
		"mixing_time": 75.0,
		"baking_time": 540.0,  # 9 minutes
		"base_price": 30.0,
		"quality_price_multiplier": 1.4,
		"description": "Nutritious bread packed with grains and seeds.",
		"grandma_note": "Healthy and hearty - good for body and soul!"
	})

	# ============================================================
	# SPECIAL OCCASION CAKES ($5,000 unlock)
	# ============================================================

	# 13. Birthday Cake
	register_recipe({
		"id": "birthday_cake",
		"name": "Birthday Cake",
		"category": "cake",
		"unlock_milestone": 5000,
		"ingredients": {
			"flour": 4,
			"sugar": 4,
			"butter": 3,
			"eggs": 3,
			"milk": 2,
			"vanilla": 1,
			"frosting": 2
		},
		"mixing_time": 100.0,
		"baking_time": 720.0,  # 12 minutes (multi-layer)
		"base_price": 60.0,
		"quality_price_multiplier": 2.0,
		"description": "Classic celebration cake. Customizable for any occasion.",
		"grandma_note": "Every birthday deserves to be special!"
	})

	# 14. Wedding Cupcakes
	register_recipe({
		"id": "wedding_cupcakes",
		"name": "Wedding Cupcakes",
		"category": "cake",
		"unlock_milestone": 5000,
		"ingredients": {
			"flour": 3,
			"sugar": 3,
			"butter": 2,
			"eggs": 2,
			"milk": 1,
			"vanilla": 1,
			"frosting": 3,
			"decorative_sugar": 1
		},
		"mixing_time": 90.0,
		"baking_time": 480.0,  # 8 minutes
		"base_price": 55.0,
		"quality_price_multiplier": 1.8,
		"description": "Elegant cupcakes for the most special day.",
		"grandma_note": "I made these for your parents' wedding. Remember love!"
	})

	# 15. Cheesecake
	register_recipe({
		"id": "cheesecake",
		"name": "Cheesecake",
		"category": "cake",
		"unlock_milestone": 5000,
		"ingredients": {
			"cream_cheese": 4,
			"sugar": 3,
			"eggs": 2,
			"sour_cream": 2,
			"graham_crackers": 2,
			"butter": 1,
			"vanilla": 1
		},
		"mixing_time": 85.0,
		"baking_time": 900.0,  # 15 minutes (slow bake + chill)
		"base_price": 50.0,
		"quality_price_multiplier": 1.7,
		"description": "Rich, creamy New York style cheesecake.",
		"grandma_note": "Low and slow - patience makes perfection!"
	})

	# 16. Layer Cake
	register_recipe({
		"id": "layer_cake",
		"name": "Layer Cake",
		"category": "cake",
		"unlock_milestone": 5000,
		"ingredients": {
			"flour": 5,
			"sugar": 4,
			"butter": 3,
			"eggs": 4,
			"milk": 2,
			"cocoa": 2,
			"frosting": 3
		},
		"mixing_time": 110.0,
		"baking_time": 780.0,  # 13 minutes
		"base_price": 65.0,
		"quality_price_multiplier": 2.0,
		"description": "Impressive multi-layer cake with rich frosting.",
		"grandma_note": "Level those layers! We're not building the Leaning Tower!"
	})

	# ============================================================
	# GRANDMA'S SECRET RECIPES ($10,000 unlock)
	# ============================================================

	# 17. Grandmother's Apple Pie
	register_recipe({
		"id": "grandmas_apple_pie",
		"name": "Grandmother's Apple Pie",
		"category": "pie",
		"unlock_milestone": 10000,
		"ingredients": {
			"flour": 3,
			"butter": 3,
			"sugar": 2,
			"apples": 5,
			"cinnamon": 2,
			"nutmeg": 1,
			"eggs": 1
		},
		"mixing_time": 120.0,
		"baking_time": 840.0,  # 14 minutes
		"base_price": 75.0,
		"quality_price_multiplier": 2.5,
		"description": "The recipe that started it all. Made with love.",
		"grandma_note": "This pie won first place at the county fair, three years running!"
	})

	# 18. Secret Recipe Cookies
	register_recipe({
		"id": "secret_recipe_cookies",
		"name": "Secret Recipe Cookies",
		"category": "cookie",
		"unlock_milestone": 10000,
		"ingredients": {
			"flour": 2,
			"butter": 2,
			"sugar": 2,
			"brown_sugar": 1,
			"eggs": 1,
			"secret_spice": 1,
			"chocolate_chips": 2,
			"vanilla": 1
		},
		"mixing_time": 95.0,
		"baking_time": 360.0,  # 6 minutes
		"base_price": 45.0,
		"quality_price_multiplier": 2.0,
		"description": "The secret ingredient? I'll never tell... okay, it's cardamom!",
		"grandma_note": "Don't tell anyone about the cardamom - let them wonder!"
	})

	# 19. Family Chocolate Cake
	register_recipe({
		"id": "family_chocolate_cake",
		"name": "Family Chocolate Cake",
		"category": "cake",
		"unlock_milestone": 10000,
		"ingredients": {
			"flour": 4,
			"sugar": 4,
			"cocoa": 3,
			"butter": 3,
			"eggs": 3,
			"buttermilk": 2,
			"coffee": 1,
			"frosting": 3
		},
		"mixing_time": 105.0,
		"baking_time": 720.0,  # 12 minutes
		"base_price": 70.0,
		"quality_price_multiplier": 2.3,
		"description": "Rich, moist chocolate cake. Every family gathering's centerpiece.",
		"grandma_note": "The coffee enhances the chocolate - trust me on this!"
	})

	# 20. Holiday Specialty Bread
	register_recipe({
		"id": "holiday_specialty_bread",
		"name": "Holiday Specialty Bread",
		"category": "bread",
		"unlock_milestone": 10000,
		"ingredients": {
			"flour": 4,
			"butter": 2,
			"sugar": 2,
			"eggs": 2,
			"milk": 1,
			"yeast": 1,
			"dried_fruit": 3,
			"spices": 2,
			"nuts": 1
		},
		"mixing_time": 100.0,
		"baking_time": 660.0,  # 11 minutes
		"base_price": 55.0,
		"quality_price_multiplier": 2.0,
		"description": "Festive bread filled with fruits, nuts, and holiday spices.",
		"grandma_note": "We made this every Christmas. The smell meant family was coming!"
	})

	# ============================================================
	# INTERNATIONAL TREATS ($25,000 unlock)
	# ============================================================

	# 21. French Macarons
	register_recipe({
		"id": "french_macarons",
		"name": "French Macarons",
		"category": "pastry",
		"unlock_milestone": 25000,
		"ingredients": {
			"almond_flour": 3,
			"powdered_sugar": 3,
			"egg_whites": 3,
			"sugar": 2,
			"food_coloring": 1,
			"ganache": 2
		},
		"mixing_time": 150.0,  # Very technical
		"baking_time": 540.0,  # 9 minutes
		"base_price": 80.0,
		"quality_price_multiplier": 3.0,
		"description": "Delicate French cookies. Notoriously difficult to master.",
		"grandma_note": "I learned this in Paris, 1962. Took me fifty tries!"
	})

	# 22. German Stollen
	register_recipe({
		"id": "german_stollen",
		"name": "German Stollen",
		"category": "bread",
		"unlock_milestone": 25000,
		"ingredients": {
			"flour": 4,
			"butter": 3,
			"sugar": 2,
			"milk": 2,
			"yeast": 1,
			"dried_fruit": 3,
			"marzipan": 2,
			"rum": 1,
			"spices": 2
		},
		"mixing_time": 130.0,
		"baking_time": 720.0,  # 12 minutes
		"base_price": 85.0,
		"quality_price_multiplier": 2.8,
		"description": "Traditional German Christmas bread with marzipan center.",
		"grandma_note": "Your great-grandmother brought this recipe from the old country!"
	})

	# 23. Italian Biscotti
	register_recipe({
		"id": "italian_biscotti",
		"name": "Italian Biscotti",
		"category": "cookie",
		"unlock_milestone": 25000,
		"ingredients": {
			"flour": 3,
			"sugar": 2,
			"eggs": 2,
			"almonds": 3,
			"anise": 1,
			"baking_powder": 1,
			"vanilla": 1
		},
		"mixing_time": 80.0,
		"baking_time": 600.0,  # 10 minutes (double bake)
		"base_price": 40.0,
		"quality_price_multiplier": 1.8,
		"description": "Twice-baked Italian cookies. Perfect for coffee dipping.",
		"grandma_note": "Bake twice, keep forever. Well, almost!"
	})

	# 24. Japanese Melon Pan
	register_recipe({
		"id": "japanese_melon_pan",
		"name": "Japanese Melon Pan",
		"category": "bread",
		"unlock_milestone": 25000,
		"ingredients": {
			"flour": 3,
			"bread_flour": 2,
			"sugar": 3,
			"butter": 2,
			"eggs": 2,
			"milk": 1,
			"yeast": 1,
			"vanilla": 1
		},
		"mixing_time": 110.0,
		"baking_time": 480.0,  # 8 minutes
		"base_price": 35.0,
		"quality_price_multiplier": 1.9,
		"description": "Sweet Japanese bread with a crispy cookie crust.",
		"grandma_note": "I learned this from Mrs. Tanaka down the street. So creative!"
	})

	# ============================================================
	# LEGENDARY BAKES ($50,000 unlock - End Game)
	# ============================================================

	# 25. Grandmother's Legendary Cake
	register_recipe({
		"id": "legendary_signature_cake",
		"name": "Grandmother's Legendary Cake",
		"category": "cake",
		"unlock_milestone": 50000,
		"ingredients": {
			"flour": 6,
			"sugar": 5,
			"butter": 4,
			"eggs": 5,
			"cream": 3,
			"cocoa": 2,
			"vanilla": 2,
			"frosting": 4,
			"gold_leaf": 1  # Decorative
		},
		"mixing_time": 180.0,  # 3 minutes - master recipe
		"baking_time": 1200.0,  # 20 minutes - epic bake
		"base_price": 150.0,
		"quality_price_multiplier": 4.0,
		"description": "The pinnacle of baking mastery. Grandma's masterpiece.",
		"grandma_note": "You've done it, dear. This was my greatest achievement. Now it's yours."
	})

	# 26. Championship Recipe
	register_recipe({
		"id": "championship_recipe",
		"name": "Championship Recipe",
		"category": "cake",
		"unlock_milestone": 50000,
		"ingredients": {
			"flour": 5,
			"sugar": 5,
			"butter": 4,
			"eggs": 4,
			"chocolate": 4,
			"cream": 3,
			"vanilla": 2,
			"frosting": 4,
			"decorative_sugar": 2
		},
		"mixing_time": 160.0,
		"baking_time": 960.0,  # 16 minutes
		"base_price": 125.0,
		"quality_price_multiplier": 3.5,
		"description": "Competition-grade baking. Blue ribbon guaranteed.",
		"grandma_note": "This won the state championship, 1975. Make me proud!"
	})

	# 27. Town Festival Winner
	register_recipe({
		"id": "town_festival_winner",
		"name": "Town Festival Winner",
		"category": "pastry",
		"unlock_milestone": 50000,
		"ingredients": {
			"flour": 5,
			"butter": 4,
			"sugar": 4,
			"eggs": 3,
			"cream": 3,
			"fruit": 4,
			"honey": 2,
			"nuts": 2
		},
		"mixing_time": 140.0,
		"baking_time": 840.0,  # 14 minutes
		"base_price": 110.0,
		"quality_price_multiplier": 3.2,
		"description": "The pastry that made our bakery famous.",
		"grandma_note": "They still talk about this at the festival. Legend lives on!"
	})

	print("All recipes initialized: %d total recipes" % recipes.size())

func register_recipe(recipe_data: Dictionary) -> void:
	"""Register a new recipe in the system"""
	if not recipe_data.has("id"):
		push_error("Recipe missing 'id' field")
		return

	var recipe_id: String = recipe_data["id"]
	recipe_data["unlocked"] = false  # Default to locked

	# Apply BalanceConfig multipliers if available
	if BalanceConfig:
		# Apply time multipliers
		if recipe_data.has("mixing_time"):
			recipe_data["mixing_time"] *= BalanceConfig.RECIPES.mixing_time_multiplier
		if recipe_data.has("baking_time"):
			recipe_data["baking_time"] *= BalanceConfig.RECIPES.baking_time_multiplier

		# Apply price multiplier from BalanceConfig helper function
		if recipe_data.has("base_price"):
			recipe_data["base_price"] = BalanceConfig.get_recipe_price(recipe_id)

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

# Helper functions for UI
func get_all_recipes() -> Dictionary:
	"""Get all recipes (both locked and unlocked)"""
	return recipes

func get_all_ingredients() -> Dictionary:
	"""Get all unique ingredients from all recipes"""
	var ingredients: Dictionary = {}

	# Common baking ingredients with names
	var ingredient_data := {
		"flour": {"name": "Flour", "category": "dry"},
		"sugar": {"name": "Sugar", "category": "dry"},
		"eggs": {"name": "Eggs", "category": "dairy"},
		"butter": {"name": "Butter", "category": "dairy"},
		"milk": {"name": "Milk", "category": "dairy"},
		"yeast": {"name": "Yeast", "category": "leavening"},
		"baking_powder": {"name": "Baking Powder", "category": "leavening"},
		"vanilla": {"name": "Vanilla Extract", "category": "flavoring"},
		"cocoa": {"name": "Cocoa Powder", "category": "flavoring"},
		"chocolate": {"name": "Chocolate", "category": "flavoring"},
		"cream_cheese": {"name": "Cream Cheese", "category": "dairy"},
		"heavy_cream": {"name": "Heavy Cream", "category": "dairy"},
		"salt": {"name": "Salt", "category": "seasoning"},
		"cinnamon": {"name": "Cinnamon", "category": "spice"},
		"lemon": {"name": "Lemon", "category": "fruit"},
		"honey": {"name": "Honey", "category": "sweetener"},
		"almond_flour": {"name": "Almond Flour", "category": "dry"},
		"coconut": {"name": "Shredded Coconut", "category": "flavoring"},
		"raisins": {"name": "Raisins", "category": "fruit"},
		"walnuts": {"name": "Walnuts", "category": "nuts"},
		"matcha": {"name": "Matcha Powder", "category": "flavoring"},
		"cardamom": {"name": "Cardamom", "category": "spice"},
		"rose_water": {"name": "Rose Water", "category": "flavoring"},
		"pistachios": {"name": "Pistachios", "category": "nuts"},
		"saffron": {"name": "Saffron", "category": "spice"}
	}

	return ingredient_data
