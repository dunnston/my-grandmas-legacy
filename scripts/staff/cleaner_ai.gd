extends Node

# CleanerAI - Automates cleanup tasks during Cleanup Phase with realistic movement
# Cleaners walk between stations: sink, trash, counters

class_name CleanerAI

# Reference to the staff data
var staff_data: Dictionary
var staff_id: String

# State machine
enum CleanerState {
	IDLE,                # Standing, checking for cleanup tasks
	WALKING_TO_SINK,     # Walking to sink to wash dishes
	WASHING_DISHES,      # At sink washing dishes
	WALKING_TO_TRASH,    # Walking to trash can
	EMPTYING_TRASH,      # At trash can emptying it
	WALKING_TO_COUNTER,  # Walking to dirty counter
	WIPING_COUNTER,      # At counter wiping it down
	WALKING_TO_EQUIPMENT # Walking to equipment for inspection
}

var is_active: bool = false
var current_state: CleanerState = CleanerState.IDLE
var state_timer: float = 0.0
var tasks_completed: int = 0

# Current task target
var target_station: Node = null  # Can be any Node type
var current_task_type: String = ""

# AI behavior settings
var check_interval: float = 0.0
var next_check_time: float = 0.0
var action_time: float = 3.0  # Time to perform cleanup actions

# Cleanup station references
var sinks: Array = []
var trash_cans: Array = []
var counters: Array = []
var equipment_stations: Array = []

# Visual character reference
var character: Node3D = null
var nav_agent: NavigationAgent3D = null
var cached_animation_name: String = ""  # Cache the animation name for play/stop

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

func set_character(p_character: Node3D) -> void:
	"""Set the visual character this AI controls"""
	character = p_character
	if character:
		for child in character.get_children():
			if child is NavigationAgent3D:
				nav_agent = child
				nav_agent.path_desired_distance = 0.5
				nav_agent.target_desired_distance = 0.5
				nav_agent.avoidance_enabled = true
				break

func activate() -> void:
	"""Activate the cleaner AI for this phase"""
	is_active = true
	tasks_completed = 0
	next_check_time = 0.0
	current_state = CleanerState.IDLE
	check_interval = BalanceConfig.STAFF.cleaner_check_interval
	print("[CleanerAI] ", staff_data.name, " is now cleaning!")
	_find_cleanup_stations()

	# Initialize navigation to current position (already at target)
	if character and nav_agent:
		nav_agent.target_position = character.global_position

	# Cache animation name BEFORE stopping (so we can resume later)
	_cache_animation_name()

	# Stop walking animation - pause at current frame
	_set_animation("walk", false)

func deactivate() -> void:
	"""Deactivate the cleaner AI"""
	is_active = false
	current_state = CleanerState.IDLE
	print("[CleanerAI] ", staff_data.name, " finished cleaning. Tasks completed: ", tasks_completed)

func process(delta: float) -> void:
	"""Process AI logic each frame during Cleanup Phase"""
	if not is_active or not character:
		return

	# State machine
	match current_state:
		CleanerState.IDLE:
			_state_idle()
		CleanerState.WALKING_TO_SINK:
			_state_walking_to_sink(delta)
		CleanerState.WASHING_DISHES:
			_state_washing_dishes(delta)
		CleanerState.WALKING_TO_TRASH:
			_state_walking_to_trash(delta)
		CleanerState.EMPTYING_TRASH:
			_state_emptying_trash(delta)
		CleanerState.WALKING_TO_COUNTER:
			_state_walking_to_counter(delta)
		CleanerState.WIPING_COUNTER:
			_state_wiping_counter(delta)
		CleanerState.WALKING_TO_EQUIPMENT:
			_state_walking_to_equipment(delta)

func _find_cleanup_stations() -> void:
	"""Find all StaffTarget markers for cleaner"""
	sinks.clear()
	trash_cans.clear()
	counters.clear()
	equipment_stations.clear()

	var bakery = get_tree().current_scene
	if not bakery:
		return

	# Find StaffTarget nodes
	for child in _get_all_children(bakery):
		# Check if node has the StaffTarget properties
		if child.get_script():
			var target_name_prop = child.get("target_name")
			var target_type_prop = child.get("target_type")

			# Check if this is a staff target for cleaners
			if target_name_prop and target_type_prop:
				if target_type_prop == "cleaner" or target_type_prop == "any":
					var name_lower = str(target_name_prop).to_lower()
					if "sink" in name_lower:
						sinks.append(child)
						print("[CleanerAI] Found sink target: ", child.name)
					elif "trash" in name_lower:
						trash_cans.append(child)
						print("[CleanerAI] Found trash target: ", child.name)
					elif "counter" in name_lower:
						counters.append(child)
						print("[CleanerAI] Found counter target: ", child.name)
					else:
						equipment_stations.append(child)
						print("[CleanerAI] Found equipment target: ", child.name)

	print("[CleanerAI] Total: ", sinks.size(), " sinks, ", trash_cans.size(), " trash cans")
	print("[CleanerAI] Total: ", counters.size(), " counters, ", equipment_stations.size(), " equipment")

func _get_all_children(node: Node) -> Array:
	"""Recursively get all children of a node"""
	var result: Array = []
	for child in node.get_children():
		result.append(child)
		result.append_array(_get_all_children(child))
	return result

# ============================================================================
# STATE MACHINE
# ============================================================================

func _state_idle() -> void:
	"""Idle, checking for cleanup work"""
	# Stop movement and animation when idle
	_set_animation("walk", false)

	# Make sure navigation is stopped
	if nav_agent and character:
		nav_agent.target_position = character.global_position

	# Check periodically for tasks
	if Time.get_ticks_msec() / 1000.0 >= next_check_time:
		_check_for_tasks()
		next_check_time = Time.get_ticks_msec() / 1000.0 + check_interval

func _state_walking_to_sink(delta: float) -> void:
	"""Walking to sink"""
	if not target_station:
		current_state = CleanerState.IDLE
		return

	var target_pos = _get_node_position(target_station)
	_navigate_towards(target_pos, delta)

	if _is_at_position(target_pos):
		print("[CleanerAI] ", staff_data.name, " reached sink")
		current_state = CleanerState.WASHING_DISHES
		state_timer = 0.0

func _state_washing_dishes(delta: float) -> void:
	"""Washing dishes at sink"""
	_set_animation("walk", false)

	var time_mult: float = GameManager.get_time_scale() if GameManager else 1.0
	var speed_mult: float = StaffManager.get_staff_speed_multiplier(staff_id)
	state_timer += delta * time_mult * speed_mult

	if state_timer >= action_time / speed_mult:
		_complete_sink_task()
		current_state = CleanerState.IDLE
		tasks_completed += 1

func _state_walking_to_trash(delta: float) -> void:
	"""Walking to trash can"""
	if not target_station:
		current_state = CleanerState.IDLE
		return

	var target_pos = _get_node_position(target_station)
	_navigate_towards(target_pos, delta)

	if _is_at_position(target_pos):
		print("[CleanerAI] ", staff_data.name, " reached trash can")
		current_state = CleanerState.EMPTYING_TRASH
		state_timer = 0.0

func _state_emptying_trash(delta: float) -> void:
	"""Emptying trash can"""
	_set_animation("walk", false)

	var time_mult: float = GameManager.get_time_scale() if GameManager else 1.0
	var speed_mult: float = StaffManager.get_staff_speed_multiplier(staff_id)
	state_timer += delta * time_mult * speed_mult

	if state_timer >= action_time / speed_mult:
		_complete_trash_task()
		current_state = CleanerState.IDLE
		tasks_completed += 1

func _state_walking_to_counter(delta: float) -> void:
	"""Walking to counter"""
	if not target_station:
		current_state = CleanerState.IDLE
		return

	var target_pos = _get_node_position(target_station)
	_navigate_towards(target_pos, delta)

	if _is_at_position(target_pos):
		print("[CleanerAI] ", staff_data.name, " reached counter")
		current_state = CleanerState.WIPING_COUNTER
		state_timer = 0.0

func _state_wiping_counter(delta: float) -> void:
	"""Wiping down counter"""
	_set_animation("walk", false)

	var time_mult: float = GameManager.get_time_scale() if GameManager else 1.0
	var speed_mult: float = StaffManager.get_staff_speed_multiplier(staff_id)
	state_timer += delta * time_mult * speed_mult

	if state_timer >= action_time / speed_mult:
		_complete_counter_task()
		current_state = CleanerState.IDLE
		tasks_completed += 1

func _state_walking_to_equipment(delta: float) -> void:
	"""Walking to equipment for inspection"""
	if not target_station:
		current_state = CleanerState.IDLE
		return

	var target_pos = _get_node_position(target_station)
	_navigate_towards(target_pos, delta)

	if _is_at_position(target_pos):
		print("[CleanerAI] ", staff_data.name, " inspecting equipment")
		# Equipment check is instant
		_complete_equipment_task()
		current_state = CleanerState.IDLE
		tasks_completed += 1

# ============================================================================
# TASK CHECKING
# ============================================================================

func _check_for_tasks() -> void:
	"""Check for cleanup tasks - priority order"""
	# Priority 1: Empty trash
	if _try_empty_trash():
		return

	# Priority 2: Wash dishes
	if _try_wash_dishes():
		return

	# Priority 3: Wipe counters
	if _try_wipe_counter():
		return

	# Priority 4: Check equipment (always available)
	if _try_check_equipment():
		return

func _try_wash_dishes() -> bool:
	"""Try to wash dishes at sink"""
	if sinks.is_empty():
		return false

	# Check if sink has dirty dishes
	for sink in sinks:
		if sink.has_method("needs_cleaning") and sink.needs_cleaning():
			target_station = sink
			current_task_type = "sink"
			current_state = CleanerState.WALKING_TO_SINK
			print("[CleanerAI] ", staff_data.name, " going to wash dishes")
			return true

	# If no method, just pick first sink periodically
	if randf() < 0.3:  # 30% chance to clean sink anyway
		target_station = sinks[0]
		current_task_type = "sink"
		current_state = CleanerState.WALKING_TO_SINK
		print("[CleanerAI] ", staff_data.name, " going to clean sink")
		return true

	return false

func _try_empty_trash() -> bool:
	"""Try to empty trash cans"""
	if trash_cans.is_empty():
		return false

	# Check if trash needs emptying
	for trash in trash_cans:
		if trash.has_method("needs_emptying") and trash.needs_emptying():
			target_station = trash
			current_task_type = "trash"
			current_state = CleanerState.WALKING_TO_TRASH
			print("[CleanerAI] ", staff_data.name, " going to empty trash")
			return true

	# Periodically empty trash anyway
	if randf() < 0.2:  # 20% chance
		target_station = trash_cans[0]
		current_task_type = "trash"
		current_state = CleanerState.WALKING_TO_TRASH
		print("[CleanerAI] ", staff_data.name, " going to empty trash")
		return true

	return false

func _try_wipe_counter() -> bool:
	"""Try to wipe down counters"""
	if counters.is_empty():
		return false

	# Periodically wipe counters
	if randf() < 0.4:  # 40% chance
		target_station = counters[randi() % counters.size()]
		current_task_type = "counter_wipe"
		current_state = CleanerState.WALKING_TO_COUNTER
		print("[CleanerAI] ", staff_data.name, " going to wipe counter")
		return true

	return false

func _try_check_equipment() -> bool:
	"""Try to inspect equipment"""
	if equipment_stations.is_empty():
		return false

	# Periodically check equipment
	if randf() < 0.3:  # 30% chance
		target_station = equipment_stations[randi() % equipment_stations.size()]
		current_task_type = "equipment_check"
		current_state = CleanerState.WALKING_TO_EQUIPMENT
		print("[CleanerAI] ", staff_data.name, " going to check equipment")
		return true

	return false

# ============================================================================
# TASK COMPLETION
# ============================================================================

func _complete_sink_task() -> void:
	"""Complete washing dishes"""
	if target_station and target_station.has_method("auto_clean"):
		target_station.auto_clean()
	print("[CleanerAI] ", staff_data.name, " finished washing dishes")
	target_station = null

func _complete_trash_task() -> void:
	"""Complete emptying trash"""
	if target_station and target_station.has_method("auto_empty"):
		target_station.auto_empty()
	print("[CleanerAI] ", staff_data.name, " emptied trash")
	target_station = null

func _complete_counter_task() -> void:
	"""Complete wiping counter"""
	if target_station and target_station.has_method("auto_wipe"):
		target_station.auto_wipe()
	print("[CleanerAI] ", staff_data.name, " wiped counter")
	target_station = null

func _complete_equipment_task() -> void:
	"""Complete equipment check"""
	if target_station and target_station.has_method("auto_inspect"):
		target_station.auto_inspect()
	print("[CleanerAI] ", staff_data.name, " inspected equipment")
	target_station = null

# ============================================================================
# MOVEMENT HELPERS
# ============================================================================

func _get_node_position(node: Node) -> Vector3:
	"""Safely get position from any node type"""
	if not node:
		return Vector3.ZERO

	if node is Node3D:
		return node.global_position
	else:
		return Vector3.ZERO

func _navigate_towards(target_pos: Vector3, delta: float) -> void:
	"""Navigate character towards target position"""
	if not character or not nav_agent:
		return

	# Check if target is Vector3.ZERO (invalid position)
	if target_pos == Vector3.ZERO:
		print("[CleanerAI] WARNING: Trying to navigate to ZERO position - equipment node might be wrong type!")
		return

	nav_agent.target_position = target_pos

	if nav_agent.is_navigation_finished():
		# Stopped at destination - pause animation
		_set_animation("walk", false)
		return

	# Still moving - ensure animation is playing
	_set_animation("walk", true)

	var next_position = nav_agent.get_next_path_position()
	var direction = (next_position - character.global_position).normalized()

	var speed_mult: float = StaffManager.get_staff_speed_multiplier(staff_id)
	var move_speed: float = 3.0 * speed_mult
	character.global_position += direction * move_speed * delta

	if direction.length() > 0.01:
		var target_rotation = atan2(direction.x, direction.z)
		character.rotation.y = lerp_angle(character.rotation.y, target_rotation, delta * 10.0)

func _is_at_position(target_pos: Vector3) -> bool:
	"""Check if character is at target position"""
	if not character:
		return true
	return character.global_position.distance_to(target_pos) < 1.0

func _cache_animation_name() -> void:
	"""Cache the animation name from AnimationPlayer before stopping"""
	if not character or cached_animation_name != "":
		return

	var anim_player: AnimationPlayer = _find_animation_player_recursive(character)
	if not anim_player:
		return

	# Try to get from current_animation first
	if anim_player.current_animation != "":
		cached_animation_name = anim_player.current_animation
		return

	# Fallback: Get first animation from list
	var anims = anim_player.get_animation_list()
	if anims.size() > 0:
		cached_animation_name = anims[0]

func _set_animation(anim_name: String, playing: bool) -> void:
	"""Set character animation"""
	if not character:
		return

	# Recursively search for AnimationPlayer (it's nested in customer models)
	var anim_player: AnimationPlayer = _find_animation_player_recursive(character)

	if not anim_player:
		return

	if playing:
		# Play the cached animation
		if not anim_player.is_playing() and cached_animation_name != "":
			anim_player.play(cached_animation_name)
	else:
		# Stop animation completely
		anim_player.stop()

func _find_animation_player_recursive(node: Node) -> AnimationPlayer:
	"""Recursively search for AnimationPlayer in node hierarchy"""
	if node is AnimationPlayer:
		return node

	for child in node.get_children():
		if child is AnimationPlayer:
			return child

	for child in node.get_children():
		var result = _find_animation_player_recursive(child)
		if result:
			return result

	return null
