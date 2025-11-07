extends CharacterBody3D

# Customer - AI-controlled customer that browses, purchases, and leaves
# Uses NavigationAgent3D for pathfinding

# Signals
signal reached_display_case()
signal reached_register()
signal purchase_complete(items: Array, total_spent: float)
signal left_bakery()

# Enums
enum State {
	ENTERING,
	BROWSING,
	WAITING_CHECKOUT,
	CHECKING_OUT,
	LEAVING,
	EXITED
}

enum Mood {
	HAPPY,
	NEUTRAL,
	UNHAPPY
}

# Node references
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D

# Customer properties
var customer_id: String = ""
var current_state: State = State.ENTERING
var current_mood: Mood = Mood.NEUTRAL

# Movement
var move_speed: float = 3.0
var rotation_speed: float = 10.0

# Shopping
var selected_items: Array[Dictionary] = []  # Items customer wants to buy
var patience: float = 100.0  # 0-100, affects mood
var patience_drain_rate: float = 5.0  # Per second when waiting
var browse_time: float = 0.0
var max_browse_time: float = 5.0  # Seconds to browse

# Target positions (set by CustomerManager)
var entrance_position: Vector3 = Vector3.ZERO
var display_position: Vector3 = Vector3.ZERO
var register_position: Vector3 = Vector3.ZERO
var exit_position: Vector3 = Vector3.ZERO

# Satisfaction factors
var satisfaction_score: float = 50.0  # 0-100

func _ready() -> void:
	customer_id = "customer_" + str(Time.get_ticks_msec())

	# Configure navigation agent
	if navigation_agent:
		navigation_agent.path_desired_distance = 0.5
		navigation_agent.target_desired_distance = 0.5
		navigation_agent.avoidance_enabled = true
		navigation_agent.radius = 0.5
		navigation_agent.height = 1.8

	print("Customer spawned: ", customer_id)

func _physics_process(delta: float) -> void:
	# Update state machine
	match current_state:
		State.ENTERING:
			_state_entering(delta)
		State.BROWSING:
			_state_browsing(delta)
		State.WAITING_CHECKOUT:
			_state_waiting_checkout(delta)
		State.CHECKING_OUT:
			_state_checking_out(delta)
		State.LEAVING:
			_state_leaving(delta)
		State.EXITED:
			pass  # Do nothing, waiting for cleanup

	# Update mood based on patience
	_update_mood()

func initialize(entrance: Vector3, display: Vector3, register: Vector3, exit: Vector3) -> void:
	"""Initialize customer with target positions"""
	entrance_position = entrance
	display_position = display
	register_position = register
	exit_position = exit

	# Start by walking to display case
	set_target_position(display_position)
	current_state = State.ENTERING
	print(customer_id, ": Initialized, heading to display case")

func set_target_position(target: Vector3) -> void:
	"""Set navigation target"""
	if navigation_agent:
		navigation_agent.target_position = target

# State handlers
func _state_entering(delta: float) -> void:
	"""Customer is walking to display case"""
	_navigate_to_target(delta)

	if _is_at_target():
		print(customer_id, ": Reached display case, browsing...")
		current_state = State.BROWSING
		browse_time = 0.0
		reached_display_case.emit()

func _state_browsing(delta: float) -> void:
	"""Customer is browsing items at display case"""
	browse_time += delta

	if browse_time >= max_browse_time:
		# Finished browsing, decide what to buy
		_select_items_to_purchase()

		if selected_items.size() > 0:
			# Has items, go to register
			print(customer_id, ": Selected items, going to register")
			set_target_position(register_position)
			current_state = State.WAITING_CHECKOUT
		else:
			# Nothing to buy, leave disappointed
			print(customer_id, ": Nothing to buy, leaving")
			satisfaction_score -= 20.0
			set_target_position(exit_position)
			current_state = State.LEAVING

func _state_waiting_checkout(delta: float) -> void:
	"""Customer is walking to register or waiting in line"""
	_navigate_to_target(delta)

	if _is_at_target():
		print(customer_id, ": At register, waiting for checkout")
		current_state = State.CHECKING_OUT
		reached_register.emit()

	# Drain patience while waiting
	patience -= patience_drain_rate * delta

func _state_checking_out(delta: float) -> void:
	"""Customer is at register, being served"""
	# Wait for external checkout completion
	# This will be called by Register when transaction completes
	patience -= patience_drain_rate * delta * 0.5  # Slower drain during checkout

func _state_leaving(delta: float) -> void:
	"""Customer is leaving the bakery"""
	_navigate_to_target(delta)

	if _is_at_target():
		current_state = State.EXITED
		print(customer_id, ": Exited bakery")
		left_bakery.emit()
		# Customer will be removed by CustomerManager

# Navigation helpers
func _navigate_to_target(delta: float) -> void:
	"""Move toward navigation target"""
	if not navigation_agent:
		return

	if navigation_agent.is_navigation_finished():
		return

	var next_position: Vector3 = navigation_agent.get_next_path_position()
	var direction: Vector3 = (next_position - global_position).normalized()

	# Move
	velocity = direction * move_speed
	move_and_slide()

	# Rotate toward direction
	if direction.length() > 0.01:
		var target_rotation: float = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, rotation_speed * delta)

func _is_at_target() -> bool:
	"""Check if customer reached their target"""
	if not navigation_agent:
		return false
	return navigation_agent.is_navigation_finished()

# Shopping logic
func _select_items_to_purchase() -> void:
	"""Select items from display case based on what's available"""
	# Get available items from display case
	var display_inventory: Dictionary = InventoryManager.get_inventory("display_case")

	if display_inventory.is_empty():
		print(customer_id, ": Display case is empty!")
		return

	# For now, randomly select 1-3 items from what's available
	var available_items: Array = []
	for item_id in display_inventory:
		var quantity: int = display_inventory[item_id]
		if quantity > 0:
			available_items.append(item_id)

	if available_items.is_empty():
		print(customer_id, ": No items in display case")
		return

	# Pick random items
	var num_items: int = randi_range(1, min(3, available_items.size()))
	for i in range(num_items):
		var random_item: String = available_items.pick_random()
		selected_items.append({
			"item_id": random_item,
			"quantity": 1
		})

	print(customer_id, ": Selected ", selected_items.size(), " items to purchase")

func get_selected_items() -> Array[Dictionary]:
	"""Get items customer wants to purchase"""
	return selected_items

func get_total_cost() -> float:
	"""Calculate total cost of selected items"""
	var total: float = 0.0

	for item_data in selected_items:
		var item_id: String = item_data["item_id"]

		# Look up price from RecipeManager
		var recipe: Dictionary = RecipeManager.get_recipe(item_id)
		if not recipe.is_empty():
			var price: float = recipe.get("base_price", 0.0)
			total += price * item_data["quantity"]

	return total

func complete_purchase() -> void:
	"""Called when checkout is complete"""
	var total: float = get_total_cost()
	print(customer_id, ": Purchase complete! Spent $%.2f" % total)

	# Update satisfaction based on experience
	_calculate_final_satisfaction()

	# Head to exit
	set_target_position(exit_position)
	current_state = State.LEAVING
	purchase_complete.emit(selected_items, total)

func _calculate_final_satisfaction() -> void:
	"""Calculate final satisfaction score"""
	# Base satisfaction is 50
	satisfaction_score = 50.0

	# Positive factors
	if patience > 50:
		satisfaction_score += 20.0  # Didn't wait too long
	if selected_items.size() >= 2:
		satisfaction_score += 10.0  # Got multiple items

	# Negative factors
	if patience < 30:
		satisfaction_score -= 20.0  # Waited too long
	if selected_items.is_empty():
		satisfaction_score -= 30.0  # Couldn't buy anything

	satisfaction_score = clamp(satisfaction_score, 0.0, 100.0)

	# Update mood
	if satisfaction_score >= 70:
		current_mood = Mood.HAPPY
	elif satisfaction_score >= 40:
		current_mood = Mood.NEUTRAL
	else:
		current_mood = Mood.UNHAPPY

	print(customer_id, ": Final satisfaction: %.0f%% (%s)" % [satisfaction_score, Mood.keys()[current_mood]])

func _update_mood() -> void:
	"""Update mood based on patience"""
	if patience > 60:
		current_mood = Mood.HAPPY
	elif patience > 30:
		current_mood = Mood.NEUTRAL
	else:
		current_mood = Mood.UNHAPPY

# Getters
func get_mood() -> Mood:
	return current_mood

func get_satisfaction() -> float:
	return satisfaction_score

func get_state() -> State:
	return current_state

func is_waiting_at_register() -> bool:
	return current_state == State.CHECKING_OUT
