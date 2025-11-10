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

# GDD Section 4.2.1: Customer Types
enum CustomerType {
	LOCAL,      # Price-conscious, want staples
	TOURIST,    # Less price-sensitive, want variety
	REGULAR     # Forgiving on price/wait, consistent orders
}

# Node references
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var feedback_system: Node3D = null  # Created dynamically in _ready
var animation_player: AnimationPlayer = null  # Reference to active customer's AnimationPlayer

# Customer properties
var customer_id: String = ""
var current_state: State = State.ENTERING
var current_mood: Mood = Mood.NEUTRAL
var _last_logged_mood: Mood = Mood.NEUTRAL  # Track mood changes for logging
var customer_type: CustomerType = CustomerType.LOCAL  # Default type

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

# Queue system
var queue_position_index: int = -1  # -1 means not in queue
var queue_target_position: Vector3 = Vector3.ZERO
var is_in_queue: bool = false

# Satisfaction factors
var satisfaction_score: float = 50.0  # 0-100

# Static counter for unique IDs
static var _customer_counter: int = 0

func _ready() -> void:
	_customer_counter += 1
	customer_id = "customer_%d_%d" % [Time.get_ticks_msec(), _customer_counter]

	# Configure navigation agent
	if navigation_agent:
		navigation_agent.path_desired_distance = 0.5
		navigation_agent.target_desired_distance = 0.5
		navigation_agent.avoidance_enabled = true
		navigation_agent.radius = 0.5
		navigation_agent.height = 1.8

	# Randomly select and show one customer model
	_select_random_customer_model()

	# Add random initial rotation
	rotation.y = randf_range(0.0, TAU)

	# Create feedback system (speech bubbles, emojis)
	_create_feedback_system()

	print("Customer spawned: ", customer_id)

func _create_feedback_system() -> void:
	"""Create and attach visual feedback system"""
	var feedback_script = load("res://scripts/customer/customer_feedback.gd")
	if feedback_script:
		feedback_system = Node3D.new()
		feedback_system.name = "FeedbackSystem"
		feedback_system.set_script(feedback_script)
		add_child(feedback_system)
		print(customer_id, ": Feedback system created")

func _select_random_customer_model() -> void:
	"""Randomly select one of the 5 customer models and make it visible"""
	# Pick random customer model (1-5)
	var model_num: int = randi_range(1, 5)
	var model_name: String = "CustomerModel%d" % model_num

	# Find and show the selected model
	var selected_model = get_node_or_null(model_name)
	if selected_model:
		selected_model.visible = true
		print(customer_id, ": Using customer model ", model_num)

		# Find and configure AnimationPlayer
		animation_player = _find_animation_player(selected_model)
		if animation_player and animation_player is AnimationPlayer:
			# Make sure AnimationPlayer is active
			animation_player.active = true
			animation_player.process_mode = Node.PROCESS_MODE_INHERIT

			# Get the first animation
			var anims = animation_player.get_animation_list()
			if anims.size() > 0:
				var anim_name = anims[0]

				# Get the animation library and set loop mode
				var anim_lib = animation_player.get_animation_library("")
				if anim_lib and anim_lib.has_animation(anim_name):
					var animation = anim_lib.get_animation(anim_name)
					if animation:
						animation.loop_mode = Animation.LOOP_LINEAR

				# Play the animation immediately
				animation_player.play(anim_name)

				# Force update to ensure animation starts
				animation_player.advance(0.0)

				print(customer_id, ": Walking animation started (", anim_name, ")")
		else:
			print(customer_id, ": Warning - Could not find AnimationPlayer")
	else:
		print(customer_id, ": Warning - Could not find customer model: ", model_name)

func _find_animation_player(node: Node) -> AnimationPlayer:
	"""Recursively search for AnimationPlayer"""
	# Check if current node is AnimationPlayer
	if node is AnimationPlayer:
		return node

	# Check direct children
	for child in node.get_children():
		if child is AnimationPlayer:
			return child

	# Search recursively
	for child in node.get_children():
		var result = _find_animation_player(child)
		if result:
			return result

	return null

func _process(delta: float) -> void:
	# Update state machine (AI logic in _process, not _physics_process)
	match current_state:
		State.BROWSING:
			_state_browsing(delta)
		State.CHECKING_OUT:
			_state_checking_out(delta)
		State.EXITED:
			pass  # Do nothing, waiting for cleanup
		_:
			pass  # Movement states handled in _physics_process

	# Update mood based on patience
	_update_mood()

func _physics_process(delta: float) -> void:
	# Only handle movement and navigation in physics process
	match current_state:
		State.ENTERING:
			_state_entering(delta)
		State.WAITING_CHECKOUT:
			_state_waiting_checkout(delta)
		State.LEAVING:
			_state_leaving(delta)
		_:
			pass  # Non-movement states handled in _process

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
		_update_animation_state(false)  # Pause animation while browsing
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
		_update_animation_state(false)  # Pause animation at register
		reached_register.emit()

		# Show speech bubble to indicate ready for checkout
		if feedback_system and feedback_system.has_method("show_speech_bubble"):
			feedback_system.show_speech_bubble()

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
		_update_animation_state(false)  # Pause animation when exited
		print(customer_id, ": Exited bakery")
		left_bakery.emit()
		# Customer will be removed by CustomerManager

# Navigation helpers
func _navigate_to_target(delta: float) -> void:
	"""Move toward navigation target"""
	if not navigation_agent:
		return

	if navigation_agent.is_navigation_finished():
		# Stopped at destination - pause animation
		_update_animation_state(false)
		return

	var next_position: Vector3 = navigation_agent.get_next_path_position()
	var direction: Vector3 = (next_position - global_position).normalized()

	# Move
	velocity = direction * move_speed
	move_and_slide()

	# Resume animation while moving
	_update_animation_state(true)

	# Rotate toward direction
	if direction.length() > 0.01:
		var target_rotation: float = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, rotation_speed * delta)

func _is_at_target() -> bool:
	"""Check if customer reached their target"""
	if not navigation_agent:
		return false
	return navigation_agent.is_navigation_finished()

func _update_animation_state(is_moving: bool) -> void:
	"""Pause or resume walking animation based on movement state"""
	if not animation_player:
		return

	if is_moving:
		# Resume animation if paused
		if not animation_player.is_playing():
			animation_player.play()
	else:
		# Pause animation (freezes at current frame - no T-pose!)
		if animation_player.is_playing():
			animation_player.pause()

# Shopping logic
func _select_items_to_purchase() -> void:
	"""Select items from display case based on what's available and price tolerance"""
	# Get available items from display case
	var display_inventory: Dictionary = InventoryManager.get_inventory("display_case")

	if display_inventory.is_empty():
		print(customer_id, ": Display case is empty!")
		return

	# Filter items by availability AND price tolerance (GDD Section 4.2.4)
	var available_items: Array = []
	var rejected_count: int = 0

	for item_id in display_inventory:
		var quantity: int = display_inventory[item_id]
		if quantity > 0:
			# Check if customer accepts the price
			if _check_price_acceptable(item_id):
				available_items.append(item_id)
			else:
				rejected_count += 1

	if available_items.is_empty():
		if rejected_count > 0:
			print(customer_id, ": All items too expensive! (rejected ", rejected_count, " items)")
		else:
			print(customer_id, ": No items in display case")
		return

	if rejected_count > 0:
		print(customer_id, ": Rejected ", rejected_count, " items due to high prices")

	# Pick random items (no duplicates)
	var num_items: int = randi_range(1, min(3, available_items.size()))
	available_items.shuffle()  # Randomize order
	for i in range(num_items):
		if i < available_items.size():
			selected_items.append({
				"item_id": available_items[i],
				"quantity": randi_range(1, 2)  # Customer may want 1-2 of each item
			})

	print(customer_id, ": Selected ", selected_items.size(), " items to purchase")

func get_selected_items() -> Array[Dictionary]:
	"""Get items customer wants to purchase"""
	return selected_items

func get_total_cost() -> float:
	"""Calculate total cost of selected items (with quality-adjusted pricing)"""
	var total: float = 0.0

	for item_data in selected_items:
		var item_id: String = item_data["item_id"]

		# Look up price from RecipeManager
		var recipe: Dictionary = RecipeManager.get_recipe(item_id) if RecipeManager else {}
		if not recipe.is_empty():
			var base_price: float = recipe.get("base_price", 0.0)
			var price: float = base_price

			# Check for quality metadata to get actual price
			var metadata: Dictionary = InventoryManager.get_item_metadata("display_case", item_id)
			if metadata.has("quality_data") and QualityManager:
				price = QualityManager.get_price_for_quality(base_price, metadata.quality_data)

			total += price * item_data["quantity"]

	return total

func update_queue_position(queue_index: int, target_pos: Vector3) -> void:
	"""Called by CustomerManager when queue position changes
	Args:
		queue_index: Position in queue (0 = front, 1 = second, etc.)
		target_pos: Where customer should stand in queue
	"""
	queue_position_index = queue_index
	queue_target_position = target_pos
	is_in_queue = true

	print(customer_id, ": Updated queue position to %d at %v" % [queue_index, target_pos])

	# If in WAITING_CHECKOUT or CHECKING_OUT state, update target
	if current_state == State.WAITING_CHECKOUT or (current_state == State.CHECKING_OUT and queue_index > 0):
		set_target_position(queue_target_position)
		# If not at front, need to keep navigating
		if queue_index > 0:
			current_state = State.WAITING_CHECKOUT
			_update_animation_state(true)  # Resume walking animation

func complete_purchase(transaction_time: float = 0.0, had_errors: bool = false) -> void:
	"""Called when checkout is complete
	Args:
		transaction_time: How long the checkout took in seconds
		had_errors: Whether any errors occurred during checkout
	"""
	var total: float = get_total_cost()
	print(customer_id, ": Purchase complete! Spent $%.2f" % total)

	# Update satisfaction based on experience
	_calculate_final_satisfaction(transaction_time, had_errors)

	# Show satisfaction emoji
	if feedback_system and feedback_system.has_method("show_satisfaction_emoji"):
		feedback_system.show_satisfaction_emoji(satisfaction_score, had_errors, transaction_time)

	# Remove from queue (allows next customer to advance)
	if is_in_queue and CustomerManager:
		CustomerManager.remove_from_queue(self)
		is_in_queue = false
		queue_position_index = -1

	# Head to exit
	set_target_position(exit_position)
	current_state = State.LEAVING
	purchase_complete.emit(selected_items, total)

func _calculate_final_satisfaction(transaction_time: float = 0.0, had_errors: bool = false) -> void:
	"""Calculate final satisfaction score based on checkout experience
	Args:
		transaction_time: How long the checkout took in seconds
		had_errors: Whether any errors occurred during checkout
	"""
	# Base satisfaction is 50
	satisfaction_score = 50.0

	# Positive factors
	if patience > 50:
		satisfaction_score += 20.0  # Didn't wait too long
	if selected_items.size() >= 2:
		satisfaction_score += 10.0  # Got multiple items

	# Checkout speed factors (GDD Section 4.2.3 - Speed affects satisfaction)
	if transaction_time > 0:
		if transaction_time < 30.0:
			satisfaction_score += 15.0  # Fast service!
		elif transaction_time > 60.0:
			satisfaction_score -= 20.0  # Slow service

	# Accuracy factors
	if had_errors:
		satisfaction_score -= 15.0  # Made mistakes during checkout

	# Negative factors
	if patience < 30:
		satisfaction_score -= 20.0  # Waited too long in line
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

	print(customer_id, ": Final satisfaction: %.0f%% (%s) [Time: %.1fs, Errors: %s]" % [
		satisfaction_score,
		Mood.keys()[current_mood],
		transaction_time,
		"Yes" if had_errors else "No"
	])

func _update_mood() -> void:
	"""Update mood based on patience"""
	var old_mood = current_mood

	if patience > 60:
		current_mood = Mood.HAPPY
	elif patience > 30:
		current_mood = Mood.NEUTRAL
	else:
		current_mood = Mood.UNHAPPY

	# Only log when mood changes (performance optimization)
	if old_mood != current_mood and _last_logged_mood != current_mood:
		print(customer_id, ": Mood changed to ", Mood.keys()[current_mood], " (patience: %.0f%%)" % patience)
		_last_logged_mood = current_mood

# Getters
func get_mood() -> Mood:
	return current_mood

func get_satisfaction() -> float:
	return satisfaction_score

func get_state() -> State:
	return current_state

func is_waiting_at_register() -> bool:
	return current_state == State.CHECKING_OUT

func get_customer_type() -> CustomerType:
	return customer_type

func set_customer_type(type: CustomerType) -> void:
	customer_type = type
	print(customer_id, ": Customer type set to ", CustomerType.keys()[type])

# Price Tolerance System (GDD Section 4.2.4, Lines 278-286)
func _check_price_acceptable(item_id: String) -> bool:
	"""Check if customer accepts the current price for an item"""
	if not RecipeManager:
		return true  # Default accept if no price system

	# Get recipe and current price
	var recipe: Dictionary = RecipeManager.get_recipe(item_id)
	if recipe.is_empty():
		return true

	var base_price: float = recipe.get("base_price", 0.0)
	var current_price: float = base_price

	# Check for quality-adjusted price
	var metadata: Dictionary = InventoryManager.get_item_metadata("display_case", item_id)
	if metadata.has("quality_data") and QualityManager:
		current_price = QualityManager.get_price_for_quality(base_price, metadata.quality_data)

	# Check for player-set price (will be implemented next)
	if RecipeManager.has_method("get_player_price"):
		var player_price = RecipeManager.get_player_price(item_id)
		if player_price > 0:
			current_price = player_price

	# Calculate price tolerance based on customer type
	var tolerance_range = _get_price_tolerance_range(item_id, metadata)
	var min_acceptable = base_price * tolerance_range.min
	var max_acceptable = base_price * tolerance_range.max

	var acceptable = current_price >= min_acceptable and current_price <= max_acceptable

	if not acceptable:
		print(customer_id, " (%s): Rejected %s - $%.2f not in range $%.2f-$%.2f" % [
			CustomerType.keys()[customer_type],
			item_id,
			current_price,
			min_acceptable,
			max_acceptable
		])

	return acceptable

func _get_price_tolerance_range(item_id: String, metadata: Dictionary) -> Dictionary:
	"""Calculate min/max price tolerance for this customer"""
	# Base tolerance from customer type
	var min_tolerance: float = BalanceConfig.CUSTOMERS.price_tolerance_base_min
	var max_tolerance: float = BalanceConfig.CUSTOMERS.price_tolerance_base_max

	# Apply customer type modifiers
	match customer_type:
		CustomerType.REGULAR:
			min_tolerance = BalanceConfig.CUSTOMERS.regular_price_min
			max_tolerance = BalanceConfig.CUSTOMERS.regular_price_max
		CustomerType.TOURIST:
			min_tolerance = BalanceConfig.CUSTOMERS.tourist_price_min
			max_tolerance = BalanceConfig.CUSTOMERS.tourist_price_max
		CustomerType.LOCAL:
			min_tolerance = BalanceConfig.CUSTOMERS.local_price_min
			max_tolerance = BalanceConfig.CUSTOMERS.local_price_max

	# Quality affects tolerance (GDD: quality and reputation affect acceptance)
	if metadata.has("quality_data") and metadata.quality_data.has("quality"):
		var quality: float = metadata.quality_data.quality
		if quality >= 95:  # Excellent/Perfect
			if quality >= 100:
				max_tolerance += BalanceConfig.CUSTOMERS.quality_perfect_price_bonus
			else:
				max_tolerance += BalanceConfig.CUSTOMERS.quality_excellent_price_bonus
		elif quality < 70:  # Poor quality
			max_tolerance -= BalanceConfig.CUSTOMERS.quality_poor_price_penalty

	# Reputation affects tolerance (if ReputationManager exists)
	# Note: ReputationManager not yet implemented, will use when available
	# TODO: Integrate with ReputationManager when Phase 3 systems are complete
	# if ReputationManager:
	# 	var reputation = ReputationManager.get_reputation()
	# 	if reputation >= 75:
	# 		max_tolerance += BalanceConfig.CUSTOMERS.reputation_high_price_bonus
	# 	elif reputation < 30:
	# 		max_tolerance -= BalanceConfig.CUSTOMERS.reputation_low_price_penalty

	return {"min": min_tolerance, "max": max_tolerance}
