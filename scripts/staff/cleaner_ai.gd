extends Node

# CleanerAI - Automates cleanup tasks during Cleanup Phase
# Cleaners automatically handle washing, sweeping, wiping, trash, equipment checks

class_name CleanerAI

# Reference to the staff data
var staff_data: Dictionary
var staff_id: String

# State
var is_active: bool = false
var current_task: Dictionary = {}
var task_timer: float = 0.0
var tasks_completed: int = 0

# AI behavior settings (loaded from BalanceConfig)
var check_interval: float = 0.0  # Check for new tasks (loaded from config)
var next_check_time: float = 0.0

# Cleanup equipment references
var cleanup_stations: Array = []  # Sinks, trash cans, counter wipes, equipment checks

# Task priorities (higher = more important)
const TASK_PRIORITIES = {
	"trash": 5,
	"equipment_check": 4,
	"sink": 3,
	"counter_wipe": 2
}

func _init(p_staff_id: String, p_staff_data: Dictionary) -> void:
	staff_id = p_staff_id
	staff_data = p_staff_data

func activate() -> void:
	"""Activate the cleaner AI for this phase"""
	is_active = true
	tasks_completed = 0
	next_check_time = 0.0
	check_interval = BalanceConfig.STAFF.cleaner_check_interval
	print("[CleanerAI] ", staff_data.name, " is now cleaning!")
	_find_cleanup_stations()

func deactivate() -> void:
	"""Deactivate the cleaner AI"""
	is_active = false
	current_task.clear()
	print("[CleanerAI] ", staff_data.name, " finished cleaning. Tasks completed: ", tasks_completed)

func process(delta: float) -> void:
	"""Process AI logic each frame during Cleanup Phase"""
	if not is_active:
		return

	# If we have a current task, work on it
	if not current_task.is_empty():
		_process_current_task(delta)
		return

	# Check for new tasks periodically
	if Time.get_ticks_msec() / 1000.0 >= next_check_time:
		_check_for_tasks()
		next_check_time = Time.get_ticks_msec() / 1000.0 + check_interval

func _find_cleanup_stations() -> void:
	"""Find cleanup stations in the bakery"""
	cleanup_stations.clear()

	var bakery = get_tree().current_scene
	if not bakery:
		return

	# Find all cleanup-related objects
	for child in _get_all_children(bakery):
		var child_name: String = child.name.to_lower()
		if "sink" in child_name or "trash" in child_name or \
		   "counter" in child_name or "equipment_check" in child_name:
			cleanup_stations.append(child)

	print("[CleanerAI] Found ", cleanup_stations.size(), " cleanup stations")

func _get_all_children(node: Node) -> Array:
	"""Recursively get all children of a node"""
	var result: Array = []
	for child in node.get_children():
		result.append(child)
		result.append_array(_get_all_children(child))
	return result

func _check_for_tasks() -> void:
	"""Check for cleanup tasks, prioritized"""
	var available_tasks: Array = []

	# Check each cleanup station
	for station in cleanup_stations:
		if not station.has_method("needs_cleaning"):
			continue

		if station.needs_cleaning():
			var station_type: String = _get_station_type(station)
			var priority: int = TASK_PRIORITIES.get(station_type, 1)

			available_tasks.append({
				"station": station,
				"type": station_type,
				"priority": priority
			})

	if available_tasks.is_empty():
		# print("[CleanerAI] ", staff_data.name, " is idle - everything is clean!")
		return

	# Sort by priority (highest first)
	available_tasks.sort_custom(func(a, b): return a.priority > b.priority)

	# Start the highest priority task
	var best_task = available_tasks[0]
	_start_task(best_task)

func _get_station_type(station: Node) -> String:
	"""Determine the type of cleanup station"""
	var name: String = station.name.to_lower()
	if "trash" in name:
		return "trash"
	elif "equipment" in name:
		return "equipment_check"
	elif "sink" in name:
		return "sink"
	elif "counter" in name or "wipe" in name:
		return "counter_wipe"
	return "unknown"

func _start_task(task_data: Dictionary) -> void:
	"""Start a cleanup task"""
	var station = task_data.station
	var task_type: String = task_data.type

	# Get base duration from station
	var base_duration: float = 10.0
	if station.has_method("get_cleanup_duration"):
		base_duration = station.get_cleanup_duration()

	current_task = {
		"station": station,
		"type": task_type,
		"duration": base_duration
	}
	task_timer = 0.0

	print("[CleanerAI] ", staff_data.name, " cleaning ", task_type, "...")

func _process_current_task(delta: float) -> void:
	"""Process the current cleanup task"""
	if not GameManager:
		return

	# Apply time scale and staff speed multiplier
	var time_mult: float = GameManager.get_time_scale()
	var speed_mult: float = StaffManager.get_staff_speed_multiplier(staff_id)
	task_timer += delta * time_mult * speed_mult

	# Calculate actual duration (faster staff = faster cleaning)
	var actual_duration: float = current_task.duration / speed_mult

	if task_timer >= actual_duration:
		_complete_current_task()

func _complete_current_task() -> void:
	"""Complete the current cleanup task"""
	var station = current_task.station

	if station and station.has_method("auto_clean"):
		# Apply quality multiplier from staff skill (affects thoroughness)
		var quality_mult: float = StaffManager.get_staff_quality_multiplier(staff_id)
		station.auto_clean(quality_mult)

		print("[CleanerAI] ", staff_data.name, " completed ", current_task.type, " (quality: ", int(quality_mult * 100), "%)")
		tasks_completed += 1

	current_task.clear()
	task_timer = 0.0
