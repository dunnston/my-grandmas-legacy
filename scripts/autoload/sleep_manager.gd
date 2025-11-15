extends Node

# SleepManager - Manages sleep system, bonuses, and mini-game state
# Singleton that tracks sleep quality and applies daily bonuses

# Signals
signal sleep_initiated()
signal minigame_started()
signal minigame_completed(calm_percentage: float, sleep_quality: String)
signal bonuses_applied(bonuses: Dictionary)
signal day_advanced(new_day: int)

# Sleep quality thresholds
enum SleepQuality {
	RESTLESS,   # 0-29%
	LIGHT,      # 30-49%
	RESTFUL,    # 50-69%
	GOOD,       # 70-89%
	PERFECT     # 90-100%
}

# Current sleep state
var current_calm_percentage: float = 50.0
var current_sleep_quality: SleepQuality = SleepQuality.RESTFUL
var active_sleep_buffs: Dictionary = {}

# Sleep settings
var minigame_enabled: bool = true
var minigame_difficulty: String = "normal"  # easy, normal, hard
var auto_skip_after_day_7: bool = false

func _ready() -> void:
	print("SleepManager initialized")

## Start the sleep sequence
func initiate_sleep() -> void:
	print("[SleepManager] Initiating sleep sequence...")

	# Close shop if open
	if GameManager.is_shop_open():
		GameManager.close_shop()

	sleep_initiated.emit()

	# Check if should skip mini-game
	if not minigame_enabled or (auto_skip_after_day_7 and GameManager.get_current_day() > 7):
		_skip_minigame()
	else:
		_start_minigame()

## Start the counting sheep mini-game
func _start_minigame() -> void:
	print("[SleepManager] Starting counting sheep mini-game...")
	minigame_started.emit()

	# Mini-game scene will be loaded and controlled separately
	# This manager tracks state and applies results

## Skip mini-game (grants default bonus)
func _skip_minigame() -> void:
	print("[SleepManager] Skipping mini-game, granting default bonus...")

	# Grant "Light Sleep" equivalent (30-40% calm)
	var skip_calm = randf_range(30.0, 40.0)
	complete_sleep(skip_calm)

## Called when mini-game completes
func complete_sleep(calm_percentage: float) -> void:
	current_calm_percentage = clamp(calm_percentage, 0.0, 100.0)
	current_sleep_quality = _calculate_sleep_quality(current_calm_percentage)

	print("[SleepManager] Sleep completed!")
	print("  Calm: %.1f%%" % current_calm_percentage)
	print("  Quality: %s" % _get_quality_name(current_sleep_quality))

	# Calculate and apply bonuses
	var bonuses = _calculate_bonuses()
	_apply_bonuses(bonuses)

	# Advance to next day
	_advance_day()

	# Emit completion
	minigame_completed.emit(current_calm_percentage, _get_quality_name(current_sleep_quality))
	bonuses_applied.emit(bonuses)

## Calculate sleep quality from calm percentage
func _calculate_sleep_quality(calm: float) -> SleepQuality:
	if calm >= 90.0:
		return SleepQuality.PERFECT
	elif calm >= 70.0:
		return SleepQuality.GOOD
	elif calm >= 50.0:
		return SleepQuality.RESTFUL
	elif calm >= 30.0:
		return SleepQuality.LIGHT
	else:
		return SleepQuality.RESTLESS

## Calculate bonuses based on sleep quality
func _calculate_bonuses() -> Dictionary:
	var bonuses = {
		"energy_bonus": 0.0,
		"skill_effectiveness": 0.0,
		"reputation": 0.0,
		"buff_name": "",
		"buff_icon": ""
	}

	match current_sleep_quality:
		SleepQuality.PERFECT:
			bonuses.energy_bonus = 0.20  # +20%
			bonuses.skill_effectiveness = 0.10  # +10%
			bonuses.reputation = 2.0
			bonuses.buff_name = "Well Rested"
			bonuses.buff_icon = "☀️"

		SleepQuality.GOOD:
			bonuses.energy_bonus = 0.15  # +15%
			bonuses.skill_effectiveness = 0.05  # +5%
			bonuses.reputation = 1.0
			bonuses.buff_name = "Rested"
			bonuses.buff_icon = "🌤️"

		SleepQuality.RESTFUL:
			bonuses.energy_bonus = 0.10  # +10%
			bonuses.skill_effectiveness = 0.02  # +2%
			bonuses.reputation = 0.0
			bonuses.buff_name = "Refreshed"
			bonuses.buff_icon = "😊"

		SleepQuality.LIGHT:
			bonuses.energy_bonus = 0.05  # +5%
			bonuses.skill_effectiveness = 0.0
			bonuses.reputation = 0.0
			bonuses.buff_name = ""
			bonuses.buff_icon = ""

		SleepQuality.RESTLESS:
			# No bonuses, but NO PENALTIES (cozy game)
			bonuses.energy_bonus = 0.0
			bonuses.skill_effectiveness = 0.0
			bonuses.reputation = 0.0
			bonuses.buff_name = ""
			bonuses.buff_icon = ""

	return bonuses

## Apply calculated bonuses to game systems
func _apply_bonuses(bonuses: Dictionary) -> void:
	print("[SleepManager] Applying bonuses:")

	# Store active buffs
	active_sleep_buffs = bonuses.duplicate()

	# Apply reputation bonus
	if bonuses.reputation > 0 and ProgressionManager:
		ProgressionManager.modify_reputation(int(bonuses.reputation))
		print("  + Reputation: +%.0f" % bonuses.reputation)

	# Apply staff energy bonuses
	if bonuses.energy_bonus > 0 and StaffManager:
		StaffManager.apply_sleep_energy_bonus(bonuses.energy_bonus)
		print("  + Energy Bonus: +%.0f%%" % (bonuses.energy_bonus * 100))

	# Skill effectiveness will be checked by crafting systems
	if bonuses.skill_effectiveness > 0:
		print("  + Skill Effectiveness: +%.0f%%" % (bonuses.skill_effectiveness * 100))

	# Show buff name if any
	if bonuses.buff_name != "":
		print("  📋 Buff Active: %s %s" % [bonuses.buff_icon, bonuses.buff_name])

## Advance to next day
func _advance_day() -> void:
	# Advance time to morning (6 AM)
	var current_hour = GameManager.get_current_hour()
	var hours_until_morning = 0

	if current_hour >= 22:  # 10 PM or later
		hours_until_morning = (24 - current_hour) + 6
	elif current_hour < 6:  # Before 6 AM
		hours_until_morning = 6 - current_hour
	else:  # During the day
		hours_until_morning = (24 - current_hour) + 6

	# Use GameManager's sleep function (handles day transition)
	GameManager.sleep(hours_until_morning)

	print("[SleepManager] Advanced to Day %d, 06:00" % GameManager.get_current_day())
	day_advanced.emit(GameManager.get_current_day())

## Get current skill effectiveness multiplier
func get_skill_effectiveness_multiplier() -> float:
	if active_sleep_buffs.has("skill_effectiveness"):
		return 1.0 + active_sleep_buffs.skill_effectiveness
	return 1.0

## Get current energy bonus percentage
func get_energy_bonus() -> float:
	if active_sleep_buffs.has("energy_bonus"):
		return active_sleep_buffs.energy_bonus
	return 0.0

## Get active buff info for HUD display
func get_active_buff() -> Dictionary:
	if active_sleep_buffs.has("buff_name") and active_sleep_buffs.buff_name != "":
		return {
			"active": true,
			"name": active_sleep_buffs.buff_name,
			"icon": active_sleep_buffs.buff_icon,
			"energy_bonus": active_sleep_buffs.energy_bonus,
			"skill_bonus": active_sleep_buffs.skill_effectiveness
		}
	return {"active": false}

## Clear buffs (called on next sleep)
func clear_buffs() -> void:
	active_sleep_buffs.clear()
	print("[SleepManager] Sleep buffs cleared")

## Get quality name as string
func _get_quality_name(quality: SleepQuality) -> String:
	match quality:
		SleepQuality.PERFECT:
			return "Perfect Sleep"
		SleepQuality.GOOD:
			return "Good Sleep"
		SleepQuality.RESTFUL:
			return "Restful Sleep"
		SleepQuality.LIGHT:
			return "Light Sleep"
		SleepQuality.RESTLESS:
			return "Restless Sleep"
		_:
			return "Unknown"

## Get quality message
func get_quality_message(quality: SleepQuality) -> String:
	match quality:
		SleepQuality.PERFECT:
			return "You sleep blissfully! You wake up completely refreshed and inspired!"
		SleepQuality.GOOD:
			return "You sleep soundly. You wake up feeling great!"
		SleepQuality.RESTFUL:
			return "You sleep peacefully. You wake up ready for the day."
		SleepQuality.LIGHT:
			return "You toss and turn a bit, but get some rest. A new day begins."
		SleepQuality.RESTLESS:
			return "You had trouble sleeping, but morning has arrived."
		_:
			return "You slept."

## Save/Load
func get_save_data() -> Dictionary:
	return {
		"active_buffs": active_sleep_buffs,
		"settings": {
			"minigame_enabled": minigame_enabled,
			"difficulty": minigame_difficulty,
			"auto_skip": auto_skip_after_day_7
		}
	}

func load_save_data(data: Dictionary) -> void:
	if data.has("active_buffs"):
		active_sleep_buffs = data.active_buffs

	if data.has("settings"):
		var settings = data.settings
		minigame_enabled = settings.get("minigame_enabled", true)
		minigame_difficulty = settings.get("difficulty", "normal")
		auto_skip_after_day_7 = settings.get("auto_skip", false)

	print("[SleepManager] Loaded save data")
