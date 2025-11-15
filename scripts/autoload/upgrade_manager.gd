extends Node

# UpgradeManager - Manages bakery upgrades (furniture, decorations, equipment, structural)
# Handles purchase, unlocking, and visual application of upgrades

# Signals
signal upgrade_purchased(upgrade_id: String, category: String)
signal upgrade_unlocked(upgrade_id: String, category: String)

# Upgrade categories
enum UpgradeCategory {
	FURNITURE,    # Tables, chairs, shelving, counters
	DECORATION,   # Paint, wallpaper, flooring, lighting, art
	EQUIPMENT,    # Better ovens, mixers, displays, registers
	STRUCTURAL    # Wall repairs, expansions, windows, doors
}

# Purchased upgrades (saved/loaded)
var purchased_upgrades: Dictionary = {
	"furniture": [],
	"decoration": [],
	"equipment": [],
	"structural": []
}

# FURNITURE UPGRADES
const FURNITURE_UPGRADES: Dictionary = {
	# Tables
	"wooden_table": {
		"name": "Wooden Table",
		"description": "Simple wooden table for customers",
		"cost": 150.0,
		"star_requirement": 0.0,
		"category": "furniture",
		"subcategory": "tables",
		"ambiance_bonus": 2
	},
	"marble_table": {
		"name": "Marble Table",
		"description": "Elegant marble-top table",
		"cost": 450.0,
		"star_requirement": 1.5,  # Rising Reputation
		"category": "furniture",
		"subcategory": "tables",
		"ambiance_bonus": 5
	},
	"antique_table": {
		"name": "Antique Table",
		"description": "Grandma's restored antique table",
		"cost": 800.0,
		"star_requirement": 4.0,  # Grandmother's Legacy
		"category": "furniture",
		"subcategory": "tables",
		"ambiance_bonus": 10
	},

	# Chairs
	"wooden_chair": {
		"name": "Wooden Chair",
		"description": "Comfortable wooden chair",
		"cost": 75.0,
		"star_requirement": 0.0,
		"category": "furniture",
		"subcategory": "chairs",
		"ambiance_bonus": 1
	},
	"cushioned_chair": {
		"name": "Cushioned Chair",
		"description": "Chair with soft cushions",
		"cost": 150.0,
		"star_requirement": 1.0,  # First Customers
		"category": "furniture",
		"subcategory": "chairs",
		"ambiance_bonus": 3
	},
	"luxury_chair": {
		"name": "Luxury Chair",
		"description": "Premium upholstered chair",
		"cost": 300.0,
		"star_requirement": 2.5,  # Profitable Day
		"category": "furniture",
		"subcategory": "chairs",
		"ambiance_bonus": 6
	},

	# Shelving
	"basic_shelf": {
		"name": "Basic Shelf",
		"description": "Simple wall shelf for display",
		"cost": 100.0,
		"star_requirement": 0.0,
		"category": "furniture",
		"subcategory": "shelving",
		"ambiance_bonus": 2
	},
	"glass_shelf": {
		"name": "Glass Display Shelf",
		"description": "Glass shelf with LED lighting",
		"cost": 350.0,
		"star_requirement": 1.5,  # Rising Reputation
		"category": "furniture",
		"subcategory": "shelving",
		"ambiance_bonus": 5
	},
	"trophy_case": {
		"name": "Trophy Display Case",
		"description": "Showcase your achievements",
		"cost": 600.0,
		"star_requirement": 4.0,  # Grandmother's Legacy
		"category": "furniture",
		"subcategory": "shelving",
		"ambiance_bonus": 8
	},

	# Counters
	"basic_counter": {
		"name": "Basic Counter",
		"description": "Standard service counter",
		"cost": 200.0,
		"star_requirement": 0.0,
		"category": "furniture",
		"subcategory": "counters",
		"ambiance_bonus": 2
	},
	"granite_counter": {
		"name": "Granite Counter",
		"description": "Premium granite countertop",
		"cost": 500.0,
		"star_requirement": 2.5,  # Profitable Day
		"category": "furniture",
		"subcategory": "counters",
		"ambiance_bonus": 6
	}
}

# DECORATION UPGRADES
const DECORATION_UPGRADES: Dictionary = {
	# Paint
	"fresh_paint_white": {
		"name": "Fresh White Paint",
		"description": "Clean, bright white walls",
		"cost": 200.0,
		"star_requirement": 0.0,
		"category": "decoration",
		"subcategory": "paint",
		"ambiance_bonus": 5,
		"color": Color(0.95, 0.95, 0.95)
	},
	"warm_cream_paint": {
		"name": "Warm Cream Paint",
		"description": "Cozy cream-colored walls",
		"cost": 250.0,
		"star_requirement": 1.0,  # First Customers
		"category": "decoration",
		"subcategory": "paint",
		"ambiance_bonus": 8,
		"color": Color(0.96, 0.92, 0.84)
	},
	"sage_green_paint": {
		"name": "Sage Green Paint",
		"description": "Calming sage green walls",
		"cost": 300.0,
		"star_requirement": 2.5,  # Profitable Day
		"category": "decoration",
		"subcategory": "paint",
		"ambiance_bonus": 10,
		"color": Color(0.7, 0.8, 0.7)
	},

	# Wallpaper
	"floral_wallpaper": {
		"name": "Floral Wallpaper",
		"description": "Vintage floral pattern",
		"cost": 400.0,
		"star_requirement": 1.5,  # Rising Reputation
		"category": "decoration",
		"subcategory": "wallpaper",
		"ambiance_bonus": 12
	},
	"grandmas_wallpaper": {
		"name": "Grandma's Wallpaper",
		"description": "Restore the original wallpaper",
		"cost": 600.0,
		"star_requirement": 4.0,  # Grandmother's Legacy
		"category": "decoration",
		"subcategory": "wallpaper",
		"ambiance_bonus": 20
	},

	# Flooring
	"tile_flooring": {
		"name": "Tile Flooring",
		"description": "Classic ceramic tiles",
		"cost": 500.0,
		"unlock_revenue": 0,
		"category": "decoration",
		"subcategory": "flooring",
		"ambiance_bonus": 5,
		"color": Color(0.8, 0.8, 0.8)
	},
	"hardwood_flooring": {
		"name": "Hardwood Flooring",
		"description": "Beautiful hardwood planks",
		"cost": 1000.0,
		"star_requirement": 2.5,  # Profitable Day
		"category": "decoration",
		"subcategory": "flooring",
		"ambiance_bonus": 12,
		"color": Color(0.6, 0.4, 0.2)
	},
	"vintage_checkerboard": {
		"name": "Vintage Checkerboard",
		"description": "Classic black & white pattern",
		"cost": 800.0,
		"star_requirement": 4.0,  # Grandmother's Legacy
		"category": "decoration",
		"subcategory": "flooring",
		"ambiance_bonus": 15
	},

	# Lighting
	"warm_lighting": {
		"name": "Warm Lighting",
		"description": "Cozy warm-toned lights",
		"cost": 300.0,
		"star_requirement": 1.0,  # First Customers
		"category": "decoration",
		"subcategory": "lighting",
		"ambiance_bonus": 8
	},
	"chandelier": {
		"name": "Crystal Chandelier",
		"description": "Elegant crystal chandelier",
		"cost": 1200.0,
		"star_requirement": 4.0,  # Grandmother's Legacy
		"category": "decoration",
		"subcategory": "lighting",
		"ambiance_bonus": 20
	},

	# Art & Decor
	"family_photos": {
		"name": "Family Photos",
		"description": "Frame family memories",
		"cost": 150.0,
		"star_requirement": 0.5,  # First Steps
		"category": "decoration",
		"subcategory": "art",
		"ambiance_bonus": 5
	},
	"baking_poster": {
		"name": "Vintage Baking Poster",
		"description": "Classic bakery advertisement",
		"cost": 200.0,
		"star_requirement": 1.5,  # Rising Reputation
		"category": "decoration",
		"subcategory": "art",
		"ambiance_bonus": 6
	},
	"oil_painting": {
		"name": "Oil Painting",
		"description": "Beautiful countryside painting",
		"cost": 800.0,
		"star_requirement": 4.0,  # Grandmother's Legacy
		"category": "decoration",
		"subcategory": "art",
		"ambiance_bonus": 12
	},

	# Plants
	"potted_plant": {
		"name": "Potted Plant",
		"description": "Small decorative plant",
		"cost": 50.0,
		"star_requirement": 0.0,
		"category": "decoration",
		"subcategory": "plants",
		"ambiance_bonus": 3
	},
	"flower_vase": {
		"name": "Fresh Flowers",
		"description": "Vase with fresh cut flowers",
		"cost": 100.0,
		"star_requirement": 1.0,  # First Customers
		"category": "decoration",
		"subcategory": "plants",
		"ambiance_bonus": 5
	}
}

# EQUIPMENT UPGRADES
const EQUIPMENT_UPGRADES: Dictionary = {
	# Ovens
	"oven_tier_1": {
		"name": "Professional Oven",
		"description": "Commercial-grade oven (+2% quality)",
		"cost": 2000.0,
		"star_requirement": 1.5,  # Rising Reputation task
		"category": "equipment",
		"subcategory": "oven",
		"equipment_tier": 1
	},
	"oven_tier_2": {
		"name": "Convection Oven",
		"description": "Advanced convection oven (+4% quality)",
		"cost": 5000.0,
		"star_requirement": 3.0,  # Team Player task
		"category": "equipment",
		"subcategory": "oven",
		"equipment_tier": 2
	},
	"oven_tier_3": {
		"name": "Master Baker's Oven",
		"description": "Top-of-the-line oven (+6% quality)",
		"cost": 10000.0,
		"star_requirement": 3.5,  # Perfectionist task
		"category": "equipment",
		"subcategory": "oven",
		"equipment_tier": 3
	},

	# Mixers
	"mixer_tier_1": {
		"name": "Stand Mixer",
		"description": "Professional stand mixer (+2% quality)",
		"cost": 1500.0,
		"star_requirement": 1.5,  # Rising Reputation task
		"category": "equipment",
		"subcategory": "mixer",
		"equipment_tier": 1
	},
	"mixer_tier_2": {
		"name": "Industrial Mixer",
		"description": "Heavy-duty industrial mixer (+4% quality)",
		"cost": 4000.0,
		"star_requirement": 3.0,  # Team Player task
		"category": "equipment",
		"subcategory": "mixer",
		"equipment_tier": 2
	},
	"mixer_tier_3": {
		"name": "Master Mixer",
		"description": "Grandma's restored professional mixer (+6% quality)",
		"cost": 8000.0,
		"star_requirement": 4.0,  # Grandmother's Legacy task
		"category": "equipment",
		"subcategory": "mixer",
		"equipment_tier": 3
	},

	# Display Case
	"display_tier_1": {
		"name": "Refrigerated Display",
		"description": "Temperature-controlled display case",
		"cost": 1000.0,
		"star_requirement": 2.0,  # Baking Variety task
		"category": "equipment",
		"subcategory": "display",
		"capacity_bonus": 5
	},
	"display_tier_2": {
		"name": "Premium Display",
		"description": "Large multi-shelf display (+10 capacity)",
		"cost": 2500.0,
		"star_requirement": 3.5,  # Perfectionist task
		"category": "equipment",
		"subcategory": "display",
		"capacity_bonus": 10
	},

	# Register
	"register_tier_1": {
		"name": "Digital Register",
		"description": "Faster checkout (20% speed boost)",
		"cost": 800.0,
		"star_requirement": 1.5,  # Rising Reputation task
		"category": "equipment",
		"subcategory": "register",
		"speed_bonus": 0.2
	}
}

# STRUCTURAL UPGRADES
const STRUCTURAL_UPGRADES: Dictionary = {
	# Repairs
	"wall_repair": {
		"name": "Wall Repairs",
		"description": "Fix cracks and damage",
		"cost": 500.0,
		"star_requirement": 0.0,
		"category": "structural",
		"subcategory": "repairs",
		"ambiance_bonus": 10
	},
	"ceiling_repair": {
		"name": "Ceiling Repairs",
		"description": "Fix water stains and cracks",
		"cost": 600.0,
		"star_requirement": 1.0,  # First Customers
		"category": "structural",
		"subcategory": "repairs",
		"ambiance_bonus": 8
	},

	# Windows
	"new_windows": {
		"name": "New Windows",
		"description": "Replace old drafty windows",
		"cost": 1500.0,
		"star_requirement": 2.5,  # Profitable Day
		"category": "structural",
		"subcategory": "windows",
		"ambiance_bonus": 15
	},
	"bay_window": {
		"name": "Bay Window",
		"description": "Beautiful bay window with seating",
		"cost": 3000.0,
		"star_requirement": 4.0,  # Grandmother's Legacy
		"category": "structural",
		"subcategory": "windows",
		"ambiance_bonus": 25
	},

	# Expansion
	"seating_expansion": {
		"name": "Seating Area Expansion",
		"description": "Add more customer seating space",
		"cost": 5000.0,
		"star_requirement": 4.0,  # Grandmother's Legacy
		"category": "structural",
		"subcategory": "expansion",
		"customer_capacity": 5
	},
	"kitchen_expansion": {
		"name": "Kitchen Expansion",
		"description": "Expand work area for more equipment",
		"cost": 10000.0,
		"star_requirement": 5.0,  # Master Baker
		"category": "structural",
		"subcategory": "expansion",
		"equipment_slots": 2
	}
}

func _ready() -> void:
	print("UpgradeManager initialized")
	print("  - %d furniture upgrades available" % FURNITURE_UPGRADES.size())
	print("  - %d decoration upgrades available" % DECORATION_UPGRADES.size())
	print("  - %d equipment upgrades available" % EQUIPMENT_UPGRADES.size())
	print("  - %d structural upgrades available" % STRUCTURAL_UPGRADES.size())

# Get all upgrades in a category
func get_upgrades_by_category(category: String) -> Dictionary:
	match category:
		"furniture":
			return FURNITURE_UPGRADES
		"decoration":
			return DECORATION_UPGRADES
		"equipment":
			return EQUIPMENT_UPGRADES
		"structural":
			return STRUCTURAL_UPGRADES
	return {}

# Get specific upgrade data
func get_upgrade(upgrade_id: String) -> Dictionary:
	# Search all categories
	for category in ["furniture", "decoration", "equipment", "structural"]:
		var upgrades = get_upgrades_by_category(category)
		if upgrades.has(upgrade_id):
			return upgrades[upgrade_id]
	return {}

# Check if upgrade is unlocked (based on star rating ONLY)
func is_upgrade_unlocked(upgrade_id: String) -> bool:
	var upgrade = get_upgrade(upgrade_id)
	if upgrade.is_empty():
		return false

	# Check star requirement (if specified, otherwise unlocked by default)
	var required_stars: float = upgrade.get("star_requirement", 0.0)
	var current_stars: float = TaskManager.get_star_rating() if TaskManager else 0.0
	var stars_met = current_stars >= required_stars

	return stars_met

# Check if upgrade is purchased
func is_upgrade_purchased(upgrade_id: String) -> bool:
	for category in purchased_upgrades.keys():
		if upgrade_id in purchased_upgrades[category]:
			return true
	return false

# Purchase an upgrade
func purchase_upgrade(upgrade_id: String) -> bool:
	var upgrade = get_upgrade(upgrade_id)
	if upgrade.is_empty():
		print("Error: Upgrade '%s' not found" % upgrade_id)
		return false

	# Check if already purchased
	if is_upgrade_purchased(upgrade_id):
		print("Already purchased: %s" % upgrade.get("name", upgrade_id))
		return false

	# Check if unlocked
	if not is_upgrade_unlocked(upgrade_id):
		var required_stars: float = upgrade.get("star_requirement", 0.0)
		if required_stars > 0.0:
			print("Upgrade locked: Need %.1f stars" % required_stars)
		else:
			print("Upgrade locked")
		return false

	# Check if can afford
	var cost: float = upgrade.get("cost", 0)
	if not EconomyManager.can_afford(cost):
		print("Cannot afford: %s (costs $%.2f)" % [upgrade.get("name", upgrade_id), cost])
		return false

	# Purchase!
	EconomyManager.spend(cost)

	# Add to purchased list
	var category: String = upgrade.get("category", "furniture")
	if not purchased_upgrades.has(category):
		purchased_upgrades[category] = []
	purchased_upgrades[category].append(upgrade_id)

	# Apply upgrade effects
	apply_upgrade_effects(upgrade_id, upgrade)

	print("Purchased: %s for $%.2f" % [upgrade.get("name", upgrade_id), cost])
	upgrade_purchased.emit(upgrade_id, category)

	return true

# Apply upgrade effects to game systems
func apply_upgrade_effects(upgrade_id: String, upgrade: Dictionary) -> void:
	var category: String = upgrade.get("category", "")

	# Ambiance bonus (affects customer satisfaction)
	if upgrade.has("ambiance_bonus"):
		var bonus: int = upgrade.ambiance_bonus
		print("  + Ambiance bonus: +%d" % bonus)
		# TODO: Apply to ambiance system when implemented

	# Equipment tier (affects quality)
	if upgrade.has("equipment_tier"):
		var tier: int = upgrade.equipment_tier
		var subcategory: String = upgrade.get("subcategory", "")
		print("  + Equipment tier: %d (%s)" % [tier, subcategory])
		# Equipment tier is applied when scene loads based on purchased upgrades

	# Capacity bonus
	if upgrade.has("capacity_bonus"):
		print("  + Capacity bonus: +%d" % upgrade.capacity_bonus)

	# Speed bonus
	if upgrade.has("speed_bonus"):
		print("  + Speed bonus: +%.0f%%" % (upgrade.speed_bonus * 100))

	# Customer capacity
	if upgrade.has("customer_capacity"):
		print("  + Customer capacity: +%d" % upgrade.customer_capacity)

	# Equipment slots
	if upgrade.has("equipment_slots"):
		print("  + Equipment slots: +%d" % upgrade.equipment_slots)

# Get highest tier equipment purchased for a type
func get_equipment_tier(equipment_type: String) -> int:
	"""Returns the highest tier equipment purchased for a type (oven, mixer, etc.)"""
	var highest_tier: int = 0

	for upgrade_id in purchased_upgrades.get("equipment", []):
		var upgrade = get_upgrade(upgrade_id)
		if upgrade.get("subcategory", "") == equipment_type:
			var tier: int = upgrade.get("equipment_tier", 0)
			if tier > highest_tier:
				highest_tier = tier

	return highest_tier

# Get total ambiance from all purchased upgrades
func get_total_ambiance() -> int:
	var total: int = 0

	for category in purchased_upgrades.keys():
		for upgrade_id in purchased_upgrades[category]:
			var upgrade = get_upgrade(upgrade_id)
			total += upgrade.get("ambiance_bonus", 0)

	return total

# Get available upgrades (unlocked but not purchased)
func get_available_upgrades(category: String = "") -> Array:
	var available: Array = []
	var upgrades: Dictionary = {}

	if category.is_empty():
		# Get all upgrades from all categories
		for cat in ["furniture", "decoration", "equipment", "structural"]:
			upgrades.merge(get_upgrades_by_category(cat))
	else:
		upgrades = get_upgrades_by_category(category)

	for upgrade_id in upgrades.keys():
		if is_upgrade_unlocked(upgrade_id) and not is_upgrade_purchased(upgrade_id):
			available.append(upgrade_id)

	return available

# Save/Load
func get_save_data() -> Dictionary:
	return {
		"purchased_upgrades": purchased_upgrades
	}

func load_save_data(data: Dictionary) -> void:
	if data.has("purchased_upgrades"):
		purchased_upgrades = data.purchased_upgrades
		print("Loaded %d purchased upgrades" % get_total_purchased_count())

		# Reapply all upgrade effects
		for category in purchased_upgrades.keys():
			for upgrade_id in purchased_upgrades[category]:
				var upgrade = get_upgrade(upgrade_id)
				if not upgrade.is_empty():
					apply_upgrade_effects(upgrade_id, upgrade)

func get_total_purchased_count() -> int:
	var count: int = 0
	for category in purchased_upgrades.keys():
		count += purchased_upgrades[category].size()
	return count

func reset() -> void:
	"""Reset all purchased upgrades (for new game)"""
	purchased_upgrades = {
		"furniture": [],
		"decoration": [],
		"equipment": [],
		"structural": []
	}
	print("UpgradeManager reset")
