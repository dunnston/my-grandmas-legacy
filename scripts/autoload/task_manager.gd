## TaskManager Singleton
## Manages bakery tasks, quest progression, and star rating system
extends Node

## Signals
signal star_rating_changed(new_rating: float, old_rating: float)
signal task_progress_updated(task_id: String, current: int, required: int)
signal task_completed(task: BakeryTask)
signal task_unlocked(task_id: String)
signal tasks_loaded

## Star rating (0.0 to 5.0 in 0.5 increments)
var star_rating: float = 0.0

## All tasks (main progression + optional)
var all_tasks: Dictionary = {}  # task_id -> BakeryTask

## Active tasks the player is currently working on
var active_tasks: Array[String] = []

## Completed task IDs
var completed_tasks: Array[String] = []

## Unlocked but not yet started task IDs
var unlocked_tasks: Array[String] = []


func _ready() -> void:
	# Initialize all tasks
	_initialize_tasks()

	# Connect to stat tracking signals
	_connect_tracking_signals()

	print("[TaskManager] Initialized with %d tasks" % all_tasks.size())


## Initialize all task definitions
func _initialize_tasks() -> void:
	# MAIN PROGRESSION TASKS (10 tasks, 0 → 5 stars)

	# Task 1: First Steps (0 → 0.5 stars)
	var task1 = BakeryTask.new()
	task1.task_id = "first_steps"
	task1.task_name = "First Steps"
	task1.task_description = "Clean up the initial shop and repair all broken equipment to make your bakery presentable."
	task1.task_tips = "Complete all cleanup tasks once: sweep, wipe counters, equipment check, and repair any broken items."
	task1.star_reward = 0.5
	task1.required_star_level = 0.0
	task1.is_main_task = true
	task1.task_category = "upgrades"
	task1.completion_type = "boolean"
	task1.tracked_stat = "shop_fully_cleaned"
	task1.progress_required = 1
	var unlocks1: Array[String] = ["planning_phase_access"]
	task1.unlocks = unlocks1
	all_tasks[task1.task_id] = task1
	unlocked_tasks.append(task1.task_id)

	# Task 2: First Customers (0.5 → 1.0 stars)
	var task2 = BakeryTask.new()
	task2.task_id = "first_customers"
	task2.task_name = "First Customers"
	task2.task_description = "Serve 10 happy customers to establish your bakery's reputation."
	task2.task_tips = "Focus on baking fresh items and serving customers promptly. Happy customers have high satisfaction!"
	task2.star_reward = 0.5
	task2.required_star_level = 0.5
	task2.is_main_task = true
	task2.task_category = "customer_service"
	task2.completion_type = "counter"
	task2.tracked_stat = "happy_customers_served"
	task2.progress_required = 10
	var unlocks2: Array[String] = ["recipe_group_basic_pastries"]
	task2.unlocks = unlocks2
	all_tasks[task2.task_id] = task2

	# Task 3: Rising Reputation (1.0 → 1.5 stars)
	var task3 = BakeryTask.new()
	task3.task_id = "rising_reputation"
	task3.task_name = "Rising Reputation"
	task3.task_description = "Reach 60 reputation score through consistent quality and service."
	task3.task_tips = "Maintain good customer satisfaction over multiple days. Reputation increases gradually with happy customers."
	task3.star_reward = 0.5
	task3.required_star_level = 1.0
	task3.is_main_task = true
	task3.task_category = "business_growth"
	task3.completion_type = "threshold"
	task3.tracked_stat = "reputation"
	task3.progress_required = 60
	var unlocks3: Array[String] = ["story_letter_1"]
	task3.unlocks = unlocks3
	all_tasks[task3.task_id] = task3

	# Task 4: Baking Variety (1.5 → 2.0 stars)
	var task4 = BakeryTask.new()
	task4.task_id = "baking_variety"
	task4.task_name = "Baking Variety"
	task4.task_description = "Bake at least 5 different recipes to expand your menu."
	task4.task_tips = "Experiment with different recipes! Quality doesn't matter for this task, just variety."
	task4.star_reward = 0.5
	task4.required_star_level = 1.5
	task4.is_main_task = true
	task4.task_category = "recipe_mastery"
	task4.completion_type = "collection"
	task4.tracked_stat = "unique_recipes_baked"
	task4.progress_required = 5
	var unlocks4: Array[String] = ["recipe_group_artisan_breads"]
	task4.unlocks = unlocks4
	all_tasks[task4.task_id] = task4

	# Task 5: Profitable Day (2.0 → 2.5 stars)
	var task5 = BakeryTask.new()
	task5.task_id = "profitable_day"
	task5.task_name = "Profitable Day"
	task5.task_description = "Earn $200 profit in a single day (revenue minus expenses)."
	task5.task_tips = "Manage your costs carefully! Profit = sales revenue - wages - ingredient costs - marketing."
	task5.star_reward = 0.5
	task5.required_star_level = 2.0
	task5.is_main_task = true
	task5.task_category = "business_growth"
	task5.completion_type = "threshold"
	task5.tracked_stat = "daily_profit"
	task5.progress_required = 200
	var unlocks5: Array[String] = ["staff_hiring_enabled"]
	task5.unlocks = unlocks5
	all_tasks[task5.task_id] = task5

	# Task 6: Team Player (2.5 → 3.0 stars)
	var task6 = BakeryTask.new()
	task6.task_id = "team_player"
	task6.task_name = "Team Player"
	task6.task_description = "Hire your first employee to help run the bakery."
	task6.task_tips = "Visit the staff hiring panel to review applicants and hire your first team member."
	task6.star_reward = 0.5
	task6.required_star_level = 2.5
	task6.is_main_task = true
	task6.task_category = "upgrades"
	task6.completion_type = "boolean"
	task6.tracked_stat = "employee_hired"
	task6.progress_required = 1
	var unlocks6: Array[String] = ["recipe_group_special_cakes", "story_letter_2"]
	task6.unlocks = unlocks6
	all_tasks[task6.task_id] = task6

	# Task 7: Perfectionist (3.0 → 3.5 stars)
	var task7 = BakeryTask.new()
	task7.task_id = "perfectionist"
	task7.task_name = "Perfectionist"
	task7.task_description = "Bake 25 perfect quality items to master your craft."
	task7.task_tips = "Perfect items require good timing and attention. Watch the quality meter when baking!"
	task7.star_reward = 0.5
	task7.required_star_level = 3.0
	task7.is_main_task = true
	task7.task_category = "baking_mastery"
	task7.completion_type = "counter"
	task7.tracked_stat = "perfect_items_baked"
	task7.progress_required = 25
	var unlocks7: Array[String] = []
	task7.unlocks = unlocks7
	all_tasks[task7.task_id] = task7

	# Task 8: Grandmother's Legacy (3.5 → 4.0 stars)
	var task8 = BakeryTask.new()
	task8.task_id = "grandmothers_legacy"
	task8.task_name = "Grandmother's Legacy"
	task8.task_description = "Reach 80 reputation AND earn $5,000 total revenue to honor your grandmother's memory."
	task8.task_tips = "This requires both sustained quality (reputation) and business success (revenue). Take your time!"
	task8.star_reward = 0.5
	task8.required_star_level = 3.5
	task8.is_main_task = true
	task8.task_category = "story"
	task8.completion_type = "compound"
	task8.tracked_stat = "reputation"
	task8.progress_required = 80
	task8.secondary_stat = "total_revenue"
	task8.secondary_required = 5000
	var unlocks8: Array[String] = ["recipe_group_secret_recipes", "story_letter_3", "bakery_expansion_option"]
	task8.unlocks = unlocks8
	all_tasks[task8.task_id] = task8

	# Task 9: Town Favorite (4.0 → 4.5 stars)
	var task9 = BakeryTask.new()
	task9.task_id = "town_favorite"
	task9.task_name = "Town Favorite"
	task9.task_description = "Successfully complete a food critic visit with a positive review AND serve 500 total customers."
	task9.task_tips = "Prepare for the food critic event carefully, and keep serving customers daily!"
	task9.star_reward = 0.5
	task9.required_star_level = 4.0
	task9.is_main_task = true
	task9.task_category = "special_challenge"
	task9.completion_type = "compound"
	task9.tracked_stat = "food_critic_success"
	task9.progress_required = 1
	task9.secondary_stat = "total_customers_served"
	task9.secondary_required = 500
	var unlocks9: Array[String] = ["recipe_group_international_treats", "marketing_billboard", "story_letter_4"]
	task9.unlocks = unlocks9
	all_tasks[task9.task_id] = task9

	# Task 10: Master Baker (4.5 → 5.0 stars)
	var task10 = BakeryTask.new()
	task10.task_id = "master_baker"
	task10.task_name = "Master Baker"
	task10.task_description = "Reach 95 reputation, own all tier 3+ equipment, and bake at least one legendary item from each recipe category."
	task10.task_tips = "The ultimate challenge! Requires mastery of all game systems. Good luck!"
	task10.star_reward = 0.5
	task10.required_star_level = 4.5
	task10.is_main_task = true
	task10.task_category = "baking_mastery"
	task10.completion_type = "compound"
	task10.tracked_stat = "reputation"
	task10.progress_required = 95
	task10.secondary_stat = "legendary_items_by_category"
	task10.secondary_required = 6
	var unlocks10: Array[String] = ["recipe_group_legendary_bakes", "story_letter_final", "achievement_master_baker"]
	task10.unlocks = unlocks10
	all_tasks[task10.task_id] = task10

	# TODO: Add optional tasks later

	print("[TaskManager] Loaded %d tasks" % all_tasks.size())


## Connect to existing game signals for automatic tracking
func _connect_tracking_signals() -> void:
	# Wait for other managers to be ready
	await get_tree().process_frame

	# Connect to CustomerManager
	if CustomerManager:
		if CustomerManager.has_signal("customer_left"):
			CustomerManager.customer_left.connect(_on_customer_left)
		if CustomerManager.has_signal("daily_customer_stats_ready"):
			CustomerManager.daily_customer_stats_ready.connect(_on_daily_customer_stats)

	# Connect to QualityManager for quality tracking
	if QualityManager:
		if QualityManager.has_signal("quality_calculated"):
			QualityManager.quality_calculated.connect(_on_quality_calculated)
		if QualityManager.has_signal("legendary_item_created"):
			QualityManager.legendary_item_created.connect(_on_legendary_item_created)

	# Connect to EconomyManager
	if EconomyManager:
		if EconomyManager.has_signal("daily_report_ready"):
			EconomyManager.daily_report_ready.connect(_on_daily_report_ready)
		if EconomyManager.has_signal("transaction_completed"):
			EconomyManager.transaction_completed.connect(_on_transaction_completed)

	# Connect to StaffManager
	if StaffManager:
		if StaffManager.has_signal("staff_hired"):
			StaffManager.staff_hired.connect(_on_staff_hired)

	# Connect to ProgressionManager for reputation tracking
	if ProgressionManager:
		if ProgressionManager.has_signal("reputation_changed"):
			ProgressionManager.reputation_changed.connect(_on_reputation_changed)

	# Connect to CleanlinessManager
	if CleanlinessManager:
		if CleanlinessManager.has_signal("all_chores_completed"):
			CleanlinessManager.all_chores_completed.connect(_on_all_chores_completed)

	print("[TaskManager] Connected to tracking signals")


## Update task progress
func update_task_progress(task_id: String, amount: int = 1) -> void:
	if not all_tasks.has(task_id):
		return

	var task: BakeryTask = all_tasks[task_id]

	if task.is_completed:
		return

	# Check if task is unlocked
	if not task.can_start(star_rating):
		return

	# Update progress
	task.progress_current += amount

	# Emit progress signal
	task_progress_updated.emit(task_id, task.progress_current, task.progress_required)

	# Check for completion
	if task.check_completion():
		_complete_task(task)


## Set task progress to specific value (for threshold tasks)
func set_task_progress(task_id: String, value: int) -> void:
	if not all_tasks.has(task_id):
		return

	var task: BakeryTask = all_tasks[task_id]

	if task.is_completed:
		return

	if not task.can_start(star_rating):
		return

	var old_progress = task.progress_current
	task.progress_current = value

	if old_progress != value:
		task_progress_updated.emit(task_id, task.progress_current, task.progress_required)

		if task.check_completion():
			_complete_task(task)


## Complete a task
func _complete_task(task: BakeryTask) -> void:
	if task.is_completed:
		return

	task.is_completed = true
	completed_tasks.append(task.task_id)

	# Remove from active tasks if present
	if active_tasks.has(task.task_id):
		active_tasks.erase(task.task_id)

	# Award stars
	var old_rating = star_rating
	star_rating += task.star_reward
	star_rating = clampf(star_rating, 0.0, 5.0)

	print("[TaskManager] Task completed: %s (+%.1f stars)" % [task.task_name, task.star_reward])

	# Emit signals
	star_rating_changed.emit(star_rating, old_rating)
	task_completed.emit(task)

	# Award money/reputation rewards
	if task.money_reward > 0 and EconomyManager:
		EconomyManager.add_money(task.money_reward, "Task Reward: " + task.task_name)

	if task.reputation_reward > 0 and ProgressionManager:
		ProgressionManager.modify_reputation(task.reputation_reward)

	# Process unlocks
	_process_task_unlocks(task)

	# Check for newly unlocked tasks
	_check_unlocked_tasks()


## Process task unlocks (recipes, equipment, story)
func _process_task_unlocks(task: BakeryTask) -> void:
	for unlock_id in task.unlocks:
		print("[TaskManager] Unlocking: %s" % unlock_id)

		# Recipe groups
		if unlock_id.begins_with("recipe_group_"):
			_unlock_recipe_group(unlock_id)

		# Equipment
		elif unlock_id.begins_with("equipment_"):
			_unlock_equipment(unlock_id)

		# Story letters
		elif unlock_id.begins_with("story_letter_"):
			_trigger_story_letter(unlock_id)

		# Other unlocks
		else:
			# Handle special unlocks like staff_hiring_enabled, expansion_option, etc.
			_handle_special_unlock(unlock_id)


func _unlock_recipe_group(unlock_id: String) -> void:
	"""Unlock a group of recipes based on unlock ID"""
	if not RecipeManager:
		return

	var group_name = unlock_id.replace("recipe_group_", "")
	print("[TaskManager] Unlocking recipe group: %s" % group_name)

	# Map task unlock IDs to recipe IDs
	match group_name:
		"basic_pastries":
			RecipeManager.unlock_recipe("croissants")
			RecipeManager.unlock_recipe("danish_pastries")
			RecipeManager.unlock_recipe("scones")
			RecipeManager.unlock_recipe("cinnamon_rolls")

		"artisan_breads":
			RecipeManager.unlock_recipe("sourdough_bread")
			RecipeManager.unlock_recipe("baguettes")
			RecipeManager.unlock_recipe("focaccia")
			RecipeManager.unlock_recipe("rye_bread")

		"special_cakes":
			RecipeManager.unlock_recipe("birthday_cake")
			RecipeManager.unlock_recipe("chocolate_cake")
			RecipeManager.unlock_recipe("cheesecake")
			RecipeManager.unlock_recipe("carrot_cake")

		"secret_recipes":
			RecipeManager.unlock_recipe("grandmas_apple_pie")
			RecipeManager.unlock_recipe("grandmas_cinnamon_bread")
			RecipeManager.unlock_recipe("grandmas_chocolate_brownies")

		"international_treats":
			RecipeManager.unlock_recipe("french_macarons")
			RecipeManager.unlock_recipe("german_stollen")
			RecipeManager.unlock_recipe("italian_biscotti")

		"legendary_bakes":
			RecipeManager.unlock_recipe("wedding_cake")
			RecipeManager.unlock_recipe("artisan_sourdough")
			RecipeManager.unlock_recipe("championship_croissant")


func _unlock_equipment(unlock_id: String) -> void:
	"""Unlock specific equipment"""
	# Equipment will be unlocked through UpgradeManager's star requirements
	# This is just a notification
	print("[TaskManager] Equipment available: %s" % unlock_id)


func _trigger_story_letter(unlock_id: String) -> void:
	"""Trigger a story letter to be shown"""
	if not StoryManager:
		return

	var letter_id = unlock_id.replace("story_letter_", "")
	print("[TaskManager] Triggering story letter: %s" % letter_id)

	# TODO: Call StoryManager to show the letter
	# For now, just log it


func _handle_special_unlock(unlock_id: String) -> void:
	"""Handle special unlocks like features or game systems"""
	print("[TaskManager] Special unlock: %s" % unlock_id)

	match unlock_id:
		"planning_phase_access":
			# Player can now use planning phase
			pass
		"staff_hiring_enabled":
			# Player can now hire staff
			pass
		"bakery_expansion_option":
			# Player can expand bakery
			pass
		"marketing_billboard":
			# Unlock billboard marketing option
			pass
		"achievement_master_baker":
			# Final achievement
			if AchievementManager and AchievementManager.has_method("unlock_achievement"):
				AchievementManager.unlock_achievement("master_baker")


## Check which tasks should be newly unlocked
func _check_unlocked_tasks() -> void:
	for task_id in all_tasks:
		var task: BakeryTask = all_tasks[task_id]

		if task.is_completed:
			continue

		if unlocked_tasks.has(task_id) or active_tasks.has(task_id):
			continue

		if task.can_start(star_rating):
			unlocked_tasks.append(task_id)
			task_unlocked.emit(task_id)
			print("[TaskManager] Task unlocked: %s" % task.task_name)


## Get current star rating
func get_star_rating() -> float:
	return star_rating


## Get task by ID
func get_task(task_id: String) -> BakeryTask:
	return all_tasks.get(task_id)


## Get all active tasks
func get_active_tasks() -> Array[BakeryTask]:
	var tasks: Array[BakeryTask] = []
	for task_id in active_tasks:
		if all_tasks.has(task_id):
			tasks.append(all_tasks[task_id])
	return tasks


## Get all unlocked but incomplete tasks
func get_available_tasks() -> Array[BakeryTask]:
	var tasks: Array[BakeryTask] = []
	for task_id in unlocked_tasks:
		if all_tasks.has(task_id) and not all_tasks[task_id].is_completed:
			tasks.append(all_tasks[task_id])
	return tasks


## Get all completed tasks
func get_completed_tasks() -> Array[BakeryTask]:
	var tasks: Array[BakeryTask] = []
	for task_id in completed_tasks:
		if all_tasks.has(task_id):
			tasks.append(all_tasks[task_id])
	return tasks


## Get all main progression tasks in order
func get_main_progression_tasks() -> Array[BakeryTask]:
	var tasks: Array[BakeryTask] = []
	for task_id in all_tasks:
		var task: BakeryTask = all_tasks[task_id]
		if task.is_main_task:
			tasks.append(task)

	# Sort by required star level
	tasks.sort_custom(func(a, b): return a.required_star_level < b.required_star_level)
	return tasks


## Save data
func get_save_data() -> Dictionary:
	var task_states = {}
	for task_id in all_tasks:
		task_states[task_id] = all_tasks[task_id].to_dict()

	return {
		"star_rating": star_rating,
		"completed_tasks": completed_tasks.duplicate(),
		"active_tasks": active_tasks.duplicate(),
		"unlocked_tasks": unlocked_tasks.duplicate(),
		"task_states": task_states,
		"unique_recipes_baked": unique_recipes_baked.duplicate(),
		"total_customers_served": total_customers_served,
		"happy_customers_count": happy_customers_count
	}


## Load data
func load_save_data(data: Dictionary) -> void:
	if data.has("star_rating"):
		var old_rating = star_rating
		star_rating = data.star_rating
		if old_rating != star_rating:
			star_rating_changed.emit(star_rating, old_rating)

	if data.has("completed_tasks"):
		completed_tasks = data.completed_tasks.duplicate()

	if data.has("active_tasks"):
		active_tasks = data.active_tasks.duplicate()

	if data.has("unlocked_tasks"):
		unlocked_tasks = data.unlocked_tasks.duplicate()

	if data.has("task_states"):
		for task_id in data.task_states:
			if all_tasks.has(task_id):
				all_tasks[task_id].from_dict(data.task_states[task_id])

	# Load tracking variables
	if data.has("unique_recipes_baked"):
		unique_recipes_baked = data.unique_recipes_baked.duplicate()

	if data.has("total_customers_served"):
		total_customers_served = data.total_customers_served

	if data.has("happy_customers_count"):
		happy_customers_count = data.happy_customers_count

	print("[TaskManager] Loaded save data: %.1f stars, %d completed tasks" % [star_rating, completed_tasks.size()])
	tasks_loaded.emit()


## Signal handlers for stat tracking

# Track unique recipes baked for variety task
var unique_recipes_baked: Array[String] = []

# Track total customers served
var total_customers_served: int = 0

# Track happy customers
var happy_customers_count: int = 0


func _on_customer_left(customer: Node3D, satisfaction: float) -> void:
	"""Track customer satisfaction"""
	total_customers_served += 1

	# Consider customer "happy" if satisfaction >= 75%
	if satisfaction >= 75.0:
		happy_customers_count += 1
		update_task_progress("first_customers")

	# Update town favorite task (500 total customers)
	set_task_progress("town_favorite", total_customers_served)


func _on_daily_customer_stats(total_customers: int, total_revenue: float, avg_satisfaction: float) -> void:
	"""Track daily customer statistics"""
	# This could be used for daily-based tasks
	pass


func _on_quality_calculated(item_id: String, quality: float, quality_tier: String) -> void:
	"""Track item quality for perfect items and unique recipes"""
	# Track unique recipe baked
	if not unique_recipes_baked.has(item_id):
		unique_recipes_baked.append(item_id)
		set_task_progress("baking_variety", unique_recipes_baked.size())
		print("[TaskManager] Unique recipe baked: %s (%d/%d)" % [item_id, unique_recipes_baked.size(), 5])

	# Perfect quality is tier "Perfect" or quality >= 90
	if quality_tier == "Perfect" or quality >= 90.0:
		update_task_progress("perfectionist")


func _on_legendary_item_created(item_id: String, quality: float) -> void:
	"""Track legendary item creation"""
	# TODO: Track legendary items by recipe category for task 10 (master_baker)
	pass


func _on_daily_report_ready(revenue: float, expenses: float, profit: float) -> void:
	"""Track daily profit"""
	# Check if this day's profit beats the requirement for profitable_day task
	set_task_progress("profitable_day", int(profit))


func _on_staff_hired(staff_data: Dictionary) -> void:
	"""Track employee hiring"""
	update_task_progress("team_player")


func _on_reputation_changed(new_rep: int) -> void:
	"""Track reputation changes"""
	# Update reputation threshold tasks
	set_task_progress("rising_reputation", new_rep)
	set_task_progress("grandmothers_legacy", new_rep)
	set_task_progress("master_baker", new_rep)

	# Check compound tasks
	_check_compound_task_completion("grandmothers_legacy")
	_check_compound_task_completion("master_baker")


func _on_all_chores_completed() -> void:
	"""Track shop cleaning completion"""
	update_task_progress("first_steps")


func _on_transaction_completed(amount: float, description: String, is_income: bool) -> void:
	"""Track transactions for revenue-based compound tasks"""
	if is_income and ProgressionManager:
		var total_revenue = ProgressionManager.get_total_revenue()
		# Check compound tasks that require total revenue
		_check_compound_task_completion("grandmothers_legacy")


func _check_compound_task_completion(task_id: String) -> void:
	"""Check if a compound task meets all its requirements"""
	if not all_tasks.has(task_id):
		return

	var task: BakeryTask = all_tasks[task_id]

	if task.is_completed or task.completion_type != "compound":
		return

	# Check if all requirements are met
	var primary_met = task.progress_current >= task.progress_required
	var secondary_met = false

	# Check secondary requirement
	if task.secondary_stat == "total_revenue" and ProgressionManager:
		var total_revenue = ProgressionManager.get_total_revenue()
		secondary_met = total_revenue >= task.secondary_required
	elif task.secondary_stat == "total_customers_served":
		secondary_met = total_customers_served >= task.secondary_required
	elif task.secondary_stat == "food_critic_success":
		# TODO: Implement food critic tracking
		secondary_met = false
	elif task.secondary_stat == "legendary_items_by_category":
		# TODO: Implement legendary items by category tracking
		secondary_met = false
	else:
		# No secondary requirement
		secondary_met = true

	# Complete task if both requirements are met
	if primary_met and secondary_met and not task.is_completed:
		_complete_task(task)
