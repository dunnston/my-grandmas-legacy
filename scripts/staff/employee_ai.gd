extends Node

# EmployeeAI - Unified AI for all employee phases
# Skill-based system supporting: baking, checkout, cleanup, restocking

class_name EmployeeAI

# Reference to employee data
var employee_data: Dictionary
var employee_id: String
var assigned_phase: String = "none"

# State machine - unified states for all phases
enum EmployeeState {
	IDLE,                    # Standing, checking for work
	WALKING_TO_TARGET,       # Walking to any target location
	PERFORMING_TASK,         # Performing any task (gathering, mixing, checkout, cleaning, etc.)
	WAITING                  # Waiting for task completion
}

var is_active: bool = false
var current_state: EmployeeState = EmployeeState.IDLE
var state_timer: float = 0.0
var tasks_completed: int = 0

# Current task data
var current_task: Dictionary = {}
var target_equipment: Node = null
var target_position: Vector3 = Vector3.ZERO

# AI behavior settings
var check_interval: float = 0.0
var next_check_time: float = 0.0
var action_time: float = 2.0  # Base time to perform actions

# Equipment references (found dynamically)
var available_equipment: Dictionary = {
	"storage": [],
	"mixing_bowls": [],
	"ovens": [],
	"registers": [],
	"display_cases": [],
	"sinks": [],
	"trash_cans": [],
	"counters": []
}

# Visual character reference
var character: Node3D = null
var nav_agent: NavigationAgent3D = null
var cached_animation_name: String = ""

func _init(p_employee_id: String, p_employee_data: Dictionary) -> void:
	employee_id = p_employee_id
	employee_data = p_employee_data

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

func activate(phase: String = "none") -> void:
	"""Activate the employee AI for a specific phase"""
	assigned_phase = phase
	is_active = true
	tasks_completed = 0
	next_check_time = 0.0
	current_state = EmployeeState.IDLE

	# Load phase-specific check interval
	if BalanceConfig.STAFF.ai_check_intervals.has(phase):
		check_interval = BalanceConfig.STAFF.ai_check_intervals[phase]
	else:
		check_interval = 2.0  # Default

	print("[EmployeeAI] ", employee_data["employee_name"], " is now working on ", phase, " phase!")
	_find_equipment()

	# Initialize navigation to current position
	if character and nav_agent:
		nav_agent.target_position = character.global_position

	# Cache animation and stop walking
	_cache_animation_name()
	_set_animation("walk", false)

func deactivate() -> void:
	"""Deactivate the employee AI"""
	is_active = false
	current_task.clear()
	current_state = EmployeeState.IDLE
	assigned_phase = "none"
	print("[EmployeeAI] ", employee_data["employee_name"], " finished work. Tasks completed: ", tasks_completed)

func process(delta: float) -> void:
	"""Process AI logic each frame"""
	if not is_active or not character:
		return

	# State machine
	match current_state:
		EmployeeState.IDLE:
			_state_idle()
		EmployeeState.WALKING_TO_TARGET:
			_state_walking_to_target(delta)
		EmployeeState.PERFORMING_TASK:
			_state_performing_task(delta)
		EmployeeState.WAITING:
			_state_waiting(delta)

func _find_equipment() -> void:
	"""Find all relevant equipment/targets for this phase"""
	# Clear existing
	for key in available_equipment.keys():
		available_equipment[key].clear()

	var bakery = get_tree().current_scene
	if not bakery:
		print("[EmployeeAI] ERROR: No current scene found")
		return

	# Find StaffTarget nodes and actual equipment
	for child in _get_all_children(bakery):
		if child.get_script():
			var target_name_prop = child.get("target_name")
			var target_type_prop = child.get("target_type")

			if target_name_prop:
				var name_lower = str(target_name_prop).to_lower()

				# Storage/cabinets
				if "storage" in name_lower or "cabinet" in name_lower or "ingredient" in name_lower:
					available_equipment.storage.append(child)

				# Baking equipment
				elif "mixing" in name_lower or "bowl" in name_lower:
					available_equipment.mixing_bowls.append(child)
				elif "oven" in name_lower:
					available_equipment.ovens.append(child)

				# Checkout equipment
				elif "register" in name_lower:
					available_equipment.registers.append(child)
				elif "display" in name_lower:
					available_equipment.display_cases.append(child)

				# Cleanup equipment
				elif "sink" in name_lower:
					available_equipment.sinks.append(child)
				elif "trash" in name_lower:
					available_equipment.trash_cans.append(child)
				elif "counter" in name_lower:
					available_equipment.counters.append(child)

	print("[EmployeeAI] Found equipment - Storage:", available_equipment.storage.size(),
		  " Bowls:", available_equipment.mixing_bowls.size(), " Ovens:", available_equipment.ovens.size(),
		  " Registers:", available_equipment.registers.size(), " Sinks:", available_equipment.sinks.size())

func _get_all_children(node: Node) -> Array:
	"""Recursively get all children"""
	var result: Array = []
	for child in node.get_children():
		result.append(child)
		result.append_array(_get_all_children(child))
	return result

# ============================================================================
# STATE MACHINE
# ============================================================================

func _state_idle() -> void:
	"""Idle, checking for work based on assigned phase"""
	# Stop navigation and animation
	if nav_agent and character:
		nav_agent.target_position = character.global_position

	# Check periodically for tasks
	if Time.get_ticks_msec() / 1000.0 >= next_check_time:
		_check_for_tasks()
		next_check_time = Time.get_ticks_msec() / 1000.0 + check_interval

func _state_walking_to_target(delta: float) -> void:
	"""Walking to target position"""
	if target_position == Vector3.ZERO:
		print("[EmployeeAI] Invalid target position - returning to idle")
		current_state = EmployeeState.IDLE
		return

	_navigate_towards(target_position, delta)

	if _is_at_position(target_position):
		print("[EmployeeAI] ", employee_data["employee_name"], " reached target")
		_set_animation("walk", false)
		current_state = EmployeeState.PERFORMING_TASK
		state_timer = 0.0

func _state_performing_task(delta: float) -> void:
	"""Performing the current task"""
	# Animation already stopped when reached destination
	var time_mult: float = GameManager.get_time_scale() if GameManager else 1.0
	var performance: Dictionary = StaffManager.get_employee_performance_multiplier(employee_id, assigned_phase)
	var speed_mult: float = performance.speed

	state_timer += delta * time_mult / speed_mult  # Divide by speed_mult (higher skill = lower multiplier = faster)

	if state_timer >= action_time:
		_complete_current_task()

		# Deplete energy for completing task
		StaffManager.deplete_employee_energy(employee_id, assigned_phase)

		# Gain morale from completing task
		var morale_gain: int = BalanceConfig.STAFF.morale_events.get("task_completed", 1)
		StaffManager.adjust_employee_morale(employee_id, morale_gain, "task completed")

		# Gain XP from completing task
		StaffManager.grant_employee_xp(employee_id, assigned_phase)

		current_state = EmployeeState.IDLE
		tasks_completed += 1

func _state_waiting(delta: float) -> void:
	"""Waiting state (for future expansion)"""
	state_timer += delta
	if state_timer >= action_time:
		current_state = EmployeeState.IDLE

# ============================================================================
# TASK CHECKING (Phase-Specific)
# ============================================================================

func _check_for_tasks() -> void:
	"""Check for work based on assigned phase"""
	match assigned_phase:
		"baking":
			_check_baking_tasks()
		"checkout":
			_check_checkout_tasks()
		"cleanup":
			_check_cleanup_tasks()
		"restocking":
			_check_restocking_tasks()
		_:
			pass  # Off duty or unknown phase

func _check_baking_tasks() -> void:
	"""Check for baking tasks (priority: collect -> load -> mix)"""
	# Priority 1: Collect finished items from oven
	if _try_collect_from_oven():
		return

	# Priority 2: Load dough into empty oven
	if _try_load_oven():
		return

	# Priority 3: Start new recipe
	if _try_start_recipe():
		return

func _check_checkout_tasks() -> void:
	"""Check for customers to serve"""
	if available_equipment.registers.is_empty():
		return

	for register in available_equipment.registers:
		if register.has_method("get_waiting_customer"):
			var customer = register.get_waiting_customer()
			if customer:
				current_task = {"type": "checkout", "customer": customer, "register": register}
				target_equipment = register
				target_position = _get_node_position(register)
				current_state = EmployeeState.WALKING_TO_TARGET
				print("[EmployeeAI] ", employee_data["employee_name"], " going to serve customer")
				return

func _check_cleanup_tasks() -> void:
	"""Check for cleanup tasks (trash -> counters)"""
	# Priority 1: Empty trash
	for trash_can in available_equipment.trash_cans:
		if trash_can.has_method("needs_cleaning") and trash_can.needs_cleaning():
			current_task = {"type": "empty_trash", "equipment": trash_can}
			target_equipment = trash_can
			target_position = _get_node_position(trash_can)
			current_state = EmployeeState.WALKING_TO_TARGET
			print("[EmployeeAI] ", employee_data["employee_name"], " going to empty trash")
			return

	# Priority 2: Wipe counters
	for counter in available_equipment.counters:
		if counter.has_method("needs_cleaning") and counter.needs_cleaning():
			current_task = {"type": "wipe_counter", "equipment": counter}
			target_equipment = counter
			target_position = _get_node_position(counter)
			current_state = EmployeeState.WALKING_TO_TARGET
			print("[EmployeeAI] ", employee_data["employee_name"], " going to wipe counter")
			return

func _check_restocking_tasks() -> void:
	"""Check for restocking tasks (placeholder for future)"""
	print("[EmployeeAI] Restocking tasks not yet implemented")

# ============================================================================
# BAKING TASK HELPERS
# ============================================================================

func _try_collect_from_oven() -> bool:
	"""Try to collect finished items from ovens"""
	for oven in available_equipment.ovens:
		if "has_finished_item" in oven and oven.has_finished_item:
			current_task = {"type": "collect_oven", "oven": oven}
			target_equipment = oven
			target_position = _get_node_position(oven)
			current_state = EmployeeState.WALKING_TO_TARGET
			print("[EmployeeAI] ", employee_data["employee_name"], " going to collect from oven")
			return true
	return false

func _try_load_oven() -> bool:
	"""Try to load dough into an available oven"""
	var empty_oven = null
	for oven in available_equipment.ovens:
		if "is_baking" in oven and not oven.is_baking:
			if "has_finished_item" in oven and not oven.has_finished_item:
				empty_oven = oven
				break

	if not empty_oven:
		return false

	# Check for dough/batter in storage
	var storage_inv: Dictionary = InventoryManager.get_inventory("ingredient_storage_IngredientStorage")
	for item_id in storage_inv.keys():
		if "dough" in item_id or "batter" in item_id:
			current_task = {"type": "load_oven", "oven": empty_oven, "item_id": item_id}
			target_equipment = empty_oven
			target_position = _get_node_position(empty_oven)
			current_state = EmployeeState.WALKING_TO_TARGET
			print("[EmployeeAI] ", employee_data["employee_name"], " going to load oven with ", item_id)
			return true

	return false

func _try_start_recipe() -> bool:
	"""Try to start mixing a new recipe"""
	var available_bowl = null
	for bowl in available_equipment.mixing_bowls:
		if "is_crafting" in bowl and not bowl.is_crafting:
			available_bowl = bowl
			break

	if not available_bowl:
		return false

	# Find recipe we can make
	var unlocked_recipes: Array = RecipeManager.get_all_unlocked_recipes()
	for recipe_data in unlocked_recipes:
		var can_make: bool = true
		for ingredient in recipe_data.ingredients:
			var available_qty: int = InventoryManager.get_item_quantity("ingredient_storage_IngredientStorage", ingredient.id)
			if available_qty < ingredient.quantity:
				can_make = false
				break

		if can_make:
			current_task = {"type": "start_recipe", "bowl": available_bowl, "recipe": recipe_data}
			target_equipment = available_bowl
			target_position = _get_node_position(available_bowl)
			current_state = EmployeeState.WALKING_TO_TARGET
			print("[EmployeeAI] ", employee_data["employee_name"], " starting recipe: ", recipe_data.get("name", "unknown"))
			return true

	return false

# ============================================================================
# TASK COMPLETION
# ============================================================================

func _complete_current_task() -> void:
	"""Complete the current task based on type"""
	if current_task.is_empty():
		return

	var task_type: String = current_task.get("type", "")

	match task_type:
		"collect_oven":
			_complete_collect_oven()
		"load_oven":
			_complete_load_oven()
		"start_recipe":
			_complete_start_recipe()
		"checkout":
			_complete_checkout()
		"empty_trash":
			_complete_empty_trash()
		"wipe_counter":
			_complete_wipe_counter()

	current_task.clear()
	target_equipment = null
	target_position = Vector3.ZERO

func _complete_collect_oven() -> void:
	"""Collect baked goods from oven"""
	var oven = current_task.get("oven")
	if oven and oven.has_method("auto_collect_baked_goods"):
		oven.auto_collect_baked_goods()
		print("[EmployeeAI] ", employee_data["employee_name"], " collected baked goods")

func _complete_load_oven() -> void:
	"""Load dough into oven"""
	var oven = current_task.get("oven")
	var item_id: String = current_task.get("item_id", "")

	if oven and oven.has_method("auto_load_item"):
		if InventoryManager.remove_item("ingredient_storage_IngredientStorage", item_id, 1):
			oven.auto_load_item(item_id)
			print("[EmployeeAI] ", employee_data["employee_name"], " loaded ", item_id, " into oven")

func _complete_start_recipe() -> void:
	"""Start mixing a recipe"""
	var bowl = current_task.get("bowl")
	var recipe: Dictionary = {}
	if current_task.has("recipe"):
		recipe = current_task["recipe"]

	if not bowl or recipe.is_empty():
		return

	if not bowl.has_method("auto_start_recipe"):
		return

	# Check and remove ingredients
	var can_craft: bool = true
	for ingredient in recipe.ingredients:
		if not InventoryManager.has_item("ingredient_storage_IngredientStorage", ingredient.id, ingredient.quantity):
			can_craft = false
			break

	if can_craft:
		# Remove ingredients
		for ingredient in recipe.ingredients:
			InventoryManager.remove_item("ingredient_storage_IngredientStorage", ingredient.id, ingredient.quantity)

		# Get quality multiplier based on skill
		var performance: Dictionary = StaffManager.get_employee_performance_multiplier(employee_id, assigned_phase)
		var quality_mult: float = performance.quality

		# Start crafting
		bowl.auto_start_recipe(recipe.id, recipe, quality_mult)
		print("[EmployeeAI] ", employee_data["employee_name"], " started mixing ", recipe.get("name", "unknown"))

func _complete_checkout() -> void:
	"""Complete customer checkout"""
	var register = current_task.get("register")
	var customer = current_task.get("customer")

	if register and customer and register.has_method("auto_process_customer"):
		register.auto_process_customer(customer)
		print("[EmployeeAI] ", employee_data["employee_name"], " completed checkout")

func _complete_empty_trash() -> void:
	"""Empty trash can"""
	var trash_can = current_task.get("equipment")
	if trash_can and trash_can.has_method("auto_clean"):
		# Get quality multiplier based on cleaning skill
		var performance: Dictionary = StaffManager.get_employee_performance_multiplier(employee_id, assigned_phase)
		var quality_mult: float = performance.quality

		trash_can.auto_clean(quality_mult)
		print("[EmployeeAI] ", employee_data["employee_name"], " emptied trash")

func _complete_wipe_counter() -> void:
	"""Wipe counter"""
	var counter = current_task.get("equipment")
	if counter and counter.has_method("auto_clean"):
		# Get quality multiplier based on cleaning skill
		var performance: Dictionary = StaffManager.get_employee_performance_multiplier(employee_id, assigned_phase)
		var quality_mult: float = performance.quality

		counter.auto_clean(quality_mult)
		print("[EmployeeAI] ", employee_data["employee_name"], " wiped counter")

# ============================================================================
# MOVEMENT HELPERS
# ============================================================================

func _get_node_position(node: Node) -> Vector3:
	"""Get position from any node type"""
	if not node:
		return Vector3.ZERO
	if node is Node3D:
		return node.global_position
	return Vector3.ZERO

func _navigate_towards(target_pos: Vector3, delta: float) -> void:
	"""Navigate character towards target position"""
	if not character or not nav_agent:
		return

	if target_pos == Vector3.ZERO:
		print("[EmployeeAI] WARNING: Trying to navigate to ZERO position")
		return

	nav_agent.target_position = target_pos

	if nav_agent.is_navigation_finished():
		_set_animation("walk", false)
		return

	# Still moving - ensure animation is playing
	_set_animation("walk", true)

	var next_position = nav_agent.get_next_path_position()
	var direction = (next_position - character.global_position).normalized()

	var performance: Dictionary = StaffManager.get_employee_performance_multiplier(employee_id, assigned_phase)
	var speed_mult: float = 1.0 / performance.speed  # Invert because lower speed_mult = faster
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
	"""Cache the animation name from AnimationPlayer"""
	if not character or cached_animation_name != "":
		return

	var anim_player: AnimationPlayer = _find_animation_player_recursive(character)
	if not anim_player:
		return

	if anim_player.current_animation != "":
		cached_animation_name = anim_player.current_animation
		return

	var anims = anim_player.get_animation_list()
	if anims.size() > 0:
		cached_animation_name = anims[0]

func _set_animation(anim_name: String, playing: bool) -> void:
	"""Set character animation"""
	if not character:
		return

	var anim_player: AnimationPlayer = _find_animation_player_recursive(character)
	if not anim_player:
		return

	if playing:
		if not anim_player.is_playing() and cached_animation_name != "":
			anim_player.play(cached_animation_name)
	else:
		anim_player.stop()

func _find_animation_player_recursive(node: Node) -> AnimationPlayer:
	"""Recursively search for AnimationPlayer"""
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
