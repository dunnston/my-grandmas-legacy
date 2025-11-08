extends Node

# QualityManager - Handles crafting quality and legendary items
# Calculates quality based on timing, equipment, and randomness

# Signals
signal legendary_item_created(item_id: String, quality: float)
signal quality_calculated(item_id: String, quality: float, quality_tier: String)

# Quality tiers
enum QualityTier {
	POOR,      # 50-69% - Burns, mistakes
	NORMAL,    # 70-89% - Standard quality
	GOOD,      # 90-94% - Well-made
	EXCELLENT, # 95-99% - Near-perfect
	PERFECT    # 100% - Flawless
}

# Quality multipliers for pricing
const QUALITY_PRICE_MULTIPLIERS: Dictionary = {
	QualityTier.POOR: 0.7,      # -30% price
	QualityTier.NORMAL: 1.0,    # Base price
	QualityTier.GOOD: 1.2,      # +20% price
	QualityTier.EXCELLENT: 1.5, # +50% price
	QualityTier.PERFECT: 2.0    # +100% price
}

# Legendary chance (only on PERFECT items)
const LEGENDARY_CHANCE: float = 0.05  # 5%

# Equipment quality bonuses (these will come from EquipmentManager later)
var equipment_quality_bonus: float = 0.0  # 0-10% bonus from good equipment

func _ready() -> void:
	print("QualityManager initialized")

func calculate_quality(recipe_id: String, bake_time_actual: float, bake_time_target: float, equipment_tier: int = 0) -> Dictionary:
	"""
	Calculate crafting quality based on multiple factors
	Returns: { quality: float (0-100), tier: QualityTier, is_legendary: bool }
	"""

	var quality: float = 100.0

	# 1. Timing factor (0-40% impact)
	var timing_quality: float = calculate_timing_quality(bake_time_actual, bake_time_target)
	quality *= timing_quality

	# 2. Equipment bonus (0-10% bonus)
	var equipment_bonus: float = equipment_tier * 0.02  # Each tier = +2%
	quality += equipment_bonus * 100

	# 3. Random variance (±5%)
	var random_variance: float = randf_range(-5.0, 5.0)
	quality += random_variance

	# Clamp to valid range
	quality = clampf(quality, 0.0, 100.0)

	# Determine quality tier
	var tier: QualityTier = get_quality_tier(quality)

	# Check for legendary (only on PERFECT items)
	var is_legendary: bool = false
	if tier == QualityTier.PERFECT:
		if randf() < LEGENDARY_CHANCE:
			is_legendary = true
			print("✨ LEGENDARY ITEM CREATED! ✨")
			legendary_item_created.emit(recipe_id, quality)

	var tier_name: String = QualityTier.keys()[tier]
	quality_calculated.emit(recipe_id, quality, tier_name)

	print("Quality calculated: %.1f%% (%s)%s" % [
		quality,
		tier_name,
		" - LEGENDARY!" if is_legendary else ""
	])

	return {
		"quality": quality,
		"tier": tier,
		"tier_name": tier_name,
		"is_legendary": is_legendary,
		"price_multiplier": QUALITY_PRICE_MULTIPLIERS[tier]
	}

func calculate_timing_quality(actual_time: float, target_time: float) -> float:
	"""
	Calculate quality factor based on baking time accuracy
	Returns: 0.6 to 1.0 (60% to 100%)
	"""
	if target_time <= 0:
		return 1.0

	var time_diff: float = abs(actual_time - target_time)
	var percent_off: float = (time_diff / target_time) * 100.0

	# Perfect timing (within 5%)
	if percent_off <= 5.0:
		return 1.0  # 100%

	# Good timing (within 10%)
	elif percent_off <= 10.0:
		return 0.95  # 95%

	# Acceptable timing (within 20%)
	elif percent_off <= 20.0:
		return 0.85  # 85%

	# Poor timing (within 30%)
	elif percent_off <= 30.0:
		return 0.75  # 75%

	# Very poor timing (over 30% off)
	else:
		return 0.60  # 60% (burnt or underbaked)

func get_quality_tier(quality_percent: float) -> QualityTier:
	"""Convert quality percentage to tier"""
	if quality_percent >= 100.0:
		return QualityTier.PERFECT
	elif quality_percent >= 95.0:
		return QualityTier.EXCELLENT
	elif quality_percent >= 90.0:
		return QualityTier.GOOD
	elif quality_percent >= 70.0:
		return QualityTier.NORMAL
	else:
		return QualityTier.POOR

func get_quality_tier_name(tier: QualityTier) -> String:
	"""Get display name for quality tier"""
	match tier:
		QualityTier.POOR:
			return "Poor"
		QualityTier.NORMAL:
			return "Normal"
		QualityTier.GOOD:
			return "Good"
		QualityTier.EXCELLENT:
			return "Excellent"
		QualityTier.PERFECT:
			return "Perfect"
		_:
			return "Unknown"

func get_quality_color(tier: QualityTier) -> Color:
	"""Get color for quality tier display"""
	match tier:
		QualityTier.POOR:
			return Color(0.7, 0.3, 0.3)  # Reddish
		QualityTier.NORMAL:
			return Color(0.8, 0.8, 0.8)  # Gray
		QualityTier.GOOD:
			return Color(0.3, 0.8, 0.3)  # Green
		QualityTier.EXCELLENT:
			return Color(0.3, 0.6, 1.0)  # Blue
		QualityTier.PERFECT:
			return Color(1.0, 0.8, 0.2)  # Gold
		_:
			return Color.WHITE

func get_price_for_quality(base_price: float, quality_data: Dictionary) -> float:
	"""Calculate final price based on quality"""
	var multiplier: float = quality_data.get("price_multiplier", 1.0)

	# Legendary items get an additional 50% bonus
	if quality_data.get("is_legendary", false):
		multiplier *= 1.5

	return base_price * multiplier

func create_quality_item_id(base_item_id: String, quality_data: Dictionary) -> String:
	"""
	Create a unique item ID that includes quality information
	Example: "white_bread_excellent" or "croissant_legendary"
	"""
	if quality_data.get("is_legendary", false):
		return base_item_id + "_legendary"

	var tier_name: String = quality_data.get("tier_name", "normal").to_lower()

	# Only add quality suffix for non-normal items
	if tier_name != "normal":
		return base_item_id + "_" + tier_name

	return base_item_id

func get_display_name_with_quality(base_name: String, quality_data: Dictionary) -> String:
	"""Get item display name with quality prefix"""
	if quality_data.get("is_legendary", false):
		return "⭐ Legendary " + base_name

	var tier: QualityTier = quality_data.get("tier", QualityTier.NORMAL)
	var tier_name: String = get_quality_tier_name(tier)

	# Only add quality prefix for non-normal items
	if tier != QualityTier.NORMAL:
		return tier_name + " " + base_name

	return base_name

# Helper for equipment bonuses (will integrate with EquipmentManager later)
func set_equipment_quality_bonus(bonus: float) -> void:
	"""Set equipment quality bonus (0.0 to 0.10)"""
	equipment_quality_bonus = clampf(bonus, 0.0, 0.10)
