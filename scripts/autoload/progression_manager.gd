extends Node

# ProgressionManager - Singleton for managing progression, unlocks, and milestones
# Tracks total lifetime revenue, reputation, and milestone-based unlocks

# Signals
signal milestone_reached(milestone_id: String, revenue_threshold: float)
signal recipe_unlocked(recipe_id: String, recipe_name: String)
signal reputation_changed(new_reputation: int)
signal tier_unlocked(tier_name: String)

# Progression state
var total_lifetime_revenue: float = 0.0
var reputation: int = 50  # Range: 0-100, starts at 50
var current_day: int = 1

# Milestone definitions (from GDD) - matches RecipeManager recipe IDs
var milestones: Dictionary = {
	"basic_pastries": {
		"revenue_threshold": 500.0,
		"reached": false,
		"tier_name": "Basic Pastries",
		"unlocks": ["croissants", "danish_pastries", "scones", "cinnamon_rolls"],
		"story_beat": true  # Triggers grandmother's letter
	},
	"artisan_breads": {
		"revenue_threshold": 2000.0,
		"reached": false,
		"tier_name": "Artisan Breads",
		"unlocks": ["sourdough", "baguettes", "focaccia", "rye_bread", "multigrain_loaf"],
		"story_beat": true
	},
	"special_occasion": {
		"revenue_threshold": 5000.0,
		"reached": false,
		"tier_name": "Special Occasion Cakes",
		"unlocks": ["birthday_cake", "wedding_cupcakes", "cheesecake", "layer_cake"],
		"story_beat": true,  # Important story letter
		"special_unlock": "decorating_station"
	},
	"secret_recipes": {
		"revenue_threshold": 10000.0,
		"reached": false,
		"tier_name": "Grandma's Secret Recipes",
		"unlocks": ["grandmas_apple_pie", "secret_recipe_cookies", "family_chocolate_cake", "holiday_specialty_bread"],
		"story_beat": true,
		"special_unlock": "recipe_book_complete"
	},
	"international": {
		"revenue_threshold": 25000.0,
		"reached": false,
		"tier_name": "International Treats",
		"unlocks": ["french_macarons", "german_stollen", "italian_biscotti", "japanese_melon_pan"],
		"story_beat": true,
		"special_unlock": "bakery_expansion"
	},
	"legendary": {
		"revenue_threshold": 50000.0,
		"reached": false,
		"tier_name": "Legendary Bakes",
		"unlocks": ["legendary_signature_cake", "championship_recipe", "town_festival_winner"],
		"story_beat": true,
		"special_unlock": "game_ending"
	}
}

# Recipe unlock tracking
var unlocked_recipes: Array[String] = [
	# Starter recipes (always available from GDD)
	"white_bread",
	"chocolate_chip_cookies",
	"blueberry_muffins"
]

# Reputation modifiers
const REPUTATION_MIN: int = 0
const REPUTATION_MAX: int = 100
const REPUTATION_START: int = 50
const REPUTATION_DECAY_RATE: float = 0.5  # Points per day towards 50

func _ready() -> void:
	print("ProgressionManager initialized")
	print("Starting reputation: ", reputation)
	print("Starting recipes: ", unlocked_recipes.size())

	# Connect to EconomyManager to track revenue
	if EconomyManager:
		EconomyManager.transaction_completed.connect(_on_transaction_completed)

# Revenue tracking
func _on_transaction_completed(amount: float, description: String, is_income: bool) -> void:
	"""Track income transactions for milestone progress"""
	if is_income:
		add_revenue(amount)

func add_revenue(amount: float) -> void:
	"""Add to lifetime revenue and check for milestone unlocks"""
	if amount <= 0:
		return

	var old_revenue: float = total_lifetime_revenue
	total_lifetime_revenue += amount

	# Check if any milestones were crossed
	check_milestones(old_revenue, total_lifetime_revenue)

func check_milestones(old_revenue: float, new_revenue: float) -> void:
	"""Check if any milestones were reached with this revenue update"""
	for milestone_id in milestones:
		var milestone: Dictionary = milestones[milestone_id]
		var threshold: float = milestone["revenue_threshold"]

		# Check if we just crossed this threshold
		if old_revenue < threshold and new_revenue >= threshold:
			if not milestone["reached"]:
				unlock_milestone(milestone_id)

func unlock_milestone(milestone_id: String) -> void:
	"""Unlock a milestone and all associated content"""
	if not milestones.has(milestone_id):
		push_warning("Unknown milestone: ", milestone_id)
		return

	var milestone: Dictionary = milestones[milestone_id]
	if milestone["reached"]:
		return  # Already unlocked

	milestone["reached"] = true
	var tier_name: String = milestone["tier_name"]
	var threshold: float = milestone["revenue_threshold"]

	print("\n=== MILESTONE REACHED ===")
	print("Total Revenue: $%.2f" % total_lifetime_revenue)
	print("Unlocked: %s" % tier_name)

	# Unlock recipes
	if milestone.has("unlocks"):
		for recipe_id in milestone["unlocks"]:
			unlock_recipe(recipe_id)

	# Handle special unlocks
	if milestone.has("special_unlock"):
		print("Special unlock: %s" % milestone["special_unlock"])

	print("========================\n")

	milestone_reached.emit(milestone_id, threshold)
	tier_unlocked.emit(tier_name)

func unlock_recipe(recipe_id: String) -> void:
	"""Unlock a specific recipe"""
	if recipe_id in unlocked_recipes:
		return  # Already unlocked

	unlocked_recipes.append(recipe_id)

	# Also unlock in RecipeManager if it exists
	if RecipeManager:
		RecipeManager.unlock_recipe(recipe_id)
		var recipe_data: Dictionary = RecipeManager.get_recipe(recipe_id)
		var recipe_name: String = recipe_data.get("name", recipe_id.replace("_", " ").capitalize())
		print("Recipe unlocked: %s" % recipe_name)
		recipe_unlocked.emit(recipe_id, recipe_name)
	else:
		var recipe_name: String = recipe_id.replace("_", " ").capitalize()
		print("Recipe unlocked: %s" % recipe_name)
		recipe_unlocked.emit(recipe_id, recipe_name)

func is_recipe_unlocked(recipe_id: String) -> bool:
	"""Check if a recipe is unlocked"""
	return recipe_id in unlocked_recipes

func get_unlocked_recipes() -> Array[String]:
	"""Get list of all unlocked recipe IDs"""
	return unlocked_recipes.duplicate()

# Reputation system
func modify_reputation(amount: int) -> void:
	"""Modify reputation by amount (can be positive or negative)"""
	var old_reputation: int = reputation
	reputation = clampi(reputation + amount, REPUTATION_MIN, REPUTATION_MAX)

	if reputation != old_reputation:
		print("Reputation: %d -> %d (change: %+d)" % [old_reputation, reputation, reputation - old_reputation])
		reputation_changed.emit(reputation)

func set_reputation(value: int) -> void:
	"""Set reputation to specific value"""
	reputation = clampi(value, REPUTATION_MIN, REPUTATION_MAX)
	reputation_changed.emit(reputation)

func apply_daily_reputation_decay() -> void:
	"""Apply slow decay towards neutral (50) each day"""
	if reputation > REPUTATION_START:
		modify_reputation(-int(REPUTATION_DECAY_RATE))
	elif reputation < REPUTATION_START:
		modify_reputation(int(REPUTATION_DECAY_RATE))

func get_reputation() -> int:
	return reputation

func get_reputation_level() -> String:
	"""Get reputation level description"""
	if reputation >= 90:
		return "Legendary"
	elif reputation >= 75:
		return "Excellent"
	elif reputation >= 60:
		return "Good"
	elif reputation >= 40:
		return "Average"
	elif reputation >= 25:
		return "Poor"
	else:
		return "Terrible"

# Milestone queries
func get_next_milestone() -> Dictionary:
	"""Get the next unachieved milestone"""
	var next_milestone: Dictionary = {}
	var lowest_threshold: float = INF

	for milestone_id in milestones:
		var milestone: Dictionary = milestones[milestone_id]
		if not milestone["reached"]:
			var threshold: float = milestone["revenue_threshold"]
			if threshold < lowest_threshold:
				lowest_threshold = threshold
				next_milestone = milestone.duplicate()
				next_milestone["id"] = milestone_id

	return next_milestone

func get_progress_to_next_milestone() -> float:
	"""Get progress (0.0-1.0) to next milestone"""
	var next: Dictionary = get_next_milestone()
	if next.is_empty():
		return 1.0  # All milestones reached

	var threshold: float = next["revenue_threshold"]
	return minf(total_lifetime_revenue / threshold, 1.0)

func get_all_milestones() -> Dictionary:
	"""Get all milestone data"""
	return milestones.duplicate(true)

# Getters
func get_total_revenue() -> float:
	return total_lifetime_revenue

func get_current_day() -> int:
	return current_day

func increment_day() -> void:
	"""Called by GameManager when a new day starts"""
	current_day += 1
	apply_daily_reputation_decay()
	print("Day %d begins (Reputation: %d)" % [current_day, reputation])

# Save/Load support
func get_save_data() -> Dictionary:
	return {
		"total_lifetime_revenue": total_lifetime_revenue,
		"reputation": reputation,
		"current_day": current_day,
		"unlocked_recipes": unlocked_recipes.duplicate(),
		"milestones": milestones.duplicate(true)
	}

func load_save_data(data: Dictionary) -> void:
	if data.has("total_lifetime_revenue"):
		total_lifetime_revenue = data["total_lifetime_revenue"]
	if data.has("reputation"):
		reputation = data["reputation"]
		reputation_changed.emit(reputation)
	if data.has("current_day"):
		current_day = data["current_day"]
	if data.has("unlocked_recipes"):
		unlocked_recipes = data["unlocked_recipes"].duplicate()
	if data.has("milestones"):
		milestones = data["milestones"].duplicate(true)

	print("Progression data loaded:")
	print("  Day: %d" % current_day)
	print("  Total Revenue: $%.2f" % total_lifetime_revenue)
	print("  Reputation: %d (%s)" % [reputation, get_reputation_level()])
	print("  Unlocked Recipes: %d" % unlocked_recipes.size())
