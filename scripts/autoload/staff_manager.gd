extends Node

# StaffManager - Singleton for managing hired staff and automation
# Handles hiring, firing, wages, skill progression, and AI task automation

# Signals
signal staff_hired(staff_data: Dictionary)
signal staff_fired(staff_id: String)
signal staff_skill_improved(staff_id: String, skill_name: String, new_value: int)
signal applicants_refreshed(applicants: Array)
signal wages_paid(total_amount: float)
signal staff_raised(staff_id: String, new_wage: float)
signal staff_bonus_given(staff_id: String, amount: float)

# Save version for migration handling
const SAVE_VERSION: int = 2  # Version 1 = old role-based system

# Staff state
var hired_staff: Dictionary = {}  # staff_id -> staff_data
var applicant_pool: Array = []    # Available applicants (refreshes weekly)
var max_staff_slots: int = 3      # Upgradeable (loaded from BalanceConfig)
var next_staff_id: int = 1

# AI instances (created when staff activated)
var active_ai_workers: Dictionary = {}  # staff_id -> AI instance

# Visual character instances
var staff_characters: Dictionary = {}  # staff_id -> Node3D character

# Staff spawning and navigation
var entrance_position: Vector3 = Vector3(-8, 0, -4)  # Default entrance (same as customers)
var staff_walking_to_station: Dictionary = {}  # staff_id -> { character, target_pos, ai_type, staff_data }

# Employee scene for visual representation
var employee_scene: PackedScene = preload("res://scenes/employees/employee.tscn")

# Staff generation settings
var staff_names: Array = [
	"Alice", "Bob", "Carlos", "Diana", "Emma", "Frank", "Grace", "Henry",
	"Iris", "Jack", "Kelly", "Leo", "Maria", "Noah", "Olivia", "Peter",
	"Quinn", "Rachel", "Sam", "Taylor", "Uma", "Victor", "Wendy", "Xavier"
]

# Balance values (loaded from BalanceConfig on ready)
# Note: Skill-based system no longer uses fixed wage/speed/quality dictionaries
# Wages calculated dynamically based on total skill points
# Performance calculated from individual skill values (0-100)

func _ready() -> void:
	# Load balance values from BalanceConfig
	_load_balance_config()

	print("StaffManager initialized")
	# Connect to day change and phase change signals
	if GameManager:
		GameManager.day_changed.connect(_on_day_changed)
		GameManager.shop_state_changed.connect(_on_shop_state_changed)

	# Generate initial applicant pool
	refresh_applicants()

func _load_balance_config() -> void:
	"""Load all staff balance parameters from BalanceConfig"""
	max_staff_slots = BalanceConfig.STAFF.max_staff_slots
	# Skill-based system - config will be loaded as needed from BalanceConfig.STAFF

func set_entrance_position(position: Vector3) -> void:
	"""Set the entrance position where staff will spawn (called by bakery scene)"""
	entrance_position = position
	print("[StaffManager] Entrance position set to: ", position)

func _process(delta: float) -> void:
	"""Process all active AI workers and staff walking to stations"""
	# Update staff walking to their stations
	_process_staff_walking_to_station(delta)

	# Process active AI workers
	for staff_id in active_ai_workers.keys():
		var ai_worker = active_ai_workers[staff_id]
		if ai_worker and ai_worker.has_method("process"):
			ai_worker.process(delta)

# ============================================================================
# HIRING & FIRING
# ============================================================================

func hire_staff(applicant_data: Dictionary) -> bool:
	"""Hire a staff member from applicant pool"""
	if get_hired_staff_count() >= max_staff_slots:
		print("Cannot hire - staff slots full")
		return false

	# Check if can afford first day's wage
	var daily_wage: float = applicant_data["base_wage"]
	if EconomyManager.get_current_cash() < daily_wage:
		print("Cannot hire - insufficient funds for wage")
		return false

	# Create employee record with new skill-based structure
	var employee_id: String = "employee_%d" % next_staff_id
	next_staff_id += 1

	var employee_data: Dictionary = {
		# Identity
		"employee_id": employee_id,
		"employee_name": applicant_data["employee_name"],
		"portrait": null,  # For future expansion
		"hire_date": GameManager.current_day if GameManager else 1,

		# Skills (0-100 each)
		"culinary_skill": applicant_data["culinary_skill"],
		"customer_service_skill": applicant_data["customer_service_skill"],
		"cleaning_skill": applicant_data["cleaning_skill"],
		"organization_skill": applicant_data["organization_skill"],

		# Attributes
		"energy": 100,  # Start at full energy
		"morale": 80,   # Start at good morale
		"experience_points": 0,
		"days_employed": 0,

		# Employment
		"base_wage": applicant_data["base_wage"],
		"assigned_phase": applicant_data.get("assigned_phase", "none"),  # Default to unassigned
		"current_task": "",

		# Traits (copy from applicant)
		"traits": []
	}

	# Copy traits if present
	if applicant_data.has("traits"):
		employee_data["traits"] = applicant_data["traits"].duplicate()

	hired_staff[employee_id] = employee_data

	# Remove from applicant pool
	applicant_pool.erase(applicant_data)

	print("[StaffManager] Hired ", employee_data["employee_name"], " - Wage: $", employee_data["base_wage"], "/day")
	print("[StaffManager] Skills - Culinary:", employee_data["culinary_skill"], " Service:", employee_data["customer_service_skill"],
		  " Cleaning:", employee_data["cleaning_skill"], " Organization:", employee_data["organization_skill"])
	print("[StaffManager] Total staff now: ", hired_staff.size(), "/", max_staff_slots)
	staff_hired.emit(employee_data)
	return true

func fire_staff(employee_id: String) -> void:
	"""Fire a staff member"""
	if not hired_staff.has(employee_id):
		print("Cannot fire - employee not found: ", employee_id)
		return

	var employee_data: Dictionary = hired_staff[employee_id]
	print("[StaffManager] Fired ", employee_data["employee_name"])

	hired_staff.erase(employee_id)
	staff_fired.emit(employee_id)

# ============================================================================
# APPLICANT POOL
# ============================================================================

func refresh_applicants() -> void:
	"""Generate new applicant pool (called weekly)"""
	applicant_pool.clear()

	# Generate random applicants (using BalanceConfig range)
	var num_applicants: int = randi_range(
		BalanceConfig.STAFF.applicant_pool_size_min,
		BalanceConfig.STAFF.applicant_pool_size_max
	)

	for i in range(num_applicants):
		var applicant: Dictionary = _generate_random_applicant()
		applicant_pool.append(applicant)

	print("Applicant pool refreshed: ", num_applicants, " applicants")
	applicants_refreshed.emit(applicant_pool)

func _generate_random_applicant() -> Dictionary:
	"""Generate a random employee applicant using archetypes and traits from BalanceConfig"""
	var employee_name: String = staff_names[randi() % staff_names.size()]

	# Select archetype based on spawn weights
	var archetype_name: String = _select_random_archetype()
	var archetype_data: Dictionary = BalanceConfig.STAFF.archetypes[archetype_name]

	# Generate skills based on archetype
	var culinary_skill: int
	var customer_service_skill: int
	var cleaning_skill: int
	var organization_skill: int

	if archetype_name == "Specialist":
		# Specialist: one skill high, others low
		var skills: Array = ["culinary", "customer_service", "cleaning", "organization"]
		var chosen_skill: String = skills[randi() % skills.size()]
		var high_range: Array = archetype_data.high_skill
		var low_range: Array = archetype_data.low_skills

		culinary_skill = randi_range(high_range[0], high_range[1]) if chosen_skill == "culinary" else randi_range(low_range[0], low_range[1])
		customer_service_skill = randi_range(high_range[0], high_range[1]) if chosen_skill == "customer_service" else randi_range(low_range[0], low_range[1])
		cleaning_skill = randi_range(high_range[0], high_range[1]) if chosen_skill == "cleaning" else randi_range(low_range[0], low_range[1])
		organization_skill = randi_range(high_range[0], high_range[1]) if chosen_skill == "organization" else randi_range(low_range[0], low_range[1])
	else:
		# Standard archetypes: use defined ranges for each skill
		var cul_range: Array = archetype_data.culinary_skill
		var cs_range: Array = archetype_data.customer_service_skill
		var clean_range: Array = archetype_data.cleaning_skill
		var org_range: Array = archetype_data.organization_skill

		culinary_skill = randi_range(cul_range[0], cul_range[1])
		customer_service_skill = randi_range(cs_range[0], cs_range[1])
		cleaning_skill = randi_range(clean_range[0], clean_range[1])
		organization_skill = randi_range(org_range[0], org_range[1])

	# Generate traits (0-2 random traits based on spawn chance)
	var traits: Array = _generate_random_traits()

	# Apply trait bonuses to skills
	for trait_name in traits:
		if not BalanceConfig.STAFF.traits.has(trait_name):
			continue
		var trait_data: Dictionary = BalanceConfig.STAFF.traits[trait_name]
		if trait_data.has("customer_service_bonus"):
			customer_service_skill = mini(customer_service_skill + trait_data.customer_service_bonus, 100)

	# Calculate wage based on total skill points
	# Formula: base_wage = 30 + (total_skills / 10)
	var total_skills: int = culinary_skill + customer_service_skill + cleaning_skill + organization_skill
	var base_wage: float = 30.0 + (total_skills / 10.0)

	# Assign default phase (will be set by player during hiring or after)
	var assigned_phase: String = "none"  # Unassigned by default

	return {
		"employee_name": employee_name,
		"archetype": archetype_name,
		"culinary_skill": culinary_skill,
		"customer_service_skill": customer_service_skill,
		"cleaning_skill": cleaning_skill,
		"organization_skill": organization_skill,
		"base_wage": base_wage,
		"assigned_phase": assigned_phase,
		"traits": traits
	}

func _select_random_archetype() -> String:
	"""Select a random archetype based on spawn weights"""
	var roll: float = randf()
	var cumulative: float = 0.0
	var archetypes: Dictionary = BalanceConfig.STAFF.archetypes

	for archetype_name in archetypes.keys():
		cumulative += archetypes[archetype_name].spawn_weight
		if roll < cumulative:
			return archetype_name

	# Fallback (should never reach here if weights sum properly)
	return "All-Rounder"

func _generate_random_traits() -> Array:
	"""Generate 0-2 random traits based on spawn chance"""
	var traits: Array = []
	var trait_data: Dictionary = BalanceConfig.STAFF.traits
	var num_traits: int = randi() % 3  # 0, 1, or 2 traits

	# Create pool of available traits
	var available_traits: Array = trait_data.keys()
	available_traits.shuffle()

	for i in range(num_traits):
		if i >= available_traits.size():
			break

		var trait_name: String = available_traits[i]
		var trait_info: Dictionary = trait_data[trait_name]
		var spawn_chance: float = trait_info.get("spawn_chance", 0.0)

		# Roll for this trait
		if randf() < spawn_chance:
			traits.append(trait_name)

	return traits

# ============================================================================
# WAGES & PROGRESSION
# ============================================================================

func pay_daily_wages() -> float:
	"""Pay all staff their daily wages (called at end of day)"""
	var total_wages: float = 0.0

	for employee_id in hired_staff.keys():
		var employee_data: Dictionary = hired_staff[employee_id]
		var daily_wage: float = employee_data["base_wage"]

		total_wages += daily_wage
		employee_data["days_employed"] += 1

		# Gain experience points (will be used for skill improvements in Phase 8)
		# For now, just increment days_employed

	if total_wages > 0:
		EconomyManager.remove_cash(total_wages, "Staff wages")
		print("[StaffManager] Paid $%.2f in staff wages" % total_wages)
		wages_paid.emit(total_wages)

	return total_wages

func grant_employee_xp(employee_id: String, phase: String) -> void:
	"""Grant XP to employee for completing a task in their assigned phase"""
	if not hired_staff.has(employee_id):
		return

	var employee_data: Dictionary = hired_staff[employee_id]
	var xp_gain: int = BalanceConfig.STAFF.xp_per_task

	# Check for Quick Learner trait (bonus XP)
	var traits: Array = []
	if employee_data.has("traits"):
		traits = employee_data["traits"]
	if "Quick Learner" in traits and BalanceConfig.STAFF.traits.has("Quick Learner"):
		var trait_data: Dictionary = BalanceConfig.STAFF.traits["Quick Learner"]
		var multiplier: float = trait_data.get("xp_multiplier", 1.0)
		xp_gain = int(xp_gain * multiplier)

	# Grant XP
	employee_data.experience_points = employee_data.get("experience_points", 0) + xp_gain

	# Check for skill improvement
	_check_skill_improvement(employee_id, phase)

func _check_skill_improvement(employee_id: String, phase: String) -> void:
	"""Check if employee should improve a skill based on XP"""
	if not hired_staff.has(employee_id):
		return

	var employee_data: Dictionary = hired_staff[employee_id]
	var xp: int = employee_data.get("experience_points", 0)
	var xp_threshold: int = BalanceConfig.STAFF.xp_for_skill_point

	# Check if enough XP for skill improvement
	if xp >= xp_threshold:
		# Deduct XP
		employee_data["experience_points"] = xp - xp_threshold

		# Determine which skill to improve based on phase
		var skill_to_improve: String = _get_skill_for_phase(phase)

		if skill_to_improve != "":
			var current_value: int = employee_data.get(skill_to_improve, 0)
			var max_skill: int = BalanceConfig.STAFF.max_skill

			# Improve skill (cap at max)
			if current_value < max_skill:
				employee_data[skill_to_improve] = current_value + 1
				print("[StaffManager] ", employee_data["employee_name"], " improved ", skill_to_improve, ": ", current_value, " -> ", current_value + 1)
				staff_skill_improved.emit(employee_id, skill_to_improve, current_value + 1)

func _get_skill_for_phase(phase: String) -> String:
	"""Get the skill name associated with a phase"""
	match phase:
		"baking":
			return "culinary_skill"
		"checkout":
			return "customer_service_skill"
		"cleanup":
			return "cleaning_skill"
		"restocking":
			return "organization_skill"
		_:
			return ""

func _on_day_changed(new_day: int) -> void:
	"""Called when day changes - pay wages, update morale, handle weekly events"""
	pay_daily_wages()

	# Update morale and energy at end of day
	_process_daily_morale_and_energy()

	# Check for auto-quits due to low morale
	_check_employee_auto_quit()

	# Refresh applicants weekly (using BalanceConfig interval)
	if new_day % BalanceConfig.STAFF.get("applicant_refresh_days", 7) == 0:
		refresh_applicants()

# ============================================================================
# GETTERS
# ============================================================================

func get_hired_staff_count() -> int:
	"""Get number of currently hired employees"""
	return hired_staff.size()

func get_staff_by_phase(phase: String) -> Array:
	"""Get all hired employees assigned to a specific phase"""
	var result: Array = []
	for employee_data in hired_staff.values():
		if employee_data["assigned_phase"] == phase:
			result.append(employee_data)
	return result

func has_staff_in_phase(phase: String) -> bool:
	"""Check if any employee is assigned to this phase"""
	return get_staff_by_phase(phase).size() > 0

func get_employee_skill_for_phase(employee_id: String, phase: String) -> int:
	"""Get the relevant skill value (0-100) for an employee in a specific phase"""
	if not hired_staff.has(employee_id):
		return 0

	var employee_data: Dictionary = hired_staff[employee_id]

	match phase:
		"baking":
			return employee_data["culinary_skill"]
		"checkout":
			return employee_data["customer_service_skill"]
		"cleanup":
			return employee_data["cleaning_skill"]
		"restocking":
			return employee_data["organization_skill"]
		_:
			return 0

func get_employee_performance_multiplier(employee_id: String, phase: String) -> Dictionary:
	"""Get speed and quality multipliers based on skills, energy, and morale"""
	if not hired_staff.has(employee_id):
		return {"speed": 1.0, "quality": 1.0}

	var employee_data: Dictionary = hired_staff[employee_id]
	var skill_value: int = get_employee_skill_for_phase(employee_id, phase)

	# Calculate multipliers based on skill (0-100), energy (0-100), morale (0-100)
	# Speed: skill affects time taken (higher skill = faster)
	# Formula: time_mult = 2.0 - (skill/100) → ranges from 2.0x (slow) to 1.0x (baseline)
	var speed_mult: float = 2.0 - (skill_value / 100.0)

	# Quality: skill, energy, and morale all affect quality
	# Formula: quality_mult = (skill/100) * (energy/100) * (morale/100)
	var energy_factor: float = employee_data["energy"] / 100.0
	var morale_factor: float = employee_data["morale"] / 100.0
	var quality_mult: float = (skill_value / 100.0) * energy_factor * morale_factor

	return {
		"speed": speed_mult,
		"quality": quality_mult
	}

func get_total_daily_wages() -> float:
	"""Calculate total daily wages for all hired staff"""
	var total: float = 0.0
	for employee_data in hired_staff.values():
		total += employee_data["base_wage"]
	return total

func get_applicant_pool() -> Array:
	"""Get current applicant pool"""
	return applicant_pool

func can_afford_staff(applicant_data: Dictionary) -> bool:
	"""Check if player can afford to hire this applicant"""
	var daily_wage: float = applicant_data["base_wage"]
	return EconomyManager.get_current_cash() >= daily_wage

# ============================================================================
# EMPLOYEE MANAGEMENT METHODS
# ============================================================================

func assign_staff_to_phase(employee_id: String, phase: String) -> bool:
	"""Assign an employee to a specific phase (baking, checkout, cleanup, restocking, none)"""
	if not hired_staff.has(employee_id):
		print("[StaffManager] Cannot assign - employee not found: ", employee_id)
		return false

	var valid_phases: Array = ["baking", "checkout", "cleanup", "restocking", "none"]
	if not phase in valid_phases:
		print("[StaffManager] Invalid phase: ", phase)
		return false

	var employee_data: Dictionary = hired_staff[employee_id]
	var old_phase: String = employee_data["assigned_phase"]
	employee_data["assigned_phase"] = phase

	print("[StaffManager] Assigned ", employee_data["employee_name"], " from ", old_phase, " to ", phase)
	return true

func give_raise(employee_id: String, amount: float) -> bool:
	"""Give an employee a permanent wage raise"""
	if not hired_staff.has(employee_id):
		print("[StaffManager] Cannot give raise - employee not found: ", employee_id)
		return false

	if amount <= 0:
		print("[StaffManager] Raise amount must be positive")
		return false

	var employee_data: Dictionary = hired_staff[employee_id]
	employee_data["base_wage"] += amount

	print("[StaffManager] Gave ", employee_data["employee_name"], " a $", amount, " raise (new wage: $", employee_data["base_wage"], "/day)")
	staff_raised.emit(employee_id, employee_data["base_wage"])
	return true

func give_bonus(employee_id: String, amount: float, morale_boost: int = 10) -> bool:
	"""Give an employee a one-time bonus (costs money, boosts morale)"""
	if not hired_staff.has(employee_id):
		print("[StaffManager] Cannot give bonus - employee not found: ", employee_id)
		return false

	if amount <= 0:
		print("[StaffManager] Bonus amount must be positive")
		return false

	if EconomyManager.get_current_cash() < amount:
		print("[StaffManager] Cannot afford bonus - insufficient funds")
		return false

	var employee_data: Dictionary = hired_staff[employee_id]

	# Deduct cost
	EconomyManager.remove_cash(amount, "Employee bonus for " + employee_data["employee_name"])

	# Boost morale (cap at 100)
	employee_data["morale"] = mini(employee_data["morale"] + morale_boost, 100)

	print("[StaffManager] Gave ", employee_data["employee_name"], " a $", amount, " bonus (+", morale_boost, " morale)")
	staff_bonus_given.emit(employee_id, amount)
	return true

# ============================================================================
# ENERGY & MORALE SYSTEMS
# ============================================================================

func deplete_employee_energy(employee_id: String, task_type: String) -> void:
	"""Deplete energy when employee completes a task"""
	if not hired_staff.has(employee_id):
		return

	var employee_data: Dictionary = hired_staff[employee_id]
	var energy_cost: int = BalanceConfig.STAFF.energy_cost_per_task.get(task_type, 3)

	# Check for Night Owl trait (reduces energy drain)
	var traits: Array = []
	if employee_data.has("traits"):
		traits = employee_data["traits"]
	if "Night Owl" in traits and BalanceConfig.STAFF.traits.has("Night Owl"):
		var trait_data: Dictionary = BalanceConfig.STAFF.traits["Night Owl"]
		var reduction: float = trait_data.get("energy_drain_reduction", 0.0)
		energy_cost = int(energy_cost * (1.0 - reduction))

	# Deplete energy (minimum 0)
	employee_data["energy"] = maxi(employee_data["energy"] - energy_cost, 0)

	# Low energy affects morale
	if employee_data["energy"] < BalanceConfig.STAFF.low_energy_threshold:
		var morale_penalty: int = BalanceConfig.STAFF.morale_events.get("low_energy_penalty", -2)
		adjust_employee_morale(employee_id, morale_penalty, "low energy")

func regenerate_employee_energy(employee_id: String) -> void:
	"""Regenerate energy when employee is off duty"""
	if not hired_staff.has(employee_id):
		return

	var employee_data: Dictionary = hired_staff[employee_id]
	var regen_amount: int = BalanceConfig.STAFF.energy_regen_per_phase

	# Check for Morning Person trait (bonus regeneration)
	var traits: Array = []
	if employee_data.has("traits"):
		traits = employee_data["traits"]
	if "Morning Person" in traits and BalanceConfig.STAFF.traits.has("Morning Person"):
		var trait_data: Dictionary = BalanceConfig.STAFF.traits["Morning Person"]
		regen_amount += trait_data.get("energy_regen_bonus", 0)

	# Regenerate energy (cap at max)
	employee_data["energy"] = mini(employee_data["energy"] + regen_amount, BalanceConfig.STAFF.max_energy)

func adjust_employee_morale(employee_id: String, amount: int, reason: String = "") -> void:
	"""Adjust employee morale (positive or negative)"""
	if not hired_staff.has(employee_id):
		return

	var employee_data: Dictionary = hired_staff[employee_id]
	var old_morale: int = employee_data["morale"]

	# Apply morale change (cap at 0-100)
	employee_data["morale"] = clampi(employee_data["morale"] + amount, 0, 100)

	if amount != 0:
		var change_str: String = "+" if amount > 0 else ""
		print("[StaffManager] ", employee_data["employee_name"], " morale: ", old_morale, " -> ", employee_data["morale"], " (", change_str, amount, " ", reason, ")")

func _process_daily_morale_and_energy() -> void:
	"""Process daily morale decay and energy recovery"""
	for employee_id in hired_staff.keys():
		var employee_data: Dictionary = hired_staff[employee_id]

		# Natural morale decay
		var decay: int = BalanceConfig.STAFF.morale_daily_decay
		adjust_employee_morale(employee_id, -decay, "daily decay")

		# Penalty for no assignment
		if employee_data["assigned_phase"] == "none":
			var penalty: int = BalanceConfig.STAFF.morale_events.get("no_assignment", -3)
			adjust_employee_morale(employee_id, penalty, "no assignment")

		# Regenerate energy to full overnight
		employee_data["energy"] = BalanceConfig.STAFF.max_energy

func _check_employee_auto_quit() -> void:
	"""Check if any employees should auto-quit due to low morale"""
	var employees_to_fire: Array = []

	for employee_id in hired_staff.keys():
		var employee_data: Dictionary = hired_staff[employee_id]

		# Check for miserable morale (< 20 for 3+ days)
		if employee_data["morale"] < BalanceConfig.STAFF.morale_thresholds.miserable:
			# Track consecutive miserable days
			if not employee_data.has("miserable_days"):
				employee_data["miserable_days"] = 0

			employee_data["miserable_days"] += 1

			# Auto-quit after 3 days of misery
			if employee_data["miserable_days"] >= 3:
				print("[StaffManager] ", employee_data["employee_name"], " quit due to low morale (", employee_data["morale"], ")")
				employees_to_fire.append(employee_id)
		else:
			# Reset counter if morale improves
			employee_data["miserable_days"] = 0

	# Fire employees who quit
	for employee_id in employees_to_fire:
		fire_staff(employee_id)

# ============================================================================
# UPGRADES
# ============================================================================

func increase_staff_capacity(additional_slots: int) -> void:
	"""Increase maximum staff slots (from upgrades)"""
	max_staff_slots += additional_slots
	print("Staff capacity increased to ", max_staff_slots)

# ============================================================================
# AI AUTOMATION
# ============================================================================

func _on_shop_state_changed(is_open: bool) -> void:
	"""Handle shop opening/closing to activate/deactivate staff AI"""
	print("[StaffManager] Shop state changed - Open: ", is_open)
	print("[StaffManager] Currently hired staff: ", hired_staff.size())

	# Deactivate all current AI
	_deactivate_all_ai()

	# Activate ALL assigned staff when shop opens
	if is_open:
		print("[StaffManager] Shop opened - activating all staff...")
		_activate_all_staff()
	else:
		print("[StaffManager] Shop closed - staff inactive")

	print("[StaffManager] Active AI workers: ", active_ai_workers.size())

func _activate_all_staff() -> void:
	"""Activate ALL hired staff when shop opens"""
	print("[StaffManager] Activating all ", hired_staff.size(), " employees...")

	for employee_id in hired_staff.keys():
		var employee_data: Dictionary = hired_staff[employee_id]
		var assigned_phase: String = employee_data.get("assigned_phase", "none")

		# Only activate employees with assigned phases (not "none")
		if assigned_phase != "none":
			_create_and_activate_ai(employee_data, assigned_phase)
		else:
			print("[StaffManager] ", employee_data["employee_name"], " is off duty (no phase assigned)")

func _create_and_activate_ai(employee_data: Dictionary, phase: String) -> void:
	"""Create and activate an AI worker instance - spawns at entrance and walks to station"""
	var employee_id: String = employee_data["employee_id"]

	# Spawn visual character at entrance (will walk to station, then AI activates)
	_spawn_staff_character(employee_data, phase)

	# Note: AI activation happens in _activate_staff_ai() after character reaches station

func _deactivate_all_ai() -> void:
	"""Deactivate and cleanup all AI workers"""
	for staff_id in active_ai_workers.keys():
		var ai_worker = active_ai_workers[staff_id]
		if ai_worker:
			if ai_worker.has_method("deactivate"):
				ai_worker.deactivate()
			# Remove from scene tree and free
			if ai_worker.get_parent():
				ai_worker.get_parent().remove_child(ai_worker)
			ai_worker.queue_free()

		# Remove visual character
		_remove_staff_character(staff_id)

	active_ai_workers.clear()

	# Clear any staff still walking to their stations
	staff_walking_to_station.clear()

# ============================================================================
# SAVE/LOAD
# ============================================================================

func get_save_data() -> Dictionary:
	"""Get data for saving"""
	return {
		"version": SAVE_VERSION,
		"hired_staff": hired_staff,
		"applicant_pool": applicant_pool,
		"max_staff_slots": max_staff_slots,
		"next_staff_id": next_staff_id
	}

func load_save_data(data: Dictionary) -> void:
	"""Load saved data with version checking"""
	var save_version: int = data.get("version", 1)

	if save_version < SAVE_VERSION:
		print("[StaffManager] WARNING: Loading old save format (v%d). Employee data will be reset." % save_version)
		# Invalidate old employee data - player must hire new staff
		hired_staff = {}
		applicant_pool = []
		max_staff_slots = data.get("max_staff_slots", 3)
		next_staff_id = data.get("next_staff_id", 1)
		# Generate fresh applicant pool
		refresh_applicants()
		print("[StaffManager] Old employee system data cleared. Fresh applicant pool generated.")
		return

	# Load current version data
	hired_staff = data["hired_staff"] if data.has("hired_staff") else {}
	applicant_pool = data["applicant_pool"] if data.has("applicant_pool") else []
	max_staff_slots = data.get("max_staff_slots", 3)
	next_staff_id = data.get("next_staff_id", 1)

	print("[StaffManager] Data loaded: ", hired_staff.size(), " employees hired")

# ============================================================================
# UTILITIES
# ============================================================================

func get_phase_display_name(phase: String) -> String:
	"""Get display name for phase"""
	match phase:
		"baking":
			return "Baking"
		"checkout":
			return "Checkout"
		"cleanup":
			return "Cleanup"
		"restocking":
			return "Restocking"
		"none":
			return "Off Duty"
		_:
			return "Unknown"

func get_phase_description(phase: String) -> String:
	"""Get description for phase"""
	match phase:
		"baking":
			return "Prepares baked goods during Baking Phase"
		"checkout":
			return "Handles customer transactions during Business Phase"
		"cleanup":
			return "Completes cleanup tasks during Cleanup Phase"
		"restocking":
			return "Manages inventory and restocking"
		"none":
			return "Not currently assigned to any phase"
		_:
			return ""

# ============================================================================
# VISUAL STAFF CHARACTERS
# ============================================================================

func _spawn_staff_character(employee_data: Dictionary, phase: String) -> void:
	"""Spawn a visual character for this employee at entrance, then walk to station"""
	var employee_id: String = employee_data["employee_id"]

	# Get the bakery scene
	var bakery = get_tree().current_scene
	if not bakery:
		print("[StaffManager] Cannot spawn character - no current scene")
		return

	# Instance the employee scene
	var character: Node3D = employee_scene.instantiate()
	character.name = "Employee_" + employee_data["employee_name"]
	bakery.add_child(character)

	# Spawn at entrance position (same as customers)
	character.global_position = entrance_position

	# Set employee properties
	character.employee_id = employee_id
	character.employee_name = employee_data["employee_name"]
	character.employee_role = phase  # Using role property to store phase for now

	# Add name label
	_add_staff_name_label(character, employee_data["employee_name"], phase)

	# Store reference
	staff_characters[employee_id] = character

	# Get target station position
	var target_position: Vector3 = _get_staff_target_position(phase, bakery)

	# Wait one frame for employee's _ready() to complete before playing animation
	await get_tree().process_frame

	# Start walking animation
	_play_character_animation(character, "walk")

	# Begin navigation to station
	staff_walking_to_station[employee_id] = {
		"character": character,
		"target_position": target_position,
		"phase": phase,
		"employee_data": employee_data
	}

	print("[StaffManager] Spawned ", employee_data["employee_name"], " at entrance ", entrance_position, " - walking to ", phase, " station at ", target_position)

func _get_staff_target_position(phase: String, bakery: Node) -> Vector3:
	"""Get the target position for an employee based on their assigned phase"""
	# Try to find StaffTarget markers (still using old target_type names for now - Phase 9 will update markers)
	var targets = _find_staff_targets(bakery, phase)

	match phase:
		"baking":
			# Target: storage
			for target in targets:
				var target_name = target.get("target_name")
				if target_name and ("storage" in str(target_name).to_lower() or "cabinet" in str(target_name).to_lower()):
					return target.global_position
			return Vector3(2, 0, -2)  # Fallback

		"checkout":
			# Target: register
			for target in targets:
				var target_name = target.get("target_name")
				if target_name and "register" in str(target_name).to_lower():
					return target.global_position
			return Vector3(7, 0, 3)  # Fallback

		"cleanup":
			# Target: sink
			for target in targets:
				var target_name = target.get("target_name")
				if target_name and "sink" in str(target_name).to_lower():
					return target.global_position
			return Vector3(-2, 0, 2)  # Fallback

		"restocking":
			# Target: storage (same as baking for now)
			for target in targets:
				var target_name = target.get("target_name")
				if target_name and ("storage" in str(target_name).to_lower() or "cabinet" in str(target_name).to_lower()):
					return target.global_position
			return Vector3(2, 0, -2)  # Fallback

	return Vector3.ZERO

func _process_staff_walking_to_station(delta: float) -> void:
	"""Process employees walking from entrance to their stations"""
	var arrived_employees: Array = []

	for employee_id in staff_walking_to_station.keys():
		var walk_data: Dictionary = staff_walking_to_station[employee_id]
		var character: Node3D = walk_data.character
		var target_position: Vector3 = walk_data.target_position

		if not is_instance_valid(character):
			arrived_employees.append(employee_id)
			continue

		# Calculate direction to target
		var direction: Vector3 = (target_position - character.global_position)
		var distance: float = direction.length()

		# Check if arrived (within 0.5 meters)
		if distance < 0.5:
			# Stop walking animation completely (not pause - stop!)
			var anim_player: AnimationPlayer = _find_animation_player(character)
			if anim_player:
				print("[StaffManager] Stopping animation for ", character.name, " - was playing: ", anim_player.is_playing())
				anim_player.stop()
				print("[StaffManager] After stop() - is playing: ", anim_player.is_playing())
			else:
				print("[StaffManager] WARNING: No AnimationPlayer found for ", character.name)

			# Rotate to face their workstation (180 degrees from entrance)
			character.rotation.y = PI

			# Mark as arrived
			arrived_employees.append(employee_id)
			print("[StaffManager] ", character.name, " arrived at station")
			continue

		# Move toward target
		direction = direction.normalized()
		var move_speed: float = 3.0  # Same speed as customers
		character.global_position += direction * move_speed * delta

		# Rotate to face movement direction
		if direction.length_squared() > 0.001:
			var target_rotation = atan2(direction.x, direction.z)
			character.rotation.y = lerp_angle(character.rotation.y, target_rotation, 10.0 * delta)

	# Activate AI for employees that arrived at their stations
	for employee_id in arrived_employees:
		var walk_data: Dictionary = staff_walking_to_station[employee_id]
		_activate_staff_ai(walk_data.employee_data, walk_data.phase, employee_id)
		staff_walking_to_station.erase(employee_id)

func _activate_staff_ai(employee_data: Dictionary, phase: String, employee_id: String) -> void:
	"""Activate AI for an employee who has reached their station"""
	# Get the character reference
	var character: Node3D = staff_characters.get(employee_id)

	# Load the unified EmployeeAI class
	var EmployeeAI = load("res://scripts/staff/employee_ai.gd")
	if not EmployeeAI:
		print("[StaffManager] ERROR: Could not load EmployeeAI class")
		return

	# Create AI instance
	var ai_instance = EmployeeAI.new(employee_id, employee_data)

	# Add AI to scene tree so it can access get_tree()
	add_child(ai_instance)
	active_ai_workers[employee_id] = ai_instance

	# Give AI control of the visual character
	if ai_instance.has_method("set_character") and character:
		ai_instance.set_character(character)

	# Activate with assigned phase
	if ai_instance.has_method("activate"):
		ai_instance.activate(phase)
		print("[StaffManager] Unified AI activated for ", employee_data["employee_name"], " (", phase, " phase)")

func _get_staff_spawn_position(ai_type: String, bakery: Node) -> Dictionary:
	"""Get the spawn position and rotation for a staff member based on their role"""
	# Try to find StaffTarget markers for initial spawn position
	var targets = _find_staff_targets(bakery, ai_type)

	match ai_type:
		"baker":
			# Spawn at storage target
			for target in targets:
				var target_name = target.get("target_name")
				if target_name and ("storage" in str(target_name).to_lower() or "cabinet" in str(target_name).to_lower()):
					return {"position": target.global_position, "rotation_y": 0}
			return {"position": Vector3(2, 0, -2), "rotation_y": PI}

		"cashier":
			# Spawn at register target
			for target in targets:
				var target_name = target.get("target_name")
				if target_name and "register" in str(target_name).to_lower():
					return {"position": target.global_position, "rotation_y": 0}
			return {"position": Vector3(7, 0, 3), "rotation_y": 0}

		"cleaner":
			# Spawn at sink target
			for target in targets:
				var target_name = target.get("target_name")
				if target_name and "sink" in str(target_name).to_lower():
					return {"position": target.global_position, "rotation_y": 0}
			return {"position": Vector3(-2, 0, 2), "rotation_y": PI / 2}

	return {"position": Vector3.ZERO, "rotation_y": 0}

func _find_staff_targets(bakery: Node, phase: String) -> Array:
	"""Find all StaffTarget nodes for a given phase (supports old role names for compatibility)"""
	var targets: Array = []

	# Map phases to old role names for backwards compatibility with existing markers
	var old_role_map: Dictionary = {
		"baking": "baker",
		"checkout": "cashier",
		"cleanup": "cleaner",
		"restocking": "any"  # Can use any type markers
	}

	var compatible_types: Array = [phase, "any"]
	if old_role_map.has(phase):
		compatible_types.append(old_role_map[phase])

	for child in _get_all_descendants(bakery):
		if child.get_script():
			var target_type_prop = child.get("target_type")
			if target_type_prop and target_type_prop in compatible_types:
				targets.append(child)
	return targets

func _get_all_descendants(node: Node) -> Array:
	"""Recursively get all descendants of a node"""
	var result: Array = []
	for child in node.get_children():
		result.append(child)
		result.append_array(_get_all_descendants(child))
	return result

func _find_node_by_name(root: Node, search_name: String) -> Node:
	"""Recursively find a node by name (case-insensitive partial match)"""
	for child in root.get_children():
		if search_name.to_lower() in child.name.to_lower():
			return child
		var found = _find_node_by_name(child, search_name)
		if found:
			return found
	return null

func _play_character_animation(character: Node3D, anim_name: String) -> void:
	"""Play an animation on the staff character"""
	print("[StaffManager] Looking for AnimationPlayer in ", character.name)

	# Find the AnimationPlayer node (it's in the CustomerModel child)
	var anim_player: AnimationPlayer = _find_animation_player(character)

	print("[StaffManager] Found AnimationPlayer: ", anim_player != null)

	if anim_player and anim_player is AnimationPlayer:
		# Make sure AnimationPlayer is active
		anim_player.active = true
		anim_player.process_mode = Node.PROCESS_MODE_INHERIT

		# Get the first animation (same approach as customers)
		var anims = anim_player.get_animation_list()
		print("[StaffManager] Available animations: ", anims)

		if anims.size() > 0:
			var anim = anims[0]

			# Get the animation library and set loop mode
			var anim_lib = anim_player.get_animation_library("")
			if anim_lib and anim_lib.has_animation(anim):
				var animation = anim_lib.get_animation(anim)
				if animation:
					animation.loop_mode = Animation.LOOP_LINEAR

			# Play the animation immediately
			anim_player.play(anim)

			# Force update to ensure animation starts
			anim_player.advance(0.0)

			print("[StaffManager] Playing animation: ", anim)
		else:
			print("[StaffManager] No animations found!")
	else:
		print("[StaffManager] No AnimationPlayer found!")

func _find_animation_player(character: Node3D) -> AnimationPlayer:
	"""Recursively find AnimationPlayer in character"""
	print("[StaffManager] Searching in character with ", character.get_child_count(), " children")
	for child in character.get_children():
		print("[StaffManager]   Child: ", child.name, " (", child.get_class(), ")")
		if child is AnimationPlayer:
			return child
		# Check child's children (customer models are nested)
		var found = _find_animation_player(child)
		if found:
			return found
	return null

func _stop_character_animation(character: Node3D) -> void:
	"""Stop walking animation and set to idle pose"""
	_play_character_animation(character, "idle")

func _add_staff_name_label(character: Node3D, employee_name: String, phase: String) -> void:
	"""Add a name label above the employee character"""
	# Create a Label3D node
	var label = Label3D.new()
	label.name = "NameLabel"
	var phase_display: String = get_phase_display_name(phase)
	label.text = employee_name + " (" + phase_display + ")"
	label.position = Vector3(0, 2.2, 0)  # Above character's head
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 24
	label.outline_size = 4
	label.modulate = Color(0.3, 0.8, 1.0)  # Light blue color for staff

	character.add_child(label)

func _remove_staff_character(staff_id: String) -> void:
	"""Remove visual character for a staff member"""
	if staff_characters.has(staff_id):
		var character = staff_characters[staff_id]
		if character and is_instance_valid(character):
			character.queue_free()
		staff_characters.erase(staff_id)
		print("[StaffManager] Removed visual character for staff ", staff_id)

# ============================================================================
# NEW METHODS FOR SHOP OPEN/CLOSED SYSTEM
# ============================================================================

func regenerate_all_employee_energy() -> void:
	"""Fully regenerate energy for all employees (called when shop closes)"""
	for employee_id in hired_staff.keys():
		var employee_data: Dictionary = hired_staff[employee_id]
		employee_data["energy"] = BalanceConfig.STAFF.max_energy
	print("[StaffManager] Regenerated energy for all employees")

func apply_sleep_energy_bonus(bonus_percentage: float) -> void:
	"""Apply sleep quality energy bonus to all employees"""
	var bonus_amount = BalanceConfig.STAFF.max_energy * bonus_percentage
	for employee_id in hired_staff.keys():
		var employee_data: Dictionary = hired_staff[employee_id]
		employee_data["energy"] = min(employee_data["energy"] + bonus_amount, BalanceConfig.STAFF.max_energy)
	print("[StaffManager] Applied sleep energy bonus: +%.1f%% to all employees" % (bonus_percentage * 100))

func process_daily_updates() -> void:
	"""Process daily updates - called by GameManager at end of day"""
	pay_daily_wages()
	_process_daily_morale_and_energy()
	_check_employee_auto_quit()
	
	# Refresh applicants weekly
	if GameManager.current_day % BalanceConfig.STAFF.get("applicant_refresh_days", 7) == 0:
		refresh_applicants()
