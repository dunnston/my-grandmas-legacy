extends Node

# BalanceExporter - Export game data to CSV for balance analysis
# Generates spreadsheets with recipe data, economy data, and more

func export_all_to_csv() -> void:
	"""Export all balance data to CSV files"""
	export_recipes_csv()
	export_ingredients_csv()
	export_economy_csv()
	export_upgrades_csv()
	print("✓ All balance data exported to user://balance/")

func export_recipes_csv() -> String:
	"""Export all recipes to CSV format"""
	var recipes = RecipeManager.get_all_recipes()

	var csv: String = "Recipe ID,Name,Category,Unlock Milestone,Mixing Time,Baking Time,Base Price,Ingredients,Ingredient Costs,Total Cost,Base Profit\n"

	for recipe_id in recipes:
		var recipe = recipes[recipe_id]

		# Calculate ingredient cost
		var total_cost: float = RecipeManager.get_recipe_cost(recipe_id)

		# Format ingredients
		var ingredients_str: String = ""
		var ingredients_dict = recipe["ingredients"] if recipe.has("ingredients") else {}
		for ing in ingredients_dict:
			ingredients_str += "%s:%d " % [ing, ingredients_dict[ing]]

		var profit: float = recipe.get("base_price", 0.0) - total_cost

		csv += "\"%s\",\"%s\",\"%s\",%s,%.1f,%.1f,%.2f,\"%s\",%.2f,%.2f,%.2f\n" % [
			recipe_id,
			recipe.get("name", ""),
			recipe.get("category", ""),
			str(recipe.get("unlock_milestone", "Day 1")),
			recipe.get("mixing_time", 0.0),
			recipe.get("baking_time", 0.0),
			recipe.get("base_price", 0.0),
			ingredients_str,
			total_cost,
			total_cost,
			profit
		]

	_save_csv("balance/recipes.csv", csv)
	print("✓ Exported recipes.csv")
	return csv

func export_ingredients_csv() -> String:
	"""Export ingredient prices to CSV"""
	var csv: String = "Ingredient ID,Base Price Per Unit,Bulk Discount\n"

	# Get ingredient costs from EconomyManager
	var ingredient_prices = EconomyManager.ingredient_costs if EconomyManager.has("ingredient_costs") else {}

	for ingredient_id in ingredient_prices:
		csv += "\"%s\",%.2f,0%%\n" % [ingredient_id, ingredient_prices[ingredient_id]]

	_save_csv("balance/ingredients.csv", csv)
	print("✓ Exported ingredients.csv")
	return csv

func export_economy_csv() -> String:
	"""Export economy settings to CSV"""
	var csv: String = "Setting,Value,Notes\n"

	csv += "\"Starting Cash\",\"200\",\"Initial player money\"\n"
	csv += "\"Starting Reputation\",\"50\",\"0-100 scale\"\n"
	csv += "\"Day Length (minutes)\",\"30\",\"Real-time minutes per game day\"\n"
	csv += "\"Quality Poor Multiplier\",\"0.7\",\"-30%% price\"\n"
	csv += "\"Quality Normal Multiplier\",\"1.0\",\"Base price\"\n"
	csv += "\"Quality Good Multiplier\",\"1.2\",\"+20%% price\"\n"
	csv += "\"Quality Excellent Multiplier\",\"1.5\",\"+50%% price\"\n"
	csv += "\"Quality Perfect Multiplier\",\"2.0\",\"+100%% price\"\n"
	csv += "\"Legendary Bonus Multiplier\",\"1.5\",\"Additional +50%% on top of quality\"\n"

	_save_csv("balance/economy.csv", csv)
	print("✓ Exported economy.csv")
	return csv

func export_upgrades_csv() -> String:
	"""Export upgrade costs and effects to CSV"""
	var csv: String = "Upgrade ID,Name,Category,Cost,Unlock Milestone,Effect,Effect Value\n"

	var upgrades = UpgradeManager.get_all_upgrades() if UpgradeManager.has_method("get_all_upgrades") else {}

	for upgrade_id in upgrades:
		var upgrade = upgrades[upgrade_id]
		csv += "\"%s\",\"%s\",\"%s\",%.2f,%s,\"%s\",%s\n" % [
			upgrade_id,
			upgrade.get("name", ""),
			upgrade.get("category", ""),
			upgrade.get("cost", 0.0),
			str(upgrade.get("unlock_milestone", "Day 1")),
			upgrade.get("effect_type", ""),
			str(upgrade.get("effect_value", ""))
		]

	_save_csv("balance/upgrades.csv", csv)
	print("✓ Exported upgrades.csv")
	return csv

func export_progression_csv() -> String:
	"""Export milestone progression data"""
	var csv: String = "Milestone,Revenue Required,Recipes Unlocked,Letter Received\n"

	var milestones = [
		{"revenue": 0, "recipes": "White Bread, Cookies, Muffins", "letter": "None"},
		{"revenue": 500, "recipes": "Croissants, Danish, Scones, Cinnamon Rolls", "letter": "No"},
		{"revenue": 2000, "recipes": "Sourdough, Baguettes, Focaccia, Rye, Multigrain", "letter": "No"},
		{"revenue": 5000, "recipes": "Birthday Cake, Wedding Cupcakes, Cheesecake, Layer Cake", "letter": "Yes"},
		{"revenue": 10000, "recipes": "Apple Pie, Secret Cookies, Chocolate Cake, Holiday Bread", "letter": "Yes"},
		{"revenue": 25000, "recipes": "Macarons, Stollen, Biscotti, Melon Pan", "letter": "Yes"},
		{"revenue": 50000, "recipes": "Legendary Cake, Championship, Festival Winner", "letter": "Yes (Ending)"}
	]

	for milestone in milestones:
		csv += "$%.0f,\"%s\",\"%s\"\n" % [
			milestone.revenue,
			milestone.recipes,
			milestone.letter
		]

	_save_csv("balance/progression.csv", csv)
	print("✓ Exported progression.csv")
	return csv

func _save_csv(filename: String, content: String) -> void:
	"""Save CSV content to user:// directory"""
	var dir_path = "user://balance"

	# Create directory if it doesn't exist
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("balance"):
		dir.make_dir("balance")

	# Save file
	var file_path = "user://" + filename
	var file = FileAccess.open(file_path, FileAccess.WRITE)

	if file:
		file.store_string(content)
		file.close()
		print("Saved: ", file_path)
	else:
		print("Error: Could not save ", file_path)

func print_export_paths() -> void:
	"""Print where exports are saved"""
	print("\n=== BALANCE EXPORT LOCATIONS ===")
	print("All files saved to: ", OS.get_user_data_dir(), "/balance/")
	print("Files:")
	print("  - recipes.csv")
	print("  - ingredients.csv")
	print("  - economy.csv")
	print("  - upgrades.csv")
	print("  - progression.csv")
	print("================================\n")
