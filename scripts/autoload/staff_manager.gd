extends Node

# StaffManager - Singleton for managing hired staff and automation
# Handles hiring, firing, wages, skill progression, and AI task automation

# Signals
signal staff_hired(staff_data: Dictionary)
signal staff_fired(staff_id: String)
signal staff_skill_improved(staff_id: String, new_skill: int)
signal applicants_refreshed(applicants: Array)
signal wages_paid(total_amount: float)

# Staff roles
enum StaffRole {
	BAKER,      # Automates baking during Baking Phase
	CASHIER,    # Automates checkout during Business Phase
	CLEANER     # Automates cleanup during Cleanup Phase
}

# Staff state
var hired_staff: Dictionary = {}  # staff_id -> staff_data
var applicant_pool: Array = []    # Available applicants (refreshes weekly)
var max_staff_slots: int = 3      # Upgradeable
var next_staff_id: int = 1

# AI instances (created when staff activated)
var active_ai_workers: Dictionary = {}  # staff_id -> AI instance

# Staff generation settings
var staff_names: Array = [
	"Alice", "Bob", "Carlos", "Diana", "Emma", "Frank", "Grace", "Henry",
	"Iris", "Jack", "Kelly", "Leo", "Maria", "Noah", "Olivia", "Peter",
	"Quinn", "Rachel", "Sam", "Taylor", "Uma", "Victor", "Wendy", "Xavier"
]

# Wage rates per skill level (daily)
var wage_rates: Dictionary = {
	1: 20.0,   # 1-star: $20/day
	2: 35.0,   # 2-star: $35/day
	3: 55.0,   # 3-star: $55/day
	4: 80.0,   # 4-star: $80/day
	5: 120.0   # 5-star: $120/day
}

# Skill modifiers (affects speed and quality)
var skill_speed_multipliers: Dictionary = {
	1: 0.6,   # 1-star: 60% speed
	2: 0.8,   # 2-star: 80% speed
	3: 1.0,   # 3-star: 100% speed
	4: 1.3,   # 4-star: 130% speed
	5: 1.6    # 5-star: 160% speed
}

var skill_quality_multipliers: Dictionary = {
	1: 0.8,   # 1-star: 80% quality
	2: 0.9,   # 2-star: 90% quality
	3: 1.0,   # 3-star: 100% quality
	4: 1.1,   # 4-star: 110% quality
	5: 1.2    # 5-star: 120% quality
}

func _ready() -> void:
	print("StaffManager initialized")
	# Connect to day change and phase change signals
	if GameManager:
		GameManager.day_changed.connect(_on_day_changed)
		GameManager.phase_changed.connect(_on_phase_changed)

	# Generate initial applicant pool
	refresh_applicants()

func _process(delta: float) -> void:
	"""Process all active AI workers"""
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
	var daily_wage: float = wage_rates[applicant_data.skill]
	if EconomyManager.get_current_cash() < daily_wage:
		print("Cannot hire - insufficient funds for wage")
		return false

	# Create staff record
	var staff_id: String = "staff_%d" % next_staff_id
	next_staff_id += 1

	var staff_data: Dictionary = {
		"id": staff_id,
		"name": applicant_data.name,
		"role": applicant_data.role,
		"skill": applicant_data.skill,
		"days_worked": 0,
		"experience": 0,
		"hire_date": GameManager.current_day if GameManager else 1
	}

	hired_staff[staff_id] = staff_data

	# Remove from applicant pool
	applicant_pool.erase(applicant_data)

	print("Hired ", staff_data.name, " as ", _get_role_name(staff_data.role), " (", staff_data.skill, " stars)")
	staff_hired.emit(staff_data)
	return true

func fire_staff(staff_id: String) -> void:
	"""Fire a staff member"""
	if not hired_staff.has(staff_id):
		print("Cannot fire - staff not found: ", staff_id)
		return

	var staff_data: Dictionary = hired_staff[staff_id]
	print("Fired ", staff_data.name)

	hired_staff.erase(staff_id)
	staff_fired.emit(staff_id)

# ============================================================================
# APPLICANT POOL
# ============================================================================

func refresh_applicants() -> void:
	"""Generate new applicant pool (called weekly)"""
	applicant_pool.clear()

	# Generate 5-8 random applicants
	var num_applicants: int = randi_range(5, 8)

	for i in range(num_applicants):
		var applicant: Dictionary = _generate_random_applicant()
		applicant_pool.append(applicant)

	print("Applicant pool refreshed: ", num_applicants, " applicants")
	applicants_refreshed.emit(applicant_pool)

func _generate_random_applicant() -> Dictionary:
	"""Generate a random staff applicant"""
	var name: String = staff_names[randi() % staff_names.size()]
	var role: StaffRole = randi() % 3  # Random role
	var skill: int = _weighted_random_skill()

	return {
		"name": name,
		"role": role,
		"skill": skill
	}

func _weighted_random_skill() -> int:
	"""Generate skill level with weighted randomness (lower skills more common)"""
	var roll: float = randf()

	if roll < 0.40:   # 40% chance
		return 1
	elif roll < 0.70: # 30% chance
		return 2
	elif roll < 0.88: # 18% chance
		return 3
	elif roll < 0.97: # 9% chance
		return 4
	else:             # 3% chance
		return 5

# ============================================================================
# WAGES & PROGRESSION
# ============================================================================

func pay_daily_wages() -> float:
	"""Pay all staff their daily wages (called at end of day)"""
	var total_wages: float = 0.0

	for staff_id in hired_staff.keys():
		var staff_data: Dictionary = hired_staff[staff_id]
		var daily_wage: float = wage_rates[staff_data.skill]

		total_wages += daily_wage
		staff_data.days_worked += 1

		# Gain experience
		staff_data.experience += 1
		_check_skill_improvement(staff_id)

	if total_wages > 0:
		EconomyManager.remove_cash(total_wages, "Staff wages")
		print("Paid $", total_wages, " in staff wages")
		wages_paid.emit(total_wages)

	return total_wages

func _check_skill_improvement(staff_id: String) -> void:
	"""Check if staff member's skill should improve with experience"""
	var staff_data: Dictionary = hired_staff[staff_id]
	var current_skill: int = staff_data.skill

	if current_skill >= 5:
		return  # Already max skill

	# Experience thresholds for skill improvement
	var experience_needed: int = current_skill * 30  # 30, 60, 90, 120 days

	if staff_data.experience >= experience_needed:
		staff_data.skill += 1
		staff_data.experience = 0  # Reset experience for next level

		print(staff_data.name, " improved to ", staff_data.skill, " stars!")
		staff_skill_improved.emit(staff_id, staff_data.skill)

func _on_day_changed(new_day: int) -> void:
	"""Called when day changes - pay wages and handle weekly events"""
	pay_daily_wages()

	# Refresh applicants weekly (every 7 days)
	if new_day % 7 == 0:
		refresh_applicants()

# ============================================================================
# GETTERS
# ============================================================================

func get_hired_staff_count() -> int:
	"""Get number of currently hired staff"""
	return hired_staff.size()

func get_staff_by_role(role: StaffRole) -> Array:
	"""Get all hired staff with specific role"""
	var result: Array = []
	for staff_data in hired_staff.values():
		if staff_data.role == role:
			result.append(staff_data)
	return result

func has_staff_role(role: StaffRole) -> bool:
	"""Check if any staff member has this role"""
	return get_staff_by_role(role).size() > 0

func get_staff_speed_multiplier(staff_id: String) -> float:
	"""Get speed multiplier for staff member"""
	if not hired_staff.has(staff_id):
		return 1.0
	return skill_speed_multipliers[hired_staff[staff_id].skill]

func get_staff_quality_multiplier(staff_id: String) -> float:
	"""Get quality multiplier for staff member"""
	if not hired_staff.has(staff_id):
		return 1.0
	return skill_quality_multipliers[hired_staff[staff_id].skill]

func get_total_daily_wages() -> float:
	"""Calculate total daily wages for all hired staff"""
	var total: float = 0.0
	for staff_data in hired_staff.values():
		total += wage_rates[staff_data.skill]
	return total

func get_applicant_pool() -> Array:
	"""Get current applicant pool"""
	return applicant_pool

func can_afford_staff(applicant_data: Dictionary) -> bool:
	"""Check if player can afford to hire this applicant"""
	var daily_wage: float = wage_rates[applicant_data.skill]
	return EconomyManager.get_current_cash() >= daily_wage

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

func _on_phase_changed(new_phase: int) -> void:
	"""Handle phase changes to activate/deactivate staff AI"""
	# Deactivate all current AI
	_deactivate_all_ai()

	# Activate AI for the appropriate phase
	match new_phase:
		0:  # BAKING phase
			_activate_bakers()
		1:  # BUSINESS phase
			_activate_cashiers()
		2:  # CLEANUP phase
			_activate_cleaners()
		3:  # PLANNING phase
			pass  # No automation during planning

func _activate_bakers() -> void:
	"""Activate all hired bakers"""
	var bakers: Array = get_staff_by_role(StaffRole.BAKER)
	for baker_data in bakers:
		_create_and_activate_ai(baker_data, "baker")

func _activate_cashiers() -> void:
	"""Activate all hired cashiers"""
	var cashiers: Array = get_staff_by_role(StaffRole.CASHIER)
	for cashier_data in cashiers:
		_create_and_activate_ai(cashier_data, "cashier")

func _activate_cleaners() -> void:
	"""Activate all hired cleaners"""
	var cleaners: Array = get_staff_by_role(StaffRole.CLEANER)
	for cleaner_data in cleaners:
		_create_and_activate_ai(cleaner_data, "cleaner")

func _create_and_activate_ai(staff_data: Dictionary, ai_type: String) -> void:
	"""Create and activate an AI worker instance"""
	var staff_id: String = staff_data.id

	# Load the appropriate AI class
	var ai_instance = null
	match ai_type:
		"baker":
			var BakerAI = load("res://scripts/staff/baker_ai.gd")
			ai_instance = BakerAI.new(staff_id, staff_data)
		"cashier":
			var CashierAI = load("res://scripts/staff/cashier_ai.gd")
			ai_instance = CashierAI.new(staff_id, staff_data)
		"cleaner":
			var CleanerAI = load("res://scripts/staff/cleaner_ai.gd")
			ai_instance = CleanerAI.new(staff_id, staff_data)

	if ai_instance:
		active_ai_workers[staff_id] = ai_instance
		ai_instance.activate()

func _deactivate_all_ai() -> void:
	"""Deactivate and cleanup all AI workers"""
	for staff_id in active_ai_workers.keys():
		var ai_worker = active_ai_workers[staff_id]
		if ai_worker and ai_worker.has_method("deactivate"):
			ai_worker.deactivate()

	active_ai_workers.clear()

# ============================================================================
# SAVE/LOAD
# ============================================================================

func get_save_data() -> Dictionary:
	"""Get data for saving"""
	return {
		"hired_staff": hired_staff,
		"applicant_pool": applicant_pool,
		"max_staff_slots": max_staff_slots,
		"next_staff_id": next_staff_id
	}

func load_save_data(data: Dictionary) -> void:
	"""Load saved data"""
	hired_staff = data.get("hired_staff", {})
	applicant_pool = data.get("applicant_pool", [])
	max_staff_slots = data.get("max_staff_slots", 3)
	next_staff_id = data.get("next_staff_id", 1)

	print("StaffManager data loaded: ", hired_staff.size(), " staff hired")

# ============================================================================
# UTILITIES
# ============================================================================

func _get_role_name(role: StaffRole) -> String:
	"""Get display name for role"""
	match role:
		StaffRole.BAKER:
			return "Baker"
		StaffRole.CASHIER:
			return "Cashier"
		StaffRole.CLEANER:
			return "Cleaner"
		_:
			return "Unknown"

func get_role_description(role: StaffRole) -> String:
	"""Get description for role"""
	match role:
		StaffRole.BAKER:
			return "Automatically bakes recipes during Baking Phase"
		StaffRole.CASHIER:
			return "Handles customer checkout during Business Phase"
		StaffRole.CLEANER:
			return "Completes cleanup tasks during Cleanup Phase"
		_:
			return ""
