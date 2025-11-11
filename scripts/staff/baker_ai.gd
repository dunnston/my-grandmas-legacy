extends Node

# BakerAI - Automates baking during Baking Phase with realistic movement
# Bakers walk between stations: storage -> mixer -> oven -> cooling

class_name BakerAI

# Reference to the staff data
var staff_data: Dictionary
var staff_id: String

# State machine
enum BakerState {
	IDLE,                    # Standing, checking for work
	WALKING_TO_STORAGE,      # Walking to get ingredients
	GATHERING_INGREDIENTS,   # At storage getting ingredients
	WALKING_TO_MIXER,        # Walking to mixing bowl
	MIXING,                  # At mixer, mixing ingredients
	WALKING_TO_OVEN_LOAD,    # Walking to oven with dough
	LOADING_OVEN,            # Placing dough in oven
	WALKING_TO_OVEN_COLLECT, # Walking to finished oven
	COLLECTING_FROM_OVEN,    # Taking baked goods from oven
	WALKING_TO_STORAGE_DROP  # Walking to storage with finished goods
}

var is_active: bool = false
var current_state: BakerState = BakerState.IDLE
var state_timer: float = 0.0
var tasks_completed: int = 0

# Current recipe/task data
var current_recipe: Dictionary = {}
var target_equipment: Node = null  # Can be any Node type (Node3D, Control, etc.)

# AI behavior settings
var check_interval: float = 0.0
var next_check_time: float = 0.0
var action_time: float = 2.0  # Time to perform actions (gathering, mixing, etc.)

# Equipment references
var ingredient_storage: Node = null  # Can be any Node type
var available_mixing_bowls: Array = []
var available_ovens: Array = []
var storage_id: String = "ingredient_storage_IngredientStorage"

# Visual character reference
var character: Node3D = null
var nav_agent: NavigationAgent3D = null
var cached_animation_name: String = ""  # Cache the animation name for play/stop

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
	"""Activate the baker AI for this phase"""
	is_active = true
	tasks_completed = 0
	next_check_time = 0.0
	current_state = BakerState.IDLE
	check_interval = BalanceConfig.STAFF.baker_check_interval
	print("[BakerAI] ", staff_data.name, " is now working!")
	_find_equipment()

	# Initialize navigation to current position (already at target)
	if character and nav_agent:
		nav_agent.target_position = character.global_position

	# Cache animation name BEFORE stopping (so we can resume later)
	_cache_animation_name()

	# Stop walking animation - pause at current frame
	_set_animation("walk", false)

func deactivate() -> void:
	"""Deactivate the baker AI"""
	is_active = false
	current_recipe.clear()
	current_state = BakerState.IDLE
	print("[BakerAI] ", staff_data.name, " finished work. Tasks completed: ", tasks_completed)

func process(delta: float) -> void:
	"""Process AI logic each frame during Baking Phase"""
	if not is_active or not character:
		return

	# State machine
	match current_state:
		BakerState.IDLE:
			_state_idle()
		BakerState.WALKING_TO_STORAGE:
			_state_walking_to_storage(delta)
		BakerState.GATHERING_INGREDIENTS:
			_state_gathering_ingredients(delta)
		BakerState.WALKING_TO_MIXER:
			_state_walking_to_mixer(delta)
		BakerState.MIXING:
			_state_mixing(delta)
		BakerState.WALKING_TO_OVEN_LOAD:
			_state_walking_to_oven_load(delta)
		BakerState.LOADING_OVEN:
			_state_loading_oven(delta)
		BakerState.WALKING_TO_OVEN_COLLECT:
			_state_walking_to_oven_collect(delta)
		BakerState.COLLECTING_FROM_OVEN:
			_state_collecting_from_oven(delta)
		BakerState.WALKING_TO_STORAGE_DROP:
			_state_walking_to_storage_drop(delta)

func _find_equipment() -> void:
	"""Find StaffTarget markers for baker"""
	available_mixing_bowls.clear()
	available_ovens.clear()

	var bakery = get_tree().current_scene
	if not bakery:
		print("[BakerAI] ERROR: No current scene found")
		return

	# Find StaffTarget nodes
	for child in _get_all_children(bakery):
		# Check if node has the StaffTarget properties
		if child.get_script():
			var target_name_prop = child.get("target_name")
			var target_type_prop = child.get("target_type")

			# Check if this is a staff target for bakers
			if target_name_prop and target_type_prop:
				if target_type_prop == "baker" or target_type_prop == "any":
					var name_lower = str(target_name_prop).to_lower()
					if "storage" in name_lower or "cabinet" in name_lower or "ingredient" in name_lower:
						ingredient_storage = child
						print("[BakerAI] Found storage target: ", child.name)
					elif "mixing" in name_lower or "bowl" in name_lower:
						available_mixing_bowls.append(child)
						print("[BakerAI] Found mixing bowl target: ", child.name)
					elif "oven" in name_lower:
						available_ovens.append(child)
						print("[BakerAI] Found oven target: ", child.name)

	print("[BakerAI] Found ", available_mixing_bowls.size(), " mixing bowls and ", available_ovens.size(), " ovens")

	# Warn if equipment not found
	if not ingredient_storage:
		print("[BakerAI] WARNING: No storage target found! Add StaffTarget with target_name='storage' and target_type='baker'")
	if available_mixing_bowls.is_empty():
		print("[BakerAI] WARNING: No mixing bowl targets found! Add StaffTarget with target_name='mixing_bowl' and target_type='baker'")
	if available_ovens.is_empty():
		print("[BakerAI] WARNING: No oven targets found! Add StaffTarget with target_name='oven' and target_type='baker'")

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
	"""Idle, checking for work"""
	# Animation already stopped in activate() or after completing tasks
	# Make sure navigation is stopped
	if nav_agent and character:
		nav_agent.target_position = character.global_position

	# Check periodically for tasks
	if Time.get_ticks_msec() / 1000.0 >= next_check_time:
		_check_for_tasks()
		next_check_time = Time.get_ticks_msec() / 1000.0 + check_interval

func _state_walking_to_storage(delta: float) -> void:
	"""Walking to ingredient storage"""
	if not ingredient_storage:
		# Skip to gathering if no storage
		current_state = BakerState.GATHERING_INGREDIENTS
		return

	var target_pos = _get_node_position(ingredient_storage)
	_navigate_towards(target_pos, delta)

	if _is_at_position(target_pos):
		print("[BakerAI] ", staff_data.name, " reached storage")
		current_state = BakerState.GATHERING_INGREDIENTS
		state_timer = 0.0

func _state_gathering_ingredients(delta: float) -> void:
	"""Gathering ingredients from storage"""
	_set_animation("walk", false)

	var time_mult: float = GameManager.get_time_scale() if GameManager else 1.0
	var speed_mult: float = StaffManager.get_staff_speed_multiplier(staff_id)
	state_timer += delta * time_mult * speed_mult

	if state_timer >= action_time / speed_mult:
		print("[BakerAI] ", staff_data.name, " got ingredients for ", current_recipe.name)
		current_state = BakerState.WALKING_TO_MIXER

func _state_walking_to_mixer(delta: float) -> void:
	"""Walking to mixing bowl"""
	if not target_equipment:
		current_state = BakerState.IDLE
		return

	var target_pos = _get_node_position(target_equipment)
	_navigate_towards(target_pos, delta)

	if _is_at_position(target_pos):
		print("[BakerAI] ", staff_data.name, " reached mixing bowl")
		current_state = BakerState.MIXING
		state_timer = 0.0

func _state_mixing(delta: float) -> void:
	"""Mixing ingredients"""
	_set_animation("walk", false)

	var time_mult: float = GameManager.get_time_scale() if GameManager else 1.0
	var speed_mult: float = StaffManager.get_staff_speed_multiplier(staff_id)
	state_timer += delta * time_mult * speed_mult

	if state_timer >= action_time / speed_mult:
		# Remove ingredients and start crafting
		_start_mixing_recipe()
		# Now check for oven work
		current_state = BakerState.IDLE
		tasks_completed += 1

func _state_walking_to_oven_load(delta: float) -> void:
	"""Walking to oven with dough"""
	if not target_equipment:
		current_state = BakerState.IDLE
		return

	var target_pos = _get_node_position(target_equipment)
	_navigate_towards(target_pos, delta)

	if _is_at_position(target_pos):
		print("[BakerAI] ", staff_data.name, " reached oven")
		current_state = BakerState.LOADING_OVEN
		state_timer = 0.0

func _state_loading_oven(delta: float) -> void:
	"""Loading dough into oven"""
	_set_animation("walk", false)

	var time_mult: float = GameManager.get_time_scale() if GameManager else 1.0
	var speed_mult: float = StaffManager.get_staff_speed_multiplier(staff_id)
	state_timer += delta * time_mult * speed_mult

	if state_timer >= action_time / speed_mult:
		_load_oven_with_dough()
		current_state = BakerState.IDLE
		tasks_completed += 1

func _state_walking_to_oven_collect(delta: float) -> void:
	"""Walking to oven to collect finished goods"""
	if not target_equipment:
		current_state = BakerState.IDLE
		return

	var target_pos = _get_node_position(target_equipment)
	_navigate_towards(target_pos, delta)

	if _is_at_position(target_pos):
		print("[BakerAI] ", staff_data.name, " reached oven to collect")
		current_state = BakerState.COLLECTING_FROM_OVEN
		state_timer = 0.0

func _state_collecting_from_oven(delta: float) -> void:
	"""Collecting baked goods from oven"""
	_set_animation("walk", false)

	var time_mult: float = GameManager.get_time_scale() if GameManager else 1.0
	var speed_mult: float = StaffManager.get_staff_speed_multiplier(staff_id)
	state_timer += delta * time_mult * speed_mult

	if state_timer >= action_time / speed_mult:
		_collect_from_oven()
		# Move finished goods to storage (simplified - auto collected)
		current_state = BakerState.IDLE
		tasks_completed += 1

func _state_walking_to_storage_drop(delta: float) -> void:
	"""Walking back to storage with finished goods"""
	if not ingredient_storage:
		current_state = BakerState.IDLE
		return

	var target_pos = _get_node_position(ingredient_storage)
	_navigate_towards(target_pos, delta)

	if _is_at_position(target_pos):
		print("[BakerAI] ", staff_data.name, " returned to storage")
		current_state = BakerState.IDLE

# ============================================================================
# TASK CHECKING
# ============================================================================

func _check_for_tasks() -> void:
	"""Check for work - priority order"""
	# Priority 1: Collect finished items from oven
	if _try_collect_from_oven():
		return

	# Priority 2: Load dough into empty oven
	if _try_load_oven():
		return

	# Priority 3: Start new recipe
	if _try_start_recipe():
		return

func _try_collect_from_oven() -> bool:
	"""Try to collect finished items from ovens"""
	for oven in available_ovens:
		if "has_finished_item" in oven and oven.has_finished_item:
			target_equipment = oven
			current_state = BakerState.WALKING_TO_OVEN_COLLECT
			print("[BakerAI] ", staff_data.name, " going to collect from oven")
			return true
	return false

func _try_load_oven() -> bool:
	"""Try to load dough into an available oven"""
	# Find empty oven
	var empty_oven = null
	for oven in available_ovens:
		if "is_baking" in oven and not oven.is_baking:
			if "has_finished_item" in oven and not oven.has_finished_item:
				empty_oven = oven
				break

	if not empty_oven:
		return false

	# Check for dough/batter in storage
	var storage_inv: Dictionary = InventoryManager.get_inventory(storage_id)
	for item_id in storage_inv.keys():
		if "dough" in item_id or "batter" in item_id:
			target_equipment = empty_oven
			current_recipe = {"item_id": item_id}
			current_state = BakerState.WALKING_TO_OVEN_LOAD
			print("[BakerAI] ", staff_data.name, " going to load oven with ", item_id)
			return true

	return false

func _try_start_recipe() -> bool:
	"""Try to start mixing a new recipe"""
	# Find available mixing bowl
	var available_bowl = null
	for bowl in available_mixing_bowls:
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
			var available_qty: int = InventoryManager.get_item_quantity(storage_id, ingredient.id)
			if available_qty < ingredient.quantity:
				can_make = false
				break

		if can_make:
			current_recipe = recipe_data
			target_equipment = available_bowl
			current_state = BakerState.WALKING_TO_STORAGE
			print("[BakerAI] ", staff_data.name, " starting recipe: ", recipe_data.name)
			return true

	return false

# ============================================================================
# TASK COMPLETION
# ============================================================================

func _start_mixing_recipe() -> void:
	"""Remove ingredients and start mixing"""
	if not target_equipment or current_recipe.is_empty():
		return

	var bowl = target_equipment
	if not bowl.has_method("auto_start_recipe"):
		return

	# Check and remove ingredients
	var can_craft: bool = true
	for ingredient in current_recipe.ingredients:
		if not InventoryManager.has_item(storage_id, ingredient.id, ingredient.quantity):
			can_craft = false
			break

	if can_craft:
		# Remove ingredients
		for ingredient in current_recipe.ingredients:
			InventoryManager.remove_item(storage_id, ingredient.id, ingredient.quantity)

		# Apply quality multiplier
		var quality_mult: float = StaffManager.get_staff_quality_multiplier(staff_id)

		# Start crafting
		bowl.auto_start_recipe(current_recipe.id, current_recipe, quality_mult)
		print("[BakerAI] ", staff_data.name, " started mixing ", current_recipe.name)

	current_recipe.clear()
	target_equipment = null

func _load_oven_with_dough() -> void:
	"""Load dough into oven"""
	if not target_equipment or current_recipe.is_empty():
		return

	var oven = target_equipment
	var item_id: String = current_recipe.item_id

	if oven.has_method("auto_load_item"):
		if InventoryManager.remove_item(storage_id, item_id, 1):
			oven.auto_load_item(item_id)
			print("[BakerAI] ", staff_data.name, " loaded ", item_id, " into oven")

	current_recipe.clear()
	target_equipment = null

func _collect_from_oven() -> void:
	"""Collect finished baked goods"""
	if not target_equipment:
		return

	var oven = target_equipment
	if oven.has_method("auto_collect_baked_goods"):
		oven.auto_collect_baked_goods()
		print("[BakerAI] ", staff_data.name, " collected baked goods from oven")

	target_equipment = null

# ============================================================================
# MOVEMENT HELPERS
# ============================================================================

func _get_node_position(node: Node) -> Vector3:
	"""Get position from any node type"""
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
		print("[BakerAI] WARNING: Trying to navigate to ZERO position - equipment node might be wrong type!")
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
