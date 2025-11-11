extends Node

# CashierAI - Automates customer checkout during Business Phase
# Cashiers automatically ring up customers waiting at the register

class_name CashierAI

# Reference to the staff data
var staff_data: Dictionary
var staff_id: String

# State
var is_active: bool = false
var current_customer: Node3D = null
var checkout_timer: float = 0.0
var customers_served: int = 0

# AI behavior settings (loaded from BalanceConfig)
var base_checkout_time: float = 0.0  # Base time to process a customer
var check_interval: float = 0.0      # Check for customers every second
var next_check_time: float = 0.0

# Equipment references
var register: Node3D = null

func _init(p_staff_id: String, p_staff_data: Dictionary) -> void:
	staff_id = p_staff_id
	staff_data = p_staff_data

func activate() -> void:
	"""Activate the cashier AI for this phase"""
	is_active = true
	customers_served = 0
	next_check_time = 0.0
	check_interval = BalanceConfig.STAFF.cashier_check_interval
	base_checkout_time = BalanceConfig.STAFF.cashier_base_checkout_time
	print("[CashierAI] ", staff_data.name, " is now working at register!")
	_find_register()

func deactivate() -> void:
	"""Deactivate the cashier AI"""
	is_active = false
	current_customer = null
	print("[CashierAI] ", staff_data.name, " finished work. Customers served: ", customers_served)

func process(delta: float) -> void:
	"""Process AI logic each frame during Business Phase"""
	if not is_active:
		return

	# If currently serving a customer
	if current_customer:
		_process_checkout(delta)
		return

	# Check for waiting customers periodically
	if Time.get_ticks_msec() / 1000.0 >= next_check_time:
		_check_for_customers()
		next_check_time = Time.get_ticks_msec() / 1000.0 + check_interval

func _find_register() -> void:
	"""Find the register in the bakery"""
	var bakery = get_tree().current_scene
	if not bakery:
		return

	# Find register
	for child in _get_all_children(bakery):
		if "register" in child.name.to_lower():
			register = child
			print("[CashierAI] Found register: ", register.name)
			return

func _get_all_children(node: Node) -> Array:
	"""Recursively get all children of a node"""
	var result: Array = []
	for child in node.get_children():
		result.append(child)
		result.append_array(_get_all_children(child))
	return result

func _check_for_customers() -> void:
	"""Check if there are customers waiting at the register"""
	if not register or not register.has_method("get_waiting_customer"):
		return

	var waiting_customer = register.get_waiting_customer()
	if waiting_customer:
		_start_checkout(waiting_customer)

func _start_checkout(customer: Node3D) -> void:
	"""Start checking out a customer"""
	current_customer = customer
	checkout_timer = 0.0
	print("[CashierAI] ", staff_data.name, " serving customer...")

func _process_checkout(delta: float) -> void:
	"""Process the current checkout"""
	if not current_customer or not GameManager:
		current_customer = null
		return

	# Apply time scale and staff speed multiplier
	var time_mult: float = GameManager.get_time_scale()
	var speed_mult: float = StaffManager.get_staff_speed_multiplier(staff_id)
	checkout_timer += delta * time_mult * speed_mult

	# Calculate actual checkout time (faster staff = faster checkout)
	var actual_checkout_time: float = base_checkout_time / speed_mult

	if checkout_timer >= actual_checkout_time:
		_complete_checkout()

func _complete_checkout() -> void:
	"""Complete the current checkout"""
	if not current_customer:
		return

	# Process the sale through the register
	if register and register.has_method("auto_process_customer"):
		register.auto_process_customer(current_customer)
		customers_served += 1
		print("[CashierAI] ", staff_data.name, " completed checkout")

	current_customer = null
	checkout_timer = 0.0
