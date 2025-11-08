extends Node

# CleanlinessManager - Tracks bakery cleanliness and chore completion
# Cleanliness affects customer satisfaction and traffic

# Signals
signal cleanliness_changed(new_level: float)
signal chore_completed(chore_id: String)
signal all_chores_completed()
signal cleanliness_penalty_applied(penalty: float)

# Cleanliness tracking (0-100, where 100 = spotless)
var current_cleanliness: float = 100.0
var daily_cleanliness_decay: float = 15.0  # Cleanliness drops by this much per day

# Chore states (reset each cleanup phase)
var chores_completed: Dictionary = {
	"dishes": false,
	"floor": false,
	"counters": false,
	"trash": false,
	"equipment": false
}

# Chore impact values (how much each chore improves cleanliness)
const CHORE_VALUES: Dictionary = {
	"dishes": 15.0,      # Washing dishes
	"floor": 20.0,       # Sweeping/mopping floor
	"counters": 15.0,    # Wiping counters
	"trash": 10.0,       # Emptying trash
	"equipment": 10.0    # Equipment maintenance check
}

# Cleanliness thresholds
const CLEANLINESS_EXCELLENT: float = 90.0
const CLEANLINESS_GOOD: float = 70.0
const CLEANLINESS_ACCEPTABLE: float = 50.0
const CLEANLINESS_POOR: float = 30.0
# Below 30 = Very Dirty

# Staff automation
var has_cleaning_staff: bool = false

func _ready() -> void:
	print("CleanlinessManager initialized")
	print("Starting cleanliness: %.1f%%" % current_cleanliness)

# Reset chores at start of cleanup phase
func start_cleanup_phase() -> void:
	"""Called when cleanup phase begins"""
	print("\n=== CLEANUP PHASE STARTED ===")
	print("Current cleanliness: %.1f%% (%s)" % [current_cleanliness, get_cleanliness_tier()])

	# Reset all chores to incomplete
	for chore in chores_completed.keys():
		chores_completed[chore] = false

	# If have cleaning staff, auto-complete all chores
	if has_cleaning_staff:
		print("Cleaning staff will handle cleanup automatically!")
		auto_complete_all_chores()
	else:
		print("Chores to complete:")
		for chore in chores_completed.keys():
			print("  [ ] %s" % chore.capitalize())

func complete_chore(chore_id: String) -> bool:
	"""Mark a chore as completed and improve cleanliness"""
	if not chores_completed.has(chore_id):
		print("Error: Unknown chore '%s'" % chore_id)
		return false

	if chores_completed[chore_id]:
		print("Chore '%s' already completed!" % chore_id)
		return false

	# Mark as completed
	chores_completed[chore_id] = true

	# Improve cleanliness
	var improvement: float = CHORE_VALUES[chore_id]
	current_cleanliness = min(current_cleanliness + improvement, 100.0)

	print("✓ Completed: %s (+%.1f%% cleanliness)" % [chore_id.capitalize(), improvement])
	print("  Current cleanliness: %.1f%%" % current_cleanliness)

	chore_completed.emit(chore_id)
	cleanliness_changed.emit(current_cleanliness)

	# Check if all chores done
	if are_all_chores_completed():
		print("\n✨ All chores completed! Shop is spotless!")
		all_chores_completed.emit()

	return true

func are_all_chores_completed() -> bool:
	"""Check if all chores are done"""
	for completed in chores_completed.values():
		if not completed:
			return false
	return true

func get_remaining_chores() -> Array:
	"""Get list of incomplete chores"""
	var remaining: Array = []
	for chore in chores_completed.keys():
		if not chores_completed[chore]:
			remaining.append(chore)
	return remaining

func auto_complete_all_chores() -> void:
	"""Automatically complete all chores (used by cleaning staff)"""
	print("\nCleaning staff completing all chores...")
	for chore in chores_completed.keys():
		if not chores_completed[chore]:
			complete_chore(chore)
	print("Cleaning staff finished! Shop is ready.")

# End of day cleanliness decay
func apply_daily_decay() -> void:
	"""Apply end-of-day cleanliness decay"""
	var decay: float = daily_cleanliness_decay

	# If chores weren't completed, extra decay
	if not are_all_chores_completed():
		var incomplete_count: int = get_remaining_chores().size()
		decay += incomplete_count * 5.0  # Each incomplete chore = +5% decay
		print("⚠ Warning: %d chores left incomplete! Extra decay applied." % incomplete_count)

	current_cleanliness = max(current_cleanliness - decay, 0.0)

	print("End of day cleanliness decay: -%.1f%%" % decay)
	print("New cleanliness: %.1f%% (%s)" % [current_cleanliness, get_cleanliness_tier()])

	cleanliness_changed.emit(current_cleanliness)

# Get cleanliness tier name
func get_cleanliness_tier() -> String:
	if current_cleanliness >= CLEANLINESS_EXCELLENT:
		return "Spotless"
	elif current_cleanliness >= CLEANLINESS_GOOD:
		return "Clean"
	elif current_cleanliness >= CLEANLINESS_ACCEPTABLE:
		return "Acceptable"
	elif current_cleanliness >= CLEANLINESS_POOR:
		return "Dirty"
	else:
		return "Very Dirty"

# Get customer satisfaction modifier based on cleanliness
func get_satisfaction_modifier() -> float:
	"""Returns a multiplier for customer satisfaction (0.5 to 1.2)"""
	if current_cleanliness >= CLEANLINESS_EXCELLENT:
		return 1.2  # +20% satisfaction (spotless)
	elif current_cleanliness >= CLEANLINESS_GOOD:
		return 1.0  # Normal satisfaction
	elif current_cleanliness >= CLEANLINESS_ACCEPTABLE:
		return 0.9  # -10% satisfaction
	elif current_cleanliness >= CLEANLINESS_POOR:
		return 0.7  # -30% satisfaction
	else:
		return 0.5  # -50% satisfaction (very dirty)

# Get traffic modifier based on cleanliness
func get_traffic_modifier() -> float:
	"""Returns a multiplier for customer traffic (0.5 to 1.1)"""
	if current_cleanliness >= CLEANLINESS_EXCELLENT:
		return 1.1  # +10% traffic (word spreads about cleanliness)
	elif current_cleanliness >= CLEANLINESS_GOOD:
		return 1.0  # Normal traffic
	elif current_cleanliness >= CLEANLINESS_ACCEPTABLE:
		return 0.95  # -5% traffic
	elif current_cleanliness >= CLEANLINESS_POOR:
		return 0.75  # -25% traffic
	else:
		return 0.5  # -50% traffic (people avoid dirty shops)

# Get color for UI display
func get_cleanliness_color() -> Color:
	if current_cleanliness >= CLEANLINESS_EXCELLENT:
		return Color(0.2, 0.8, 0.2)  # Green
	elif current_cleanliness >= CLEANLINESS_GOOD:
		return Color(0.6, 0.8, 0.3)  # Light green
	elif current_cleanliness >= CLEANLINESS_ACCEPTABLE:
		return Color(0.9, 0.9, 0.2)  # Yellow
	elif current_cleanliness >= CLEANLINESS_POOR:
		return Color(0.9, 0.5, 0.1)  # Orange
	else:
		return Color(0.9, 0.2, 0.2)  # Red

# Staff management
func hire_cleaning_staff() -> void:
	"""Enable automatic chore completion"""
	has_cleaning_staff = true
	print("Hired cleaning staff! Chores will be completed automatically.")

func fire_cleaning_staff() -> void:
	"""Disable automatic chore completion"""
	has_cleaning_staff = false
	print("Fired cleaning staff. You'll need to do chores manually.")

func has_staff() -> bool:
	return has_cleaning_staff

# Utility functions
func get_cleanliness() -> float:
	return current_cleanliness

func set_cleanliness(value: float) -> void:
	current_cleanliness = clampf(value, 0.0, 100.0)
	cleanliness_changed.emit(current_cleanliness)

func is_chore_completed(chore_id: String) -> bool:
	return chores_completed.get(chore_id, false)

func get_chore_completion_percentage() -> float:
	var completed_count: int = 0
	for completed in chores_completed.values():
		if completed:
			completed_count += 1
	return (float(completed_count) / float(chores_completed.size())) * 100.0

# Save/Load
func get_save_data() -> Dictionary:
	return {
		"current_cleanliness": current_cleanliness,
		"has_cleaning_staff": has_cleaning_staff,
		"chores_completed": chores_completed
	}

func load_save_data(data: Dictionary) -> void:
	if data.has("current_cleanliness"):
		current_cleanliness = data.current_cleanliness
	if data.has("has_cleaning_staff"):
		has_cleaning_staff = data.has_cleaning_staff
	if data.has("chores_completed"):
		chores_completed = data.chores_completed

	print("Loaded CleanlinessManager data:")
	print("  - Cleanliness: %.1f%%" % current_cleanliness)
	print("  - Has cleaning staff: %s" % has_cleaning_staff)

func reset() -> void:
	"""Reset cleanliness for new game"""
	current_cleanliness = 100.0
	has_cleaning_staff = false
	for chore in chores_completed.keys():
		chores_completed[chore] = false
	print("CleanlinessManager reset")
