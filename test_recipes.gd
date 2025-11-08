extends Node

# Quick test script to verify recipe system
# Run this in Godot editor: F6 on this scene

func _ready() -> void:
	print("\n=== RECIPE SYSTEM TEST ===\n")

	# Wait for autoloads to initialize
	await get_tree().process_frame

	# Test 1: Check total recipe count
	print("Test 1: Recipe Count")
	print("Total recipes registered: %d" % RecipeManager.recipes.size())
	print("Expected: 27")
	print("✓ PASS" if RecipeManager.recipes.size() == 27 else "✗ FAIL")

	print("\n---\n")

	# Test 2: Check starter recipes are unlocked
	print("Test 2: Starter Recipes Unlocked")
	var starter_recipes = ["white_bread", "chocolate_chip_cookies", "blueberry_muffins"]
	var all_unlocked = true
	for recipe_id in starter_recipes:
		var unlocked = RecipeManager.is_recipe_unlocked(recipe_id)
		print("%s: %s" % [recipe_id, "✓ unlocked" if unlocked else "✗ locked"])
		if not unlocked:
			all_unlocked = false
	print("✓ PASS" if all_unlocked else "✗ FAIL")

	print("\n---\n")

	# Test 3: List all recipes by tier
	print("Test 3: Recipes by Unlock Tier")

	var tiers = {
		"Starter": [],
		"$500": [],
		"$2,000": [],
		"$5,000": [],
		"$10,000": [],
		"$25,000": [],
		"$50,000": []
	}

	for recipe_id in RecipeManager.recipes:
		var recipe = RecipeManager.recipes[recipe_id]
		var milestone = recipe.get("unlock_milestone", 0)

		match milestone:
			0: tiers["Starter"].append(recipe["name"])
			500: tiers["$500"].append(recipe["name"])
			2000: tiers["$2,000"].append(recipe["name"])
			5000: tiers["$5,000"].append(recipe["name"])
			10000: tiers["$10,000"].append(recipe["name"])
			25000: tiers["$25,000"].append(recipe["name"])
			50000: tiers["$50,000"].append(recipe["name"])

	for tier_name in tiers:
		print("\n%s:" % tier_name)
		for recipe_name in tiers[tier_name]:
			print("  - %s" % recipe_name)

	print("\n---\n")

	# Test 4: Test milestone-recipe connection
	print("Test 4: Milestone-Recipe Integration")
	print("Simulating $500 revenue milestone...")

	# Simulate reaching $500 milestone
	ProgressionManager.add_revenue(500.0)
	await get_tree().create_timer(0.1).timeout

	# Check if basic pastries were unlocked
	var pastries = ["croissants", "danish_pastries", "scones", "cinnamon_rolls"]
	var unlocked_count = 0
	for recipe_id in pastries:
		if RecipeManager.is_recipe_unlocked(recipe_id):
			unlocked_count += 1
			print("  ✓ %s unlocked" % RecipeManager.get_recipe(recipe_id)["name"])

	print("Unlocked %d/4 basic pastries" % unlocked_count)
	print("✓ PASS" if unlocked_count == 4 else "✗ FAIL")

	print("\n---\n")

	# Test 5: Check grandma notes
	print("Test 5: Grandma's Notes")
	var sample_recipes = ["white_bread", "croissants", "grandmas_apple_pie"]
	for recipe_id in sample_recipes:
		var recipe = RecipeManager.get_recipe(recipe_id)
		if recipe.has("grandma_note"):
			print("%s: \"%s\"" % [recipe["name"], recipe["grandma_note"]])

	print("\n=== TEST COMPLETE ===\n")

	# Auto-quit after 2 seconds
	await get_tree().create_timer(2.0).timeout
	get_tree().quit()
