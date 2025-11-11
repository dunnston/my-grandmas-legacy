extends Node

# CashierAI - Automates customer checkout during Business Phase
# Cashiers automatically ring up customers waiting at the register

class_name CashierAI

# Reference to the staff data
var staff_data: Dictionary
var staff_id: String

# State
enum CashierState {
	IDLE,           # Standing at register waiting
	WALKING_TO_DISPLAY,  # Walking to get items
	GATHERING_ITEMS,     # Standing at display case getting items
	WALKING_TO_REGISTER, # Walking back to register
	CHECKING_OUT         # Processing payment at register
}

var is_active: bool = false
var current_state: CashierState = CashierState.IDLE
var current_customer: Node3D = null
var checkout_timer: float = 0.0
var customers_served: int = 0

# AI behavior settings (loaded from BalanceConfig)
var base_checkout_time: float = 0.0  # Base time to process a customer
var check_interval: float = 0.0      # Check for customers every second
var next_check_time: float = 0.0
var gather_time: float = 2.0  # Time to gather items from display

# Equipment references
var register: Node = null  # Can be any Node type
var display_case: Node = null  # Can be any Node type

# Visual character reference
var character: Node3D = null
var nav_agent: NavigationAgent3D = null

func _init(p_staff_id: String, p_staff_data: Dictionary) -> void:
	staff_id = p_staff_id
	staff_data = p_staff_data

func set_character(p_character: Node3D) -> void:
	"""Set the visual character this AI controls"""
	character = p_character
	# Get navigation agent from character
	if character:
		for child in character.get_children():
			if child is NavigationAgent3D:
				nav_agent = child
				nav_agent.path_desired_distance = 0.5
				nav_agent.target_desired_distance = 0.5
				nav_agent.avoidance_enabled = true
				break

func activate() -> void:
	"""Activate the cashier AI for this phase"""
	is_active = true
	customers_served = 0
	next_check_time = 0.0
	current_state = CashierState.IDLE
	check_interval = BalanceConfig.STAFF.cashier_check_interval
	base_checkout_time = BalanceConfig.STAFF.cashier_base_checkout_time
	print("[CashierAI] ", staff_data.name, " is now working at register!")
	_find_equipment()

func deactivate() -> void:
	"""Deactivate the cashier AI"""
	is_active = false
	current_customer = null
	current_state = CashierState.IDLE
	print("[CashierAI] ", staff_data.name, " finished work. Customers served: ", customers_served)

func process(delta: float) -> void:
	"""Process AI logic each frame during Business Phase"""
	if not is_active or not character:
		return

	# State machine
	match current_state:
		CashierState.IDLE:
			_state_idle()
		CashierState.WALKING_TO_DISPLAY:
			_state_walking_to_display(delta)
		CashierState.GATHERING_ITEMS:
			_state_gathering_items(delta)
		CashierState.WALKING_TO_REGISTER:
			_state_walking_to_register(delta)
		CashierState.CHECKING_OUT:
			_state_checking_out(delta)

func _find_equipment() -> void:
	"""Find the register and display case in the bakery"""
	var bakery = get_tree().current_scene
	if not bakery:
		return

	# Find equipment
	for child in _get_all_children(bakery):
		var child_name = child.name.to_lower()
		if "register" in child_name:
			register = child
			print("[CashierAI] Found register: ", register.name)
		elif "display" in child_name:
			display_case = child
			print("[CashierAI] Found display case: ", display_case.name)

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
	"""Idle at register, checking for customers"""
	# Stop movement and animation when idle
	_set_animation("idle", false)

	# Make sure navigation is stopped
	if nav_agent:
		nav_agent.target_position = character.global_position if character else Vector3.ZERO

	# Check periodically for customers
	if Time.get_ticks_msec() / 1000.0 >= next_check_time:
		_check_for_customers()
		next_check_time = Time.get_ticks_msec() / 1000.0 + check_interval

func _state_walking_to_display(delta: float) -> void:
	"""Walking to display case to get items"""
	if not display_case:
		# Skip to gathering if no display case found
		current_state = CashierState.GATHERING_ITEMS
		return

	var target_pos = _get_node_position(display_case)
	_navigate_towards(target_pos, delta)
	_set_animation("walk", true)

	# Check if reached display
	if _is_at_position(target_pos):
		print("[CashierAI] ", staff_data.name, " reached display case")
		current_state = CashierState.GATHERING_ITEMS
		checkout_timer = 0.0

func _state_gathering_items(delta: float) -> void:
	"""Standing at display case gathering items"""
	_set_animation("idle", false)

	var time_mult: float = GameManager.get_time_scale() if GameManager else 1.0
	var speed_mult: float = StaffManager.get_staff_speed_multiplier(staff_id)
	checkout_timer += delta * time_mult * speed_mult

	if checkout_timer >= gather_time / speed_mult:
		print("[CashierAI] ", staff_data.name, " got items, returning to register")
		current_state = CashierState.WALKING_TO_REGISTER

func _state_walking_to_register(delta: float) -> void:
	"""Walking back to register with items"""
	if not register:
		current_state = CashierState.CHECKING_OUT
		return

	var target_pos = _get_node_position(register)
	_navigate_towards(target_pos, delta)
	_set_animation("walk", true)

	# Check if reached register
	if _is_at_position(target_pos):
		print("[CashierAI] ", staff_data.name, " returned to register")
		current_state = CashierState.CHECKING_OUT
		checkout_timer = 0.0

func _state_checking_out(delta: float) -> void:
	"""Processing payment at register"""
	_set_animation("idle", false)

	if not current_customer or not GameManager:
		_complete_checkout()
		return

	var time_mult: float = GameManager.get_time_scale()
	var speed_mult: float = StaffManager.get_staff_speed_multiplier(staff_id)
	checkout_timer += delta * time_mult * speed_mult

	var actual_checkout_time: float = base_checkout_time / speed_mult

	if checkout_timer >= actual_checkout_time:
		_complete_checkout()

# ============================================================================
# HELPERS
# ============================================================================

func _check_for_customers() -> void:
	"""Check if there are customers waiting at the register"""
	if current_customer:
		return  # Already serving someone

	if not register or not register.has_method("get_waiting_customer"):
		return

	var waiting_customer = register.get_waiting_customer()
	if waiting_customer:
		print("[CashierAI] ", staff_data.name, " starting checkout for customer")
		current_customer = waiting_customer
		current_state = CashierState.WALKING_TO_DISPLAY

func _complete_checkout() -> void:
	"""Complete the current checkout"""
	if not current_customer:
		current_state = CashierState.IDLE
		return

	# Process the sale through the register
	if register and register.has_method("auto_process_customer"):
		register.auto_process_customer(current_customer)
		customers_served += 1
		print("[CashierAI] ", staff_data.name, " completed checkout")

	current_customer = null
	checkout_timer = 0.0
	current_state = CashierState.IDLE

func _get_node_position(node: Node) -> Vector3:
	"""Safely get position from any node type"""
	if node is Node3D:
		return node.global_position
	elif node is Control:
		return Vector3.ZERO
	else:
		return Vector3.ZERO

func _navigate_towards(target_pos: Vector3, delta: float) -> void:
	"""Navigate character towards target position"""
	if not character or not nav_agent:
		return

	nav_agent.target_position = target_pos

	if nav_agent.is_navigation_finished():
		return

	var next_position = nav_agent.get_next_path_position()
	var direction = (next_position - character.global_position).normalized()

	# Move character
	var speed_mult: float = StaffManager.get_staff_speed_multiplier(staff_id)
	var move_speed: float = 3.0 * speed_mult
	character.global_position += direction * move_speed * delta

	# Rotate to face movement direction
	if direction.length() > 0.01:
		var target_rotation = atan2(direction.x, direction.z)
		character.rotation.y = lerp_angle(character.rotation.y, target_rotation, delta * 10.0)

func _is_at_position(target_pos: Vector3) -> bool:
	"""Check if character is at target position"""
	if not character:
		return true
	return character.global_position.distance_to(target_pos) < 1.0

func _set_animation(anim_name: String, playing: bool) -> void:
	"""Set character animation"""
	if not character:
		return

	var anim_player: AnimationPlayer = null
	for child in character.get_children():
		if child is AnimationPlayer:
			anim_player = child
			break

	if not anim_player:
		return

	if playing and anim_player.has_animation(anim_name):
		if anim_player.current_animation != anim_name:
			anim_player.play(anim_name)
	elif not playing:
		if anim_player.is_playing():
			anim_player.stop()
