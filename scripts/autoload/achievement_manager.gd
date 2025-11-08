extends Node

# AchievementManager - Tracks player achievements and milestones
# Records legendary items, perfect bakes, and special accomplishments

# Signals
signal achievement_unlocked(achievement_id: String, achievement_data: Dictionary)

# Achievement tracking
var achievements: Dictionary = {}
var unlocked_achievements: Array[String] = []

# Statistics tracking
var stats: Dictionary = {
	"legendary_items_created": 0,
	"perfect_items_created": 0,
	"excellent_items_created": 0,
	"total_items_baked": 0,
	"total_sales": 0,
	"highest_single_sale": 0.0,
	"total_revenue": 0.0,
	"days_played": 0,
	"recipes_mastered": [],  # Recipes with 10+ perfect bakes
	"consecutive_perfect_bakes": 0,
	"best_perfect_streak": 0
}

func _ready() -> void:
	_initialize_achievements()
	_connect_signals()
	print("AchievementManager initialized")

func _initialize_achievements() -> void:
	"""Define all achievements"""

	# Quality achievements
	register_achievement({
		"id": "first_perfect",
		"name": "Perfect Start",
		"description": "Create your first perfect quality item",
		"icon": "⭐",
		"hidden": false
	})

	register_achievement({
		"id": "first_legendary",
		"name": "Legendary Baker",
		"description": "Create your first legendary item",
		"icon": "✨",
		"hidden": false
	})

	register_achievement({
		"id": "perfect_10",
		"name": "Perfectionist",
		"description": "Create 10 perfect quality items",
		"icon": "💯",
		"hidden": false
	})

	register_achievement({
		"id": "legendary_5",
		"name": "Legend",
		"description": "Create 5 legendary items",
		"icon": "👑",
		"hidden": false
	})

	register_achievement({
		"id": "perfect_streak_5",
		"name": "On Fire!",
		"description": "Create 5 perfect items in a row",
		"icon": "🔥",
		"hidden": false
	})

	# Recipe mastery
	register_achievement({
		"id": "recipe_master",
		"name": "Recipe Master",
		"description": "Master a recipe (10+ perfect bakes)",
		"icon": "📖",
		"hidden": false
	})

	register_achievement({
		"id": "all_recipes_unlocked",
		"name": "Full Menu",
		"description": "Unlock all 27 recipes",
		"icon": "🎯",
		"hidden": false
	})

	# Revenue milestones
	register_achievement({
		"id": "first_sale",
		"name": "First Customer",
		"description": "Complete your first sale",
		"icon": "💰",
		"hidden": false
	})

	register_achievement({
		"id": "big_spender",
		"name": "Big Spender",
		"description": "Single sale worth $100+",
		"icon": "💸",
		"hidden": true
	})

	# Special achievements
	register_achievement({
		"id": "grandmas_legacy",
		"name": "Grandma's Legacy Complete",
		"description": "Reach $50,000 total revenue",
		"icon": "🏆",
		"hidden": false
	})

func register_achievement(achievement_data: Dictionary) -> void:
	"""Register a new achievement"""
	var id: String = achievement_data.get("id", "")
	if id == "":
		print("Error: Achievement missing ID")
		return

	achievements[id] = achievement_data
	achievements[id]["unlocked"] = false
	achievements[id]["unlock_time"] = 0

func _connect_signals() -> void:
	"""Connect to game events to track achievements"""
	# Connect to QualityManager signals
	QualityManager.legendary_item_created.connect(_on_legendary_created)
	QualityManager.quality_calculated.connect(_on_quality_calculated)

	# Connect to EconomyManager signals
	if EconomyManager.has_signal("sale_completed"):
		EconomyManager.sale_completed.connect(_on_sale_completed)

func _on_legendary_created(item_id: String, quality: float) -> void:
	"""Track legendary item creation"""
	stats.legendary_items_created += 1
	stats.total_items_baked += 1

	print("✨ ACHIEVEMENT TRACKER: Legendary item #%d created!" % stats.legendary_items_created)

	# Check achievements
	if stats.legendary_items_created == 1:
		unlock_achievement("first_legendary")

	if stats.legendary_items_created == 5:
		unlock_achievement("legendary_5")

func _on_quality_calculated(item_id: String, quality: float, quality_tier: String) -> void:
	"""Track quality tiers"""
	stats.total_items_baked += 1

	if quality_tier == "PERFECT":
		stats.perfect_items_created += 1
		stats.consecutive_perfect_bakes += 1

		if stats.consecutive_perfect_bakes > stats.best_perfect_streak:
			stats.best_perfect_streak = stats.consecutive_perfect_bakes

		# Check achievements
		if stats.perfect_items_created == 1:
			unlock_achievement("first_perfect")

		if stats.perfect_items_created == 10:
			unlock_achievement("perfect_10")

		if stats.consecutive_perfect_bakes == 5:
			unlock_achievement("perfect_streak_5")

	elif quality_tier == "EXCELLENT":
		stats.excellent_items_created += 1
		stats.consecutive_perfect_bakes = 0  # Reset streak
	else:
		stats.consecutive_perfect_bakes = 0  # Reset streak

func _on_sale_completed(item: String, price: float) -> void:
	"""Track sales"""
	stats.total_sales += 1
	stats.total_revenue += price

	if stats.total_sales == 1:
		unlock_achievement("first_sale")

	if price > stats.highest_single_sale:
		stats.highest_single_sale = price

	if price >= 100.0:
		unlock_achievement("big_spender")

	if stats.total_revenue >= 50000.0:
		unlock_achievement("grandmas_legacy")

func track_recipe_mastery(recipe_id: String, quality_tier: String) -> void:
	"""Track recipe mastery (called manually from equipment)"""
	if quality_tier != "PERFECT":
		return

	# Count perfect bakes per recipe
	if not stats.has("recipe_perfect_counts"):
		stats["recipe_perfect_counts"] = {}

	if not stats.recipe_perfect_counts.has(recipe_id):
		stats.recipe_perfect_counts[recipe_id] = 0

	stats.recipe_perfect_counts[recipe_id] += 1

	if stats.recipe_perfect_counts[recipe_id] == 10:
		if not stats.recipes_mastered.has(recipe_id):
			stats.recipes_mastered.append(recipe_id)
			unlock_achievement("recipe_master")
			print("🎓 MASTERED RECIPE: %s" % recipe_id)

func unlock_achievement(achievement_id: String) -> void:
	"""Unlock an achievement"""
	if not achievements.has(achievement_id):
		print("Error: Unknown achievement: ", achievement_id)
		return

	if achievements[achievement_id].unlocked:
		return  # Already unlocked

	achievements[achievement_id].unlocked = true
	achievements[achievement_id].unlock_time = Time.get_unix_time_from_system()
	unlocked_achievements.append(achievement_id)

	var ach = achievements[achievement_id]
	print("\n🏆 === ACHIEVEMENT UNLOCKED === 🏆")
	print("%s %s" % [ach.icon, ach.name])
	print(ach.description)
	print("==============================\n")

	achievement_unlocked.emit(achievement_id, ach)

func is_achievement_unlocked(achievement_id: String) -> bool:
	"""Check if achievement is unlocked"""
	if not achievements.has(achievement_id):
		return false
	return achievements[achievement_id].unlocked

func get_achievement_progress(achievement_id: String) -> Dictionary:
	"""Get progress toward an achievement"""
	match achievement_id:
		"perfect_10":
			return {"current": stats.perfect_items_created, "target": 10}
		"legendary_5":
			return {"current": stats.legendary_items_created, "target": 5}
		"perfect_streak_5":
			return {"current": stats.consecutive_perfect_bakes, "target": 5}
		"all_recipes_unlocked":
			var unlocked = RecipeManager.get_all_unlocked_recipes().size()
			return {"current": unlocked, "target": 27}
		_:
			return {}

func get_all_achievements() -> Array:
	"""Get all achievements"""
	var result: Array = []
	for id in achievements:
		var ach = achievements[id].duplicate()
		ach["progress"] = get_achievement_progress(id)
		result.append(ach)
	return result

func get_unlocked_achievements() -> Array:
	"""Get only unlocked achievements"""
	var result: Array = []
	for id in unlocked_achievements:
		result.append(achievements[id].duplicate())
	return result

func get_stats() -> Dictionary:
	"""Get current statistics"""
	return stats.duplicate()

func print_stats() -> void:
	"""Print achievement statistics"""
	print("\n=== ACHIEVEMENT STATS ===")
	print("Legendary Items: %d" % stats.legendary_items_created)
	print("Perfect Items: %d" % stats.perfect_items_created)
	print("Excellent Items: %d" % stats.excellent_items_created)
	print("Total Items Baked: %d" % stats.total_items_baked)
	print("Best Perfect Streak: %d" % stats.best_perfect_streak)
	print("Recipes Mastered: %d" % stats.recipes_mastered.size())
	print("Achievements Unlocked: %d/%d" % [unlocked_achievements.size(), achievements.size()])
	print("========================\n")

# Save/Load support
func get_save_data() -> Dictionary:
	"""Get achievement data for saving"""
	return {
		"stats": stats.duplicate(true),
		"unlocked_achievements": unlocked_achievements.duplicate(),
		"achievements": achievements.duplicate(true)
	}

func load_save_data(data: Dictionary) -> void:
	"""Load achievement data from save"""
	if data.has("stats"):
		stats = data["stats"].duplicate(true)

	if data.has("unlocked_achievements"):
		unlocked_achievements = data["unlocked_achievements"].duplicate()

	if data.has("achievements"):
		# Merge with existing achievements to preserve new ones
		for id in data.achievements:
			if achievements.has(id):
				achievements[id].unlocked = data.achievements[id].unlocked
				achievements[id].unlock_time = data.achievements[id].get("unlock_time", 0)

	print("Achievement data loaded: %d achievements unlocked" % unlocked_achievements.size())
