extends Node

## =============================================================================
## BALANCE CONFIGURATION
## =============================================================================
## Centralized balance configuration for My Grandma's Legacy
##
## This file contains ALL tweakable balance parameters in one place.
## Modify values here to adjust game balance without touching individual systems.
##
## USAGE: BalanceConfig.CATEGORY.parameter_name
## Example: BalanceConfig.TIME.seconds_per_game_hour
## =============================================================================

## =============================================================================
## TIME PARAMETERS
## =============================================================================
const TIME = {
	# Day/Night Cycle
	"seconds_per_game_hour": 60.0,      # 1 game hour = 60 real seconds at 1x speed
	"business_start_hour": 9,            # Business opens at 9 AM
	"business_end_hour": 17,             # Business closes at 5 PM (8 hour day)
	"max_time_scale": 3.0,               # Maximum speed multiplier (1x, 2x, 3x)
	"cleanup_auto_delay": 2.0,           # Auto-complete cleanup after X seconds

	# Calculated: Business day = 8 hours × 60 seconds = 480 real seconds at 1x
	# At 1x speed: 8 real minutes per day
	# At 3x speed: ~2.7 real minutes per day
}

## =============================================================================
## ECONOMY PARAMETERS
## =============================================================================
const ECONOMY = {
	# Starting Resources
	"starting_cash": 200.0,              # Player starts with $200

	# Ingredient Prices (per unit)
	"ingredient_prices": {
		"flour": 1.0,
		"sugar": 0.50,
		"eggs": 0.10,
		"butter": 0.75,
		"milk": 0.75,
		"yeast": 0.50,
		"chocolate_chips": 0.25,
		"blueberries": 0.50,
		"vanilla": 1.0,
		"salt": 0.25,
		"water": 0.0,                    # Free resource
		"cinnamon": 3.5,
		"cocoa_powder": 3.0,
		"cream_cheese": 4.0,
		"lemon": 2.0,
		"almonds": 5.0,
		"honey": 4.0,
		"strawberries": 4.0,
		"raspberries": 5.0,
		"apples": 1.0,
		"pecans": 4.0,
		"walnuts": 5.0,
		"cranberries": 5.0,
		"pumpkin": 4.0,
		"ginger": 2.0,
		"nutmeg": 1.0,
		"cardamom": 1.0,
		"baking_powder": 2.0,
		"baking_soda": 1.5,
		"brown_sugar": 3.5,
		"powdered_sugar": 4.0,
		"heavy_cream": 3.0,
		"sour_cream": 2.0,
		"raisins": 3.0,
		"coconut": 4.0,
		"peanut_butter": 2.0,
		"maple_syrup": 3.0,
		"orange": 2.5,
		"cherry": 4.0,
		"matcha": 10.0,
		"espresso": 3.0,
		"cheese": 4.0,
		"olive_oil": 5.0,
		"herbs": 2.0,
	}
}

## =============================================================================
## RECIPE PARAMETERS
## =============================================================================
const RECIPES = {
	# Recipe Timing Adjustments
	"mixing_time_multiplier": 0.1,       # Global multiplier for all mixing times
	"baking_time_multiplier": 0.1,       # Global multiplier for all baking times

	# Recipe Price Adjustments (multiplied with base prices)
	"price_multiplier_global": 1.0,      # Global price multiplier for ALL recipes
	"price_multiplier_starter": 1.0,     # Additional multiplier for starter recipes
	"price_multiplier_basic": 1.0,       # Additional multiplier for basic pastries
	"price_multiplier_artisan": 1.0,     # Additional multiplier for artisan breads
	"price_multiplier_special": 1.0,     # Additional multiplier for special occasion
	"price_multiplier_secret": 1.0,      # Additional multiplier for grandma's recipes
	"price_multiplier_international": 1.0, # Additional multiplier for international
	"price_multiplier_legendary": 1.0,   # Additional multiplier for legendary bakes

	# Individual Recipe Adjustments (base values)
	# Note: These are the BASE values. Individual recipes multiply by these.
	"recipes": {
		# STARTER RECIPES
		"white_bread": {
			"mixing_time": 60.0,
			"baking_time": 300.0,
			"base_price": 10.0,
		},
		"chocolate_chip_cookies": {
			"mixing_time": 45.0,
			"baking_time": 180.0,
			"base_price": 7.0,         # NOTE: Unprofitable at current ingredient costs!
		},
		"blueberry_muffins": {
			"mixing_time": 50.0,
			"baking_time": 240.0,
			"base_price": 10.0,         # NOTE: Unprofitable at current ingredient costs!
		},

		# BASIC PASTRIES ($500 unlock)
		"croissants": {
			"mixing_time": 90.0,
			"baking_time": 360.0,
			"base_price": 25.0,
		},
		"danish_pastries": {
			"mixing_time": 75.0,
			"baking_time": 300.0,
			"base_price": 22.0,
		},
		"scones": {
			"mixing_time": 40.0,
			"baking_time": 240.0,
			"base_price": 18.0,
		},
		"cinnamon_rolls": {
			"mixing_time": 80.0,
			"baking_time": 420.0,
			"base_price": 28.0,
		},

		# ARTISAN BREADS ($2,000 unlock)
		"sourdough": {
			"mixing_time": 120.0,
			"baking_time": 600.0,
			"base_price": 35.0,
		},
		"baguettes": {
			"mixing_time": 70.0,
			"baking_time": 420.0,
			"base_price": 20.0,
		},
		"focaccia": {
			"mixing_time": 65.0,
			"baking_time": 360.0,
			"base_price": 24.0,
		},
		"rye_bread": {
			"mixing_time": 80.0,
			"baking_time": 480.0,
			"base_price": 26.0,
		},
		"multigrain_loaf": {
			"mixing_time": 75.0,
			"baking_time": 540.0,
			"base_price": 30.0,
		},

		# SPECIAL OCCASION CAKES ($5,000 unlock)
		"birthday_cake": {
			"mixing_time": 100.0,
			"baking_time": 720.0,
			"base_price": 60.0,
		},
		"wedding_cupcakes": {
			"mixing_time": 90.0,
			"baking_time": 480.0,
			"base_price": 55.0,
		},
		"cheesecake": {
			"mixing_time": 85.0,
			"baking_time": 900.0,
			"base_price": 50.0,
		},
		"layer_cake": {
			"mixing_time": 110.0,
			"baking_time": 780.0,
			"base_price": 65.0,
		},

		# GRANDMA'S SECRET RECIPES ($10,000 unlock)
		"grandmothers_apple_pie": {
			"mixing_time": 120.0,
			"baking_time": 840.0,
			"base_price": 75.0,
		},
		"secret_recipe_cookies": {
			"mixing_time": 95.0,
			"baking_time": 360.0,
			"base_price": 45.0,
		},
		"family_chocolate_cake": {
			"mixing_time": 105.0,
			"baking_time": 720.0,
			"base_price": 70.0,
		},
		"holiday_specialty_bread": {
			"mixing_time": 100.0,
			"baking_time": 660.0,
			"base_price": 55.0,
		},

		# INTERNATIONAL TREATS ($25,000 unlock)
		"french_macarons": {
			"mixing_time": 150.0,
			"baking_time": 540.0,
			"base_price": 80.0,
		},
		"german_stollen": {
			"mixing_time": 130.0,
			"baking_time": 720.0,
			"base_price": 85.0,
		},
		"italian_biscotti": {
			"mixing_time": 80.0,
			"baking_time": 600.0,
			"base_price": 40.0,
		},
		"japanese_melon_pan": {
			"mixing_time": 110.0,
			"baking_time": 480.0,
			"base_price": 35.0,
		},

		# LEGENDARY BAKES ($50,000 unlock)
		"grandmothers_legendary_cake": {
			"mixing_time": 180.0,
			"baking_time": 1200.0,    # 20 minutes! Longer than business day!
			"base_price": 150.0,
		},
		"championship_recipe": {
			"mixing_time": 160.0,
			"baking_time": 960.0,
			"base_price": 125.0,
		},
		"town_festival_winner": {
			"mixing_time": 140.0,
			"baking_time": 840.0,
			"base_price": 110.0,
		},
	}
}

## =============================================================================
## PROGRESSION PARAMETERS
## =============================================================================
const PROGRESSION = {
	# Milestone Revenue Thresholds
	"milestone_basic_pastries": 500.0,
	"milestone_artisan_breads": 2000.0,
	"milestone_special_occasion": 5000.0,
	"milestone_secret_recipes": 10000.0,
	"milestone_international": 25000.0,
	"milestone_legendary": 50000.0,

	# Reputation System
	"reputation_min": 0,
	"reputation_max": 100,
	"reputation_start": 50,
	"reputation_decay_rate": 0.5,        # Points per day drift toward 50

	# Reputation changes from customer satisfaction
	"rep_excellent": 3,                  # 90%+ satisfaction
	"rep_very_good": 2,                  # 75-89%
	"rep_good": 1,                       # 60-74%
	"rep_neutral": 0,                    # 50-59%
	"rep_below_avg": -1,                 # 40-49%
	"rep_poor": -2,                      # 25-39%
	"rep_terrible": -3,                  # <25%
}

## =============================================================================
## CUSTOMER PARAMETERS
## =============================================================================
const CUSTOMERS = {
	# Traffic & Spawning
	"base_customers_per_hour": 2.0,      # At 50 reputation (30 seconds average)
	"spawn_interval_base": 10.0,         # Base spawn interval in seconds
	"spawn_interval_min": 3.0,           # Minimum spawn interval (busy times)
	"spawn_interval_max": 120.0,         # Maximum spawn interval (slow times)
	"spawn_interval_variance": 0.3,      # ±30% randomization for realistic timing

	# Reputation Traffic Multipliers
	"traffic_at_rep_0": 0.1,             # -90% customers at 0 rep
	"traffic_at_rep_50": 1.0,            # Baseline at 50 rep
	"traffic_at_rep_75": 1.5,            # +50% at 75 rep
	"traffic_at_rep_100": 2.5,           # +150% at 100 rep

	# Day of Week Traffic Multipliers
	"traffic_weekday": 1.0,              # Mon-Thu
	"traffic_friday": 1.3,               # End of week boost
	"traffic_saturday": 1.5,             # Busiest day
	"traffic_sunday": 1.2,               # Brunch crowd

	# Customer Behavior
	"patience_start": 100.0,             # Starting patience (0-100)
	"patience_drain_rate": 5.0,          # Patience lost per second waiting
	"max_browse_time": 5.0,              # Seconds to browse display case
	"satisfaction_start": 50.0,          # Starting satisfaction score

	# Satisfaction Modifiers
	"satisfaction_patience_good": 20,    # Bonus if patience > 50
	"satisfaction_multi_items": 10,      # Bonus if bought 2+ items
	"satisfaction_patience_bad": -20,    # Penalty if patience < 30
	"satisfaction_no_items": -30,        # Penalty if couldn't buy anything

	# Mood Thresholds (based on patience)
	"mood_happy_threshold": 60,          # > 60 patience = happy
	"mood_unhappy_threshold": 30,        # < 30 patience = unhappy

	# Final Mood (based on satisfaction)
	"mood_final_happy": 70,              # 70%+ satisfaction = happy
	"mood_final_unhappy": 40,            # <40% satisfaction = unhappy

	# Movement
	"customer_move_speed": 3.0,
	"customer_rotation_speed": 10.0,

	# Customer Types (GDD Section 4.2.1)
	"customer_type_regular_weight": 0.3,     # 30% after unlocked
	"customer_type_tourist_weight": 0.25,    # 25%
	"customer_type_local_weight": 0.45,      # 45% (default type)
	"customer_type_regular_unlock": 5,       # Unlock after 5 happy visits from same customer

	# Price Tolerance (GDD Section 4.2.4, Lines 278-286)
	"price_tolerance_base_min": 0.8,         # Customers accept 80% to 150% of base price
	"price_tolerance_base_max": 1.5,

	# Customer Type Price Tolerance Modifiers
	"regular_price_min": 0.7,                # Regulars: More forgiving (70%-160%)
	"regular_price_max": 1.6,
	"tourist_price_min": 0.9,                # Tourists: Less price-sensitive (90%-180%)
	"tourist_price_max": 1.8,
	"local_price_min": 0.75,                 # Locals: Price-conscious (75%-130%)
	"local_price_max": 1.3,

	# Quality affects price tolerance
	"quality_excellent_price_bonus": 0.2,    # +20% tolerance for excellent quality
	"quality_perfect_price_bonus": 0.3,      # +30% tolerance for perfect quality
	"quality_poor_price_penalty": 0.15,      # -15% tolerance for poor quality

	# Reputation affects price tolerance
	"reputation_high_price_bonus": 0.1,      # +10% tolerance at 75+ reputation
	"reputation_low_price_penalty": 0.1,     # -10% tolerance at <30 reputation
}

## =============================================================================
## QUALITY PARAMETERS
## =============================================================================
const QUALITY = {
	# Quality Tier Price Multipliers
	"quality_poor_multiplier": 0.7,      # 50-69% quality: -30% price
	"quality_normal_multiplier": 1.0,    # 70-89% quality: base price
	"quality_good_multiplier": 1.2,      # 90-94% quality: +20% price
	"quality_excellent_multiplier": 1.5, # 95-99% quality: +50% price
	"quality_perfect_multiplier": 2.0,   # 100% quality: +100% price
	"quality_legendary_multiplier": 1.5, # Additional 1.5x on perfect items (5% chance)

	# Quality Tier Ranges
	"quality_poor_min": 50,
	"quality_poor_max": 69,
	"quality_normal_min": 70,
	"quality_normal_max": 89,
	"quality_good_min": 90,
	"quality_good_max": 94,
	"quality_excellent_min": 95,
	"quality_excellent_max": 99,
	"quality_perfect": 100,

	# Quality Calculation
	"equipment_bonus_per_tier": 2.0,     # +2% quality per equipment tier
	"random_variance": 5.0,              # ±5% random variance
	"legendary_chance": 0.05,            # 5% chance for legendary on perfect items

	# Timing Quality Thresholds
	"timing_perfect_threshold": 0.05,    # Within 5% = 100% quality
	"timing_good_threshold": 0.10,       # Within 10% = 95% quality
	"timing_acceptable_threshold": 0.20, # Within 20% = 85% quality
	"timing_poor_threshold": 0.30,       # Within 30% = 75% quality
	# Over 30% off = 60% quality

	"timing_perfect_quality": 100,
	"timing_good_quality": 95,
	"timing_acceptable_quality": 85,
	"timing_poor_quality": 75,
	"timing_failed_quality": 60,
}

## =============================================================================
## EQUIPMENT & UPGRADES
## =============================================================================
const EQUIPMENT = {
	# Base Equipment Times
	"mixing_bowl_base_time": 60.0,
	"oven_base_time": 300.0,
	"cooling_rack_base_time": 45.0,
	"cooling_rack_max_slots": 6,
	"cooling_rack_rush_penalty": 30.0,  # Quality penalty (%) if removed too early
	"decorating_station_base_time": 90.0,
	"decorating_station_value_multiplier": 1.3,  # 30% price increase

	# Oven Cooking States (percentage of target baking time)
	# These define when items transition between cooking states
	"oven_undercooked_end": 0.85,        # Undercooked until 85% of baking time
	"oven_cooked_start": 0.85,           # Cooked window starts at 85%
	"oven_cooked_optimal_start": 0.95,   # Optimal cooking starts at 95% (best quality)
	"oven_cooked_optimal_end": 1.05,     # Optimal cooking ends at 105%
	"oven_cooked_end": 1.25,             # Cooked window ends at 125% (generous!)
	"oven_burnt_start": 1.25,            # Burnt after 125% of baking time
	"oven_warning_time": 1.15,           # Show warning at 115% (10% before burning)

	# Cooking State Quality Modifiers
	"oven_undercooked_quality_max": 65,  # Max 65% quality if undercooked
	"oven_burnt_quality_max": 50,        # Max 50% quality if burnt
	"oven_cooked_quality_bonus": 5,      # +5% quality bonus in optimal window
	"oven_perfection_chance_bonus": 0.10, # +10% legendary chance in optimal window

	# Equipment Upgrade Costs
	"oven_tier_1_cost": 2000.0,
	"oven_tier_1_unlock": 2000.0,
	"oven_tier_2_cost": 5000.0,
	"oven_tier_2_unlock": 10000.0,
	"oven_tier_3_cost": 10000.0,
	"oven_tier_3_unlock": 25000.0,

	"mixer_tier_1_cost": 1500.0,
	"mixer_tier_1_unlock": 2000.0,
	"mixer_tier_2_cost": 4000.0,
	"mixer_tier_2_unlock": 10000.0,
	"mixer_tier_3_cost": 8000.0,
	"mixer_tier_3_unlock": 25000.0,

	"display_tier_1_cost": 1000.0,
	"display_tier_1_unlock": 1000.0,
	"display_tier_1_capacity": 5,
	"display_tier_2_cost": 2500.0,
	"display_tier_2_unlock": 5000.0,
	"display_tier_2_capacity": 10,

	"register_tier_1_cost": 800.0,
	"register_tier_1_unlock": 2000.0,
	"register_tier_1_speed": 0.2,        # 20% faster transactions

	# Furniture Costs (sample - many more exist)
	"wooden_table_cost": 150.0,
	"wooden_table_ambiance": 2,
	"marble_table_cost": 450.0,
	"marble_table_unlock": 2000.0,
	"marble_table_ambiance": 5,
	"antique_table_cost": 800.0,
	"antique_table_unlock": 10000.0,
	"antique_table_ambiance": 10,

	# Decoration Costs (sample)
	"fresh_paint_white_cost": 200.0,
	"fresh_paint_white_ambiance": 5,
	"warm_cream_paint_cost": 250.0,
	"warm_cream_paint_unlock": 1000.0,
	"warm_cream_paint_ambiance": 8,

	# Structural Upgrades
	"wall_repair_cost": 500.0,
	"wall_repair_ambiance": 10,
	"seating_expansion_cost": 5000.0,
	"seating_expansion_unlock": 10000.0,
	"seating_expansion_capacity": 5,
	"kitchen_expansion_cost": 10000.0,
	"kitchen_expansion_unlock": 25000.0,
	"kitchen_expansion_slots": 2,

	# Cooling Rack
	"cooling_rack_tier_1_cost": 500.0,
	"cooling_rack_tier_1_unlock": 500.0,
	"cooling_rack_tier_2_cost": 1200.0,
	"cooling_rack_tier_2_unlock": 5000.0,
	"cooling_rack_tier_2_slots": 10,  # Upgraded capacity

	# Decorating Station (unlocks at $10,000)
	"decorating_station_cost": 1500.0,
	"decorating_station_unlock": 10000.0,
	"decorating_station_quality_bonus": 5,  # +5% quality
}

## =============================================================================
## CLEANLINESS PARAMETERS
## =============================================================================
const CLEANLINESS = {
	# Cleanliness System
	"start_cleanliness": 100.0,
	"daily_decay": 15.0,                 # Base decay per day
	"incomplete_chore_penalty": 5.0,     # Per incomplete chore

	# Chore Values (how much they improve cleanliness)
	"chore_dishes": 15.0,
	"chore_floor": 20.0,
	"chore_counters": 15.0,
	"chore_trash": 10.0,
	"chore_equipment": 10.0,

	# Cleanliness Tier Thresholds
	"tier_spotless_min": 90,
	"tier_clean_min": 70,
	"tier_acceptable_min": 50,
	"tier_dirty_min": 30,
	# < 30 = very dirty

	# Cleanliness Effect Multipliers
	"spotless_satisfaction": 1.2,        # +20% satisfaction
	"spotless_traffic": 1.1,             # +10% traffic
	"clean_satisfaction": 1.0,           # Baseline
	"clean_traffic": 1.0,                # Baseline
	"acceptable_satisfaction": 0.9,      # -10% satisfaction
	"acceptable_traffic": 0.95,          # -5% traffic
	"dirty_satisfaction": 0.7,           # -30% satisfaction
	"dirty_traffic": 0.75,               # -25% traffic
	"very_dirty_satisfaction": 0.5,      # -50% satisfaction
	"very_dirty_traffic": 0.5,           # -50% traffic
}

## =============================================================================
## MARKETING PARAMETERS
## =============================================================================
const MARKETING = {
	# Campaign Costs & Effects
	"newspaper_ad_cost": 50.0,
	"newspaper_ad_duration": 3,          # Days
	"newspaper_ad_traffic": 1.2,         # +20% traffic

	"flyers_cost": 25.0,
	"flyers_duration": 1,
	"flyers_traffic": 1.15,

	"social_media_cost": 100.0,
	"social_media_unlock": 2000.0,
	"social_media_duration": 5,
	"social_media_traffic": 1.35,

	"radio_spot_cost": 150.0,
	"radio_spot_unlock": 5000.0,
	"radio_spot_duration": 7,
	"radio_spot_traffic": 1.4,

	"tv_commercial_cost": 500.0,
	"tv_commercial_unlock": 10000.0,
	"tv_commercial_duration": 14,
	"tv_commercial_traffic": 1.7,

	"billboard_cost": 1000.0,
	"billboard_unlock": 15000.0,
	"billboard_permanent": true,
	"billboard_traffic": 1.25,

	"grand_opening_cost": 200.0,
	"grand_opening_unlock": 3000.0,
	"grand_opening_duration": 1,
	"grand_opening_traffic": 2.5,        # Huge one-day boost!

	"loyalty_program_cost": 300.0,
	"loyalty_program_unlock": 8000.0,
	"loyalty_program_permanent": true,
	"loyalty_program_traffic": 1.15,
}

## =============================================================================
## STARTING RESOURCES
## =============================================================================
const STARTING_RESOURCES = {
	# Initial Ingredient Stock
	"flour": 10,
	"sugar": 10,
	"eggs": 10,
	"butter": 10,
	"milk": 10,
	"yeast": 10,
	"salt": 10,
	"chocolate_chips": 10,
	"blueberries": 10,

	# Ingredient Batch Sizes (per pickup from storage)
	"flour_batch": 5,
	"sugar_batch": 3,
	"eggs_batch": 3,
	"butter_batch": 3,
	"milk_batch": 2,
	"yeast_batch": 2,
	"salt_batch": 2,
	"chocolate_chips_batch": 4,
	"blueberries_batch": 4,
}

## =============================================================================
## PLAYER PARAMETERS
## =============================================================================
const PLAYER = {
	# Movement
	"move_speed": 5.0,
	"sprint_speed": 8.0,
	"jump_velocity": 4.5,
	"mouse_sensitivity": 0.003,

	# Camera
	"camera_distance": 4.0,
	"camera_height": 2.0,

	# Interaction
	"interaction_distance": 3.0,
}

## =============================================================================
## HELPER FUNCTIONS
## =============================================================================

## Get recipe mixing time with all multipliers applied
func get_recipe_mixing_time(recipe_id: String) -> float:
	if not RECIPES.recipes.has(recipe_id):
		return 60.0
	var base_time = RECIPES.recipes[recipe_id].mixing_time
	return base_time * RECIPES.mixing_time_multiplier

## Get recipe baking time with all multipliers applied
func get_recipe_baking_time(recipe_id: String) -> float:
	if not RECIPES.recipes.has(recipe_id):
		return 300.0
	var base_time = RECIPES.recipes[recipe_id].baking_time
	return base_time * RECIPES.baking_time_multiplier

## Get recipe price with all multipliers applied
func get_recipe_price(recipe_id: String) -> float:
	if not RECIPES.recipes.has(recipe_id):
		return 10.0
	var base_price = RECIPES.recipes[recipe_id].base_price
	var price = base_price * RECIPES.price_multiplier_global

	# Apply tier-specific multipliers
	if recipe_id in ["white_bread", "chocolate_chip_cookies", "blueberry_muffins"]:
		price *= RECIPES.price_multiplier_starter
	elif recipe_id in ["croissants", "danish_pastries", "scones", "cinnamon_rolls"]:
		price *= RECIPES.price_multiplier_basic
	elif recipe_id in ["sourdough", "baguettes", "focaccia", "rye_bread", "multigrain_loaf"]:
		price *= RECIPES.price_multiplier_artisan
	elif recipe_id in ["birthday_cake", "wedding_cupcakes", "cheesecake", "layer_cake"]:
		price *= RECIPES.price_multiplier_special
	elif recipe_id in ["grandmothers_apple_pie", "secret_recipe_cookies", "family_chocolate_cake", "holiday_specialty_bread"]:
		price *= RECIPES.price_multiplier_secret
	elif recipe_id in ["french_macarons", "german_stollen", "italian_biscotti", "japanese_melon_pan"]:
		price *= RECIPES.price_multiplier_international
	elif recipe_id in ["grandmothers_legendary_cake", "championship_recipe", "town_festival_winner"]:
		price *= RECIPES.price_multiplier_legendary

	return price

## Get ingredient price
func get_ingredient_price(ingredient_id: String) -> float:
	if ECONOMY.ingredient_prices.has(ingredient_id):
		return ECONOMY.ingredient_prices[ingredient_id]
	return 0.0

## Print balance summary for debugging
func print_balance_summary():
	print("=== BALANCE CONFIG LOADED ===")
	print("Starting Cash: $", ECONOMY.starting_cash)
	print("Business Day: ", TIME.business_end_hour - TIME.business_start_hour, " game hours")
	print("Base Customers/Hour: ", CUSTOMERS.base_customers_per_hour)
	print("Milestones: $500, $2000, $5000, $10000, $25000, $50000")
	print("============================")
