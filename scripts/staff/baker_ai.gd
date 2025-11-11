extends Node

# BakerAI - Automates baking during Baking Phase
# Bakers automatically craft recipes based on their skill level

class_name BakerAI

# Reference to the staff data
var staff_data: Dictionary
var staff_id: String

# State
var is_active: bool = false
var current_task: Dictionary = {}
var task_timer: float = 0.0
var tasks_completed: int = 0

# AI behavior settings
var check_interval: float = 0.0  # Loaded from BalanceConfig
var next_check_time: float = 0.0

# Equipment references (found at runtime)
var available_mixing_bowls: Array = []
var available_ovens: Array = []

func _init(p_staff_id: String, p_staff_data: Dictionary) -> void:
	staff_id = p_staff_id
	staff_data = p_staff_data

func activate() -> void:
	"""Activate the baker AI for this phase"""
	is_active = true
	tasks_completed = 0
	next_check_time = 0.0
	check_interval = BalanceConfig.STAFF.baker_check_interval
	print("[BakerAI] ", staff_data.name, " is now working!")
	_find_equipment()

func deactivate() -> void:
	"""Deactivate the baker AI"""
	is_active = false
	current_task.clear()
	print("[BakerAI] ", staff_data.name, " finished work. Tasks completed: ", tasks_completed)

func process(delta: float) -> void:
	"""Process AI logic each frame during Baking Phase"""
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

func _find_equipment() -> void:
	"""Find available equipment in the bakery"""
	available_mixing_bowls.clear()
	available_ovens.clear()

	# Get the bakery scene
	var bakery = get_tree().current_scene
	if not bakery:
		return

	# Find mixing bowls
	for child in _get_all_children(bakery):
		if child.has_method("get_inventory_id"):
			if "mixing_bowl" in child.name.to_lower():
				available_mixing_bowls.append(child)
			elif "oven" in child.name.to_lower():
				available_ovens.append(child)

	print("[BakerAI] Found ", available_mixing_bowls.size(), " mixing bowls and ", available_ovens.size(), " ovens")

func _get_all_children(node: Node) -> Array:
	"""Recursively get all children of a node"""
	var result: Array = []
	for child in node.get_children():
		result.append(child)
		result.append_array(_get_all_children(child))
	return result

func _check_for_tasks() -> void:
	"""Check if there's work to be done"""
	# Priority 1: Move baked goods from oven to storage
	if _try_collect_from_oven():
		return

	# Priority 2: Load prepared dough into oven
	if _try_load_oven():
		return

	# Priority 3: Start mixing a recipe
	if _try_start_recipe():
		return

	# No tasks available
	# print("[BakerAI] ", staff_data.name, " is idle - no tasks available")

func _try_collect_from_oven() -> bool:
	"""Try to collect finished items from ovens"""
	for oven in available_ovens:
		if not oven.is_baking and oven.has_finished_item:
			# Found finished item - collect it
			current_task = {
				"type": "collect_oven",
				"equipment": oven,
				"duration": 2.0  # 2 seconds to collect
			}
			task_timer = 0.0
			print("[BakerAI] ", staff_data.name, " collecting from oven...")
			return true
	return false

func _try_load_oven() -> bool:
	"""Try to load dough into an available oven"""
	# Find an empty oven
	var empty_oven = null
	for oven in available_ovens:
		if not oven.is_baking and not oven.has_finished_item:
			empty_oven = oven
			break

	if not empty_oven:
		return false

	# Check if we have any dough/batter in storage
	var storage_id: String = "ingredient_storage_IngredientStorage"
	var storage_inv: Dictionary = InventoryManager.get_inventory(storage_id)

	for item_id in storage_inv.keys():
		if "dough" in item_id or "batter" in item_id:
			# Found dough - load it into oven
			current_task = {
				"type": "load_oven",
				"equipment": empty_oven,
				"item_id": item_id,
				"duration": 3.0  # 3 seconds to load
			}
			task_timer = 0.0
			print("[BakerAI] ", staff_data.name, " loading ", item_id, " into oven...")
			return true

	return false

func _try_start_recipe() -> bool:
	"""Try to start mixing a new recipe"""
	# Find an available mixing bowl
	var available_bowl = null
	for bowl in available_mixing_bowls:
		if not bowl.is_crafting:
			available_bowl = bowl
			break

	if not available_bowl:
		return false

	# Get unlocked recipes and pick one we can make
	var unlocked_recipes: Array = RecipeManager.get_all_unlocked_recipes()
	var storage_id: String = "ingredient_storage_IngredientStorage"

	for recipe_data in unlocked_recipes:
		var recipe_id: String = recipe_data.id
		var ingredients: Array = recipe_data.ingredients

		# Check if we have all ingredients
		var can_make: bool = true
		for ingredient in ingredients:
			var required_qty: int = ingredient.quantity
			var available_qty: int = InventoryManager.get_item_quantity(storage_id, ingredient.id)

			if available_qty < required_qty:
				can_make = false
				break

		if can_make:
			# Start this recipe
			current_task = {
				"type": "start_mixing",
				"equipment": available_bowl,
				"recipe_id": recipe_id,
				"recipe_data": recipe_data,
				"duration": 4.0  # 4 seconds to gather and start
			}
			task_timer = 0.0
			print("[BakerAI] ", staff_data.name, " starting recipe: ", recipe_data.name)
			return true

	return false

func _process_current_task(delta: float) -> void:
	"""Process the current task"""
	if not GameManager:
		return

	# Apply time scale and staff speed multiplier
	var time_mult: float = GameManager.get_time_scale()
	var speed_mult: float = StaffManager.get_staff_speed_multiplier(staff_id)
	task_timer += delta * time_mult * speed_mult

	if task_timer >= current_task.duration:
		_complete_current_task()

func _complete_current_task() -> void:
	"""Complete the current task"""
	match current_task.type:
		"collect_oven":
			_complete_collect_oven()
		"load_oven":
			_complete_load_oven()
		"start_mixing":
			_complete_start_mixing()

	tasks_completed += 1
	current_task.clear()
	task_timer = 0.0

func _complete_collect_oven() -> void:
	"""Complete collecting from oven"""
	var oven = current_task.equipment
	if oven and oven.has_method("auto_collect_baked_goods"):
		oven.auto_collect_baked_goods()
		print("[BakerAI] ", staff_data.name, " collected baked goods from oven")

func _complete_load_oven() -> void:
	"""Complete loading oven"""
	var oven = current_task.equipment
	var item_id: String = current_task.item_id

	if oven and oven.has_method("auto_load_item"):
		# Remove from storage
		var storage_id: String = "ingredient_storage_IngredientStorage"
		if InventoryManager.remove_item(storage_id, item_id, 1):
			oven.auto_load_item(item_id)
			print("[BakerAI] ", staff_data.name, " loaded ", item_id, " into oven")

func _complete_start_mixing() -> void:
	"""Complete starting mixing"""
	var bowl = current_task.equipment
	var recipe_id: String = current_task.recipe_id
	var recipe_data: Dictionary = current_task.recipe_data

	if bowl and bowl.has_method("auto_start_recipe"):
		# Remove ingredients from storage
		var storage_id: String = "ingredient_storage_IngredientStorage"
		var can_craft: bool = true

		for ingredient in recipe_data.ingredients:
			if not InventoryManager.has_item(storage_id, ingredient.id, ingredient.quantity):
				can_craft = false
				break

		if can_craft:
			# Remove ingredients
			for ingredient in recipe_data.ingredients:
				InventoryManager.remove_item(storage_id, ingredient.id, ingredient.quantity)

			# Apply quality multiplier from staff skill
			var quality_mult: float = StaffManager.get_staff_quality_multiplier(staff_id)

			# Start crafting
			bowl.auto_start_recipe(recipe_id, recipe_data, quality_mult)
			print("[BakerAI] ", staff_data.name, " started mixing ", recipe_data.name)
