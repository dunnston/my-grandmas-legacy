extends Node

# CustomerManager - Singleton for managing customer spawning, tracking, and behavior
# Handles customer lifecycle and satisfaction tracking

# Signals
signal customer_spawned(customer: Node3D)
signal customer_completed_purchase(customer: Node3D, items: Array, total: float)
signal customer_left(customer: Node3D, satisfaction: float)
signal daily_customer_stats_ready(total_customers: int, total_revenue: float, avg_satisfaction: float)

# Customer scene
var customer_scene: PackedScene = preload("res://scenes/customer/customer.tscn")

# Active customers
var active_customers: Array[Node3D] = []
var customers_served_today: int = 0
var total_satisfaction_today: float = 0.0

# Spawn settings
var is_spawning_enabled: bool = false
var spawn_interval: float = 10.0  # Seconds between customer spawns
var time_since_last_spawn: float = 0.0

# Navigation targets (set by bakery scene)
var entrance_position: Vector3 = Vector3.ZERO
var display_case_position: Vector3 = Vector3.ZERO
var register_position: Vector3 = Vector3.ZERO
var exit_position: Vector3 = Vector3.ZERO
var spawn_parent: Node3D = null  # Where to add customer nodes

# Traffic calculation
var base_customers_per_hour: float = 6.0  # At 50 reputation
var current_traffic_modifier: float = 1.0  # Can be adjusted by marketing, events, etc.

func _ready() -> void:
	print("CustomerManager initialized")

func _process(delta: float) -> void:
	if not is_spawning_enabled:
		return

	if GameManager.current_phase != GameManager.Phase.BUSINESS:
		return

	# Spawn customers at intervals
	time_since_last_spawn += delta
	if time_since_last_spawn >= spawn_interval:
		spawn_customer()
		time_since_last_spawn = 0.0

func setup_navigation_targets(entrance: Vector3, display: Vector3, register: Vector3, exit: Vector3) -> void:
	"""Set up navigation targets for customers (called by bakery scene)"""
	entrance_position = entrance
	display_case_position = display
	register_position = register
	exit_position = exit
	print("CustomerManager: Navigation targets set")

func set_spawn_parent(parent: Node3D) -> void:
	"""Set the node that will parent spawned customers"""
	spawn_parent = parent
	print("CustomerManager: Spawn parent set to ", parent.name)

func start_spawning() -> void:
	"""Start spawning customers (called when Business phase starts)"""
	is_spawning_enabled = true
	time_since_last_spawn = 0.0

	# Recalculate spawn interval based on current reputation and modifiers
	calculate_spawn_interval()

	print("CustomerManager: Spawning enabled")

func stop_spawning() -> void:
	"""Stop spawning customers (called when Business phase ends)"""
	is_spawning_enabled = false
	print("CustomerManager: Spawning disabled")

func spawn_customer() -> Node3D:
	"""Spawn a new customer"""
	if not spawn_parent:
		push_warning("CustomerManager: No spawn parent set!")
		return null

	if entrance_position == Vector3.ZERO:
		push_warning("CustomerManager: Navigation targets not set!")
		return null

	# Create customer instance
	var customer: Node3D = customer_scene.instantiate()
	spawn_parent.add_child(customer)

	# Set starting position
	customer.global_position = entrance_position

	# Initialize with navigation targets
	customer.initialize(entrance_position, display_case_position, register_position, exit_position)

	# Connect signals
	customer.purchase_complete.connect(_on_customer_purchase_complete.bind(customer))
	customer.left_bakery.connect(_on_customer_left.bind(customer))

	# Track customer
	active_customers.append(customer)

	print("CustomerManager: Spawned customer (Total active: %d)" % active_customers.size())
	customer_spawned.emit(customer)

	return customer

func _on_customer_purchase_complete(items: Array, total: float, customer: Node3D) -> void:
	"""Called when a customer completes their purchase"""
	print("CustomerManager: Customer completed purchase ($%.2f)" % total)

	# Record sale in economy
	EconomyManager.add_money(total, "Customer sale")

	customers_served_today += 1
	customer_completed_purchase.emit(customer, items, total)

func _on_customer_left(customer: Node3D) -> void:
	"""Called when a customer leaves the bakery"""
	var satisfaction: float = customer.get_satisfaction() if customer.has_method("get_satisfaction") else 50.0

	print("CustomerManager: Customer left (Satisfaction: %.0f%%)" % satisfaction)

	# Track satisfaction
	total_satisfaction_today += satisfaction

	# Emit signal
	customer_left.emit(customer, satisfaction)

	# Remove from active customers
	active_customers.erase(customer)

	# Clean up customer node
	customer.queue_free()

func get_customers_waiting_at_register() -> Array[Node3D]:
	"""Get all customers currently waiting at the register"""
	var waiting: Array[Node3D] = []
	for customer in active_customers:
		if customer.has_method("is_waiting_at_register") and customer.is_waiting_at_register():
			waiting.append(customer)
	return waiting

func get_next_customer_at_register() -> Node3D:
	"""Get the first customer waiting at register"""
	var waiting: Array[Node3D] = get_customers_waiting_at_register()
	if waiting.size() > 0:
		return waiting[0]
	return null

# Daily reporting
func generate_daily_customer_report() -> Dictionary:
	"""Generate customer satisfaction report for the day and update reputation"""
	var avg_satisfaction: float = 0.0
	if customers_served_today > 0:
		avg_satisfaction = total_satisfaction_today / customers_served_today

	var report: Dictionary = {
		"customers_served": customers_served_today,
		"average_satisfaction": avg_satisfaction,
		"active_customers": active_customers.size()
	}

	print("\n=== DAILY CUSTOMER REPORT ===")
	print("Customers served: %d" % customers_served_today)
	print("Avg satisfaction: %.1f%%" % avg_satisfaction)

	# Update reputation based on average satisfaction
	if ProgressionManager and customers_served_today > 0:
		var reputation_change: int = calculate_reputation_change(avg_satisfaction)
		if reputation_change != 0:
			ProgressionManager.modify_reputation(reputation_change)
			print("Reputation change: %+d" % reputation_change)

	print("=============================\n")

	daily_customer_stats_ready.emit(customers_served_today, 0.0, avg_satisfaction)
	return report

func calculate_reputation_change(avg_satisfaction: float) -> int:
	"""Calculate how much reputation should change based on customer satisfaction"""
	# Satisfaction thresholds:
	# 90+ = +3 reputation (excellent service)
	# 75-89 = +2 reputation (very good)
	# 60-74 = +1 reputation (good)
	# 50-59 = 0 reputation (neutral)
	# 40-49 = -1 reputation (below average)
	# 25-39 = -2 reputation (poor)
	# <25 = -3 reputation (terrible)

	if avg_satisfaction >= 90:
		return 3
	elif avg_satisfaction >= 75:
		return 2
	elif avg_satisfaction >= 60:
		return 1
	elif avg_satisfaction >= 50:
		return 0
	elif avg_satisfaction >= 40:
		return -1
	elif avg_satisfaction >= 25:
		return -2
	else:
		return -3

func reset_daily_stats() -> void:
	"""Reset daily stats for new day"""
	customers_served_today = 0
	total_satisfaction_today = 0.0
	print("CustomerManager: Daily stats reset")

func clear_all_customers() -> void:
	"""Remove all active customers (for phase transitions)"""
	for customer in active_customers:
		customer.queue_free()
	active_customers.clear()
	print("CustomerManager: All customers cleared")

# Traffic calculation with reputation (Phase 3+)
func calculate_spawn_interval() -> void:
	"""Calculate spawn interval based on reputation, day of week, and modifiers"""
	var reputation_modifier: float = calculate_reputation_traffic_modifier()
	var day_of_week_modifier: float = get_day_of_week_modifier()

	# Calculate customers per hour
	var customers_per_hour: float = base_customers_per_hour * reputation_modifier * day_of_week_modifier * current_traffic_modifier

	# Convert to spawn interval (seconds between spawns)
	spawn_interval = 60.0 / customers_per_hour
	spawn_interval = clamp(spawn_interval, 3.0, 120.0)  # Min 3s, max 120s between customers

	print("Traffic calculation: %.1f customers/hour (interval: %.1fs)" % [customers_per_hour, spawn_interval])

func calculate_reputation_traffic_modifier() -> float:
	"""Calculate traffic modifier based on reputation (50 = 1.0x, 100 = 2.5x, 0 = 0.1x)"""
	if not ProgressionManager:
		return 1.0  # Default if no progression manager

	var reputation: int = ProgressionManager.get_reputation()

	# Reputation scaling:
	# 0 reputation = 0.1x traffic (90% reduction)
	# 50 reputation = 1.0x traffic (baseline)
	# 75 reputation = 1.5x traffic (50% increase)
	# 100 reputation = 2.5x traffic (150% increase)

	if reputation >= 50:
		# Above average: scale from 1.0x to 2.5x
		var progress: float = (reputation - 50) / 50.0
		return lerp(1.0, 2.5, progress)
	else:
		# Below average: scale from 0.1x to 1.0x
		var progress: float = reputation / 50.0
		return lerp(0.1, 1.0, progress)

func get_day_of_week_modifier() -> float:
	"""Get traffic modifier based on day of week"""
	if not GameManager:
		return 1.0

	var day: int = GameManager.get_current_day()
	var day_of_week: int = (day - 1) % 7  # 0 = Monday, 6 = Sunday

	# Traffic pattern:
	# Mon-Thu: 1.0x (normal weekdays)
	# Friday: 1.3x (busy end of week)
	# Saturday: 1.5x (busiest day)
	# Sunday: 1.2x (brunch crowd)

	match day_of_week:
		0, 1, 2, 3:  # Mon-Thu
			return 1.0
		4:  # Friday
			return 1.3
		5:  # Saturday
			return 1.5
		6:  # Sunday
			return 1.2
		_:
			return 1.0

func set_traffic_modifier(modifier: float) -> void:
	"""Set additional traffic modifier (for marketing, events, etc.)"""
	current_traffic_modifier = clamp(modifier, 0.1, 5.0)
	print("Traffic modifier set to %.1fx" % current_traffic_modifier)
	calculate_spawn_interval()

func get_projected_daily_customers() -> int:
	"""Project number of customers for today (for planning phase display)"""
	var reputation_modifier: float = calculate_reputation_traffic_modifier()
	var day_modifier: float = get_day_of_week_modifier()

	# Business phase is typically 8 hours (9 AM - 5 PM)
	var business_hours: float = 8.0
	var projected_customers: int = int(base_customers_per_hour * reputation_modifier * day_modifier * current_traffic_modifier * business_hours)

	return projected_customers

# Save/Load support
func get_save_data() -> Dictionary:
	# Clear active customers before saving to prevent stale customer state
	# Customers will naturally respawn when business phase starts
	clear_all_customers()

	return {
		"customers_served_today": customers_served_today,
		"total_satisfaction_today": total_satisfaction_today
	}

func load_save_data(data: Dictionary) -> void:
	if data.has("customers_served_today"):
		customers_served_today = data["customers_served_today"]
	if data.has("total_satisfaction_today"):
		total_satisfaction_today = data["total_satisfaction_today"]
	print("CustomerManager data loaded")
