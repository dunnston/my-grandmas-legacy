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
var max_staff_slots: int = 3      # Upgradeable (loaded from BalanceConfig)
var next_staff_id: int = 1

# AI instances (created when staff activated)
var active_ai_workers: Dictionary = {}  # staff_id -> AI instance

# Visual character instances
var staff_characters: Dictionary = {}  # staff_id -> Node3D character

# Staff spawning and navigation
var entrance_position: Vector3 = Vector3(-8, 0, -4)  # Default entrance (same as customers)
var staff_walking_to_station: Dictionary = {}  # staff_id -> { character, target_pos, ai_type, staff_data }

# Customer scene for visual representation (reusing customer models)
var customer_scene: PackedScene = preload("res://scenes/customer/customer.tscn")

# Staff generation settings
var staff_names: Array = [
	"Alice", "Bob", "Carlos", "Diana", "Emma", "Frank", "Grace", "Henry",
	"Iris", "Jack", "Kelly", "Leo", "Maria", "Noah", "Olivia", "Peter",
	"Quinn", "Rachel", "Sam", "Taylor", "Uma", "Victor", "Wendy", "Xavier"
]

# Balance values (loaded from BalanceConfig on ready)
var wage_rates: Dictionary = {}
var skill_speed_multipliers: Dictionary = {}
var skill_quality_multipliers: Dictionary = {}

func _ready() -> void:
	# Load balance values from BalanceConfig
	_load_balance_config()

	print("StaffManager initialized")
	# Connect to day change and phase change signals
	if GameManager:
		GameManager.day_changed.connect(_on_day_changed)
		GameManager.phase_changed.connect(_on_phase_changed)

	# Generate initial applicant pool
	refresh_applicants()

func _load_balance_config() -> void:
	"""Load all staff balance parameters from BalanceConfig"""
	max_staff_slots = BalanceConfig.STAFF.max_staff_slots
	wage_rates = BalanceConfig.STAFF.wage_rates.duplicate()
	skill_speed_multipliers = BalanceConfig.STAFF.skill_speed_multipliers.duplicate()
	skill_quality_multipliers = BalanceConfig.STAFF.skill_quality_multipliers.duplicate()

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

	print("[StaffManager] Hired ", staff_data.name, " as ", _get_role_name(staff_data.role), " (", staff_data.skill, " stars)")
	print("[StaffManager] Total staff now: ", hired_staff.size(), "/", max_staff_slots)
	print("[StaffManager] Staff data: ", staff_data)
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
	"""Generate skill level with weighted randomness (using BalanceConfig distribution)"""
	var roll: float = randf()
	var cumulative: float = 0.0

	# Use BalanceConfig skill distribution
	var distribution: Dictionary = BalanceConfig.STAFF.skill_distribution

	for skill_level in [1, 2, 3, 4, 5]:
		cumulative += distribution[skill_level]
		if roll < cumulative:
			return skill_level

	return 5  # Fallback (should never reach here if distribution sums to 1.0)

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

	# Experience thresholds for skill improvement (using BalanceConfig)
	var experience_needed: int = current_skill * BalanceConfig.STAFF.experience_per_skill_level

	if staff_data.experience >= experience_needed:
		staff_data.skill += 1
		staff_data.experience = 0  # Reset experience for next level

		print(staff_data.name, " improved to ", staff_data.skill, " stars!")
		staff_skill_improved.emit(staff_id, staff_data.skill)

func _on_day_changed(new_day: int) -> void:
	"""Called when day changes - pay wages and handle weekly events"""
	pay_daily_wages()

	# Refresh applicants weekly (using BalanceConfig interval)
	if new_day % BalanceConfig.STAFF.applicant_refresh_days == 0:
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
	print("[StaffManager] Phase changed to: ", new_phase)
	print("[StaffManager] Currently hired staff: ", hired_staff.size())

	# Deactivate all current AI
	_deactivate_all_ai()

	# Activate ALL staff during BUSINESS phase (when shop is open)
	match new_phase:
		1:  # BUSINESS phase - Shop is open, all staff work
			print("[StaffManager] Shop opened - activating all staff...")
			_activate_all_staff()
		_:  # All other phases - no staff active
			print("[StaffManager] Shop closed - staff inactive")
			pass

	print("[StaffManager] Active AI workers: ", active_ai_workers.size())

func _activate_all_staff() -> void:
	"""Activate ALL hired staff when shop opens"""
	print("[StaffManager] Activating all ", hired_staff.size(), " staff members...")

	for staff_id in hired_staff.keys():
		var staff_data: Dictionary = hired_staff[staff_id]
		var ai_type: String = ""

		# Determine AI type based on role
		match staff_data.role:
			StaffRole.BAKER:
				ai_type = "baker"
			StaffRole.CASHIER:
				ai_type = "cashier"
			StaffRole.CLEANER:
				ai_type = "cleaner"

		if ai_type != "":
			_create_and_activate_ai(staff_data, ai_type)

func _activate_bakers() -> void:
	"""Activate all hired bakers"""
	var bakers: Array = get_staff_by_role(StaffRole.BAKER)
	print("[StaffManager] Found ", bakers.size(), " bakers to activate")
	for baker_data in bakers:
		_create_and_activate_ai(baker_data, "baker")

func _activate_cashiers() -> void:
	"""Activate all hired cashiers"""
	var cashiers: Array = get_staff_by_role(StaffRole.CASHIER)
	print("[StaffManager] Found ", cashiers.size(), " cashiers to activate")
	for cashier_data in cashiers:
		_create_and_activate_ai(cashier_data, "cashier")

func _activate_cleaners() -> void:
	"""Activate all hired cleaners"""
	var cleaners: Array = get_staff_by_role(StaffRole.CLEANER)
	print("[StaffManager] Found ", cleaners.size(), " cleaners to activate")
	for cleaner_data in cleaners:
		_create_and_activate_ai(cleaner_data, "cleaner")

func _create_and_activate_ai(staff_data: Dictionary, ai_type: String) -> void:
	"""Create and activate an AI worker instance - spawns at entrance and walks to station"""
	var staff_id: String = staff_data.id

	# Spawn visual character at entrance (will walk to station, then AI activates)
	_spawn_staff_character(staff_data, ai_type)

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

# ============================================================================
# VISUAL STAFF CHARACTERS
# ============================================================================

func _spawn_staff_character(staff_data: Dictionary, ai_type: String) -> void:
	"""Spawn a visual character for this staff member at entrance, then walk to station"""
	var staff_id: String = staff_data.id

	# Get the bakery scene
	var bakery = get_tree().current_scene
	if not bakery:
		print("[StaffManager] Cannot spawn character - no current scene")
		return

	# Instance the customer scene (reusing for staff visuals)
	var character: Node3D = customer_scene.instantiate()
	character.name = "Staff_" + staff_data.name
	bakery.add_child(character)

	# Spawn at entrance position (same as customers)
	character.global_position = entrance_position

	# Disable customer AI behaviors (but keep NavigationAgent3D available)
	if character.has_method("set_customer_ai_enabled"):
		character.set_customer_ai_enabled(false)

	# Add name label
	_add_staff_name_label(character, staff_data.name, ai_type)

	# Store reference
	staff_characters[staff_id] = character

	# Get target station position
	var target_position: Vector3 = _get_staff_target_position(ai_type, bakery)

	# Start walking animation
	_play_character_animation(character, "walk")

	# Begin navigation to station
	staff_walking_to_station[staff_id] = {
		"character": character,
		"target_position": target_position,
		"ai_type": ai_type,
		"staff_data": staff_data
	}

	print("[StaffManager] Spawned ", staff_data.name, " at entrance ", entrance_position, " - walking to station at ", target_position)

func _get_staff_target_position(ai_type: String, bakery: Node) -> Vector3:
	"""Get the target position for a staff member based on their role"""
	# Try to find StaffTarget markers
	var targets = _find_staff_targets(bakery, ai_type)

	match ai_type:
		"baker":
			# Target: storage
			for target in targets:
				var target_name = target.get("target_name")
				if target_name and ("storage" in str(target_name).to_lower() or "cabinet" in str(target_name).to_lower()):
					return target.global_position
			return Vector3(2, 0, -2)  # Fallback

		"cashier":
			# Target: register
			for target in targets:
				var target_name = target.get("target_name")
				if target_name and "register" in str(target_name).to_lower():
					return target.global_position
			return Vector3(7, 0, 3)  # Fallback

		"cleaner":
			# Target: sink
			for target in targets:
				var target_name = target.get("target_name")
				if target_name and "sink" in str(target_name).to_lower():
					return target.global_position
			return Vector3(-2, 0, 2)  # Fallback

	return Vector3.ZERO

func _process_staff_walking_to_station(delta: float) -> void:
	"""Process staff members walking from entrance to their stations"""
	var arrived_staff: Array = []

	for staff_id in staff_walking_to_station.keys():
		var walk_data: Dictionary = staff_walking_to_station[staff_id]
		var character: Node3D = walk_data.character
		var target_position: Vector3 = walk_data.target_position

		if not is_instance_valid(character):
			arrived_staff.append(staff_id)
			continue

		# Calculate direction to target
		var direction: Vector3 = (target_position - character.global_position)
		var distance: float = direction.length()

		# Check if arrived (within 0.5 meters)
		if distance < 0.5:
			# Pause walking animation (freeze at current frame like customers do)
			var anim_player: AnimationPlayer = _find_animation_player(character)
			if anim_player and anim_player.is_playing():
				anim_player.pause()

			# Rotate to face forward (toward bakery interior)
			character.rotation.y = 0

			# Mark as arrived
			arrived_staff.append(staff_id)
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

	# Activate AI for staff that arrived at their stations
	for staff_id in arrived_staff:
		var walk_data: Dictionary = staff_walking_to_station[staff_id]
		_activate_staff_ai(walk_data.staff_data, walk_data.ai_type, staff_id)
		staff_walking_to_station.erase(staff_id)

func _activate_staff_ai(staff_data: Dictionary, ai_type: String, staff_id: String) -> void:
	"""Activate AI for a staff member who has reached their station"""
	# Get the character reference
	var character: Node3D = staff_characters.get(staff_id)

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
		# Add AI to scene tree so it can access get_tree()
		add_child(ai_instance)
		active_ai_workers[staff_id] = ai_instance

		# Give AI control of the visual character
		if ai_instance.has_method("set_character") and character:
			ai_instance.set_character(character)

		ai_instance.activate()
		print("[StaffManager] AI activated for ", staff_data.name, " at their station")

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

func _find_staff_targets(bakery: Node, staff_type: String) -> Array:
	"""Find all StaffTarget nodes for a given staff type"""
	var targets: Array = []
	for child in _get_all_descendants(bakery):
		if child.get_script():
			var target_type_prop = child.get("target_type")
			if target_type_prop and (target_type_prop == staff_type or target_type_prop == "any"):
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
	# Find the AnimationPlayer node (it's in the CustomerModel child)
	var anim_player: AnimationPlayer = _find_animation_player(character)

	if anim_player:
		if anim_player.has_animation(anim_name):
			if anim_player.current_animation != anim_name:
				anim_player.play(anim_name)
		else:
			print("[StaffManager] Animation '", anim_name, "' not found")

func _find_animation_player(character: Node3D) -> AnimationPlayer:
	"""Recursively find AnimationPlayer in character"""
	for child in character.get_children():
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

func _add_staff_name_label(character: Node3D, staff_name: String, ai_type: String) -> void:
	"""Add a name label above the staff character"""
	# Create a Label3D node
	var label = Label3D.new()
	label.name = "NameLabel"
	label.text = staff_name + " (" + ai_type.capitalize() + ")"
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
