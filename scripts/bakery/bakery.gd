extends Node3D

# Bakery - Main scene controller for the bakery
# Manages phase transitions, customer spawning, and UI

# Node references
@onready var equipment: Node3D = $Equipment
@onready var customers_container: Node3D = $Customers
@onready var planning_menu: CanvasLayer = $UILayer/PlanningMenu
@onready var hud: CanvasLayer = $UILayer/HUD

# Navigation markers
@onready var entrance_marker: Marker3D = $NavigationMarkers/Entrance
@onready var display_marker: Marker3D = $NavigationMarkers/DisplayCase
@onready var register_marker: Marker3D = $NavigationMarkers/Register
@onready var exit_marker: Marker3D = $NavigationMarkers/Exit
@onready var package_spawn_marker: Marker3D = $NavigationMarkers/PackageSpawn

# Package scene
const PACKAGE_SCENE = preload("res://scenes/equipment/package.tscn")
var current_package: Node3D = null

func _ready() -> void:
	print("Bakery scene ready")

	# Add to bakery group for easy access
	add_to_group("bakery")

	# Set up CustomerManager with navigation targets
	if customers_container and entrance_marker and register_marker and exit_marker:
		CustomerManager.set_spawn_parent(customers_container)

		# Find display case position dynamically (in case it was moved)
		var display_case = equipment.get_node_or_null("DisplayCase")
		var display_position = display_marker.global_position if display_marker else Vector3.ZERO

		if display_case:
			display_position = display_case.global_position
			print("Using actual DisplayCase position: ", display_position)
		elif display_marker:
			print("DisplayCase not found, using marker position: ", display_position)
		else:
			push_warning("No DisplayCase or marker found!")

		CustomerManager.setup_navigation_targets(
			entrance_marker.global_position,
			display_position,
			register_marker.global_position,
			exit_marker.global_position
		)
		print("Customer navigation targets configured")

		# Set up StaffManager entrance position (staff spawn at same place as customers)
		StaffManager.set_entrance_position(entrance_marker.global_position)
		print("Staff entrance position configured")
	else:
		push_warning("Some navigation markers are missing!")

	# Connect to GameManager phase changes
	GameManager.phase_changed.connect(_on_phase_changed)

	# Connect Planning Menu
	if planning_menu:
		planning_menu.next_day_started.connect(_on_next_day_started)

	# Connect DeliveryManager signals
	DeliveryManager.delivery_available.connect(_on_delivery_available)
	DeliveryManager.package_emptied.connect(_on_package_emptied)

	# Set package spawn position
	if package_spawn_marker:
		DeliveryManager.set_package_spawn_position(package_spawn_marker.global_position)

	# Check if there's a package to spawn on load
	if DeliveryManager.is_package_available():
		_spawn_package()

	# Start in Baking phase
	_on_phase_changed(GameManager.Phase.BAKING)

func _on_phase_changed(new_phase: GameManager.Phase) -> void:
	"""Handle phase transitions"""
	print("Bakery: Phase changed to ", GameManager.Phase.keys()[new_phase])

	match new_phase:
		GameManager.Phase.BAKING:
			_setup_baking_phase()
		GameManager.Phase.BUSINESS:
			_setup_business_phase()
		GameManager.Phase.CLEANUP:
			_setup_cleanup_phase()
		GameManager.Phase.PLANNING:
			_setup_planning_phase()

func _setup_baking_phase() -> void:
	"""Set up for baking phase"""
	print("Bakery: Setting up Baking phase")

	# Hide planning menu if visible
	if planning_menu:
		planning_menu.close_menu()

	# Update HUD
	if hud:
		hud.show_phase_info("BAKING PHASE", "Prepare goods for the day")

func _setup_business_phase() -> void:
	"""Set up for business phase"""
	print("Bakery: Setting up Business phase")

	# Customers will start spawning automatically via CustomerManager
	if hud:
		hud.show_phase_info("BUSINESS PHASE", "Shop is open!")

func _setup_cleanup_phase() -> void:
	"""Set up for cleanup phase"""
	print("Bakery: Setting up Cleanup phase")

	# GameManager handles cleanup automatically
	if hud:
		hud.show_phase_info("CLEANUP PHASE", "Cleaning up...")

func _setup_planning_phase() -> void:
	"""Set up for planning phase"""
	print("Bakery: Setting up Planning phase")

	# Open planning menu
	if planning_menu:
		planning_menu.open_menu()

	if hud:
		hud.show_phase_info("PLANNING PHASE", "Review and prepare")

func _on_next_day_started() -> void:
	"""Called when player starts next day from planning menu"""
	print("Bakery: Next day started")
	# GameManager.end_day() is called by planning menu, which triggers phase change

# Public methods for UI buttons
func start_business_phase() -> void:
	"""Manually trigger business phase (called by UI button)"""
	GameManager.start_business_phase()

func end_business_phase() -> void:
	"""Manually end business phase (called by UI button)"""
	GameManager.start_cleanup_phase()

# ============================================================================
# PACKAGE DELIVERY SYSTEM
# ============================================================================

func _on_delivery_available() -> void:
	"""Called when a delivery is available"""
	print("Bakery: Delivery available!")
	_spawn_package()

func _spawn_package() -> void:
	"""Spawn a package in the bakery"""
	# Don't spawn if package already exists
	if current_package and is_instance_valid(current_package):
		print("Bakery: Package already spawned")
		return

	if not PACKAGE_SCENE:
		push_error("Package scene not found!")
		return

	# Instance package
	current_package = PACKAGE_SCENE.instantiate()

	# Position it at spawn marker (or default position near entrance)
	if package_spawn_marker:
		current_package.global_position = package_spawn_marker.global_position
	else:
		# Default to near entrance if no marker exists
		if entrance_marker:
			current_package.global_position = entrance_marker.global_position + Vector3(1, 0, 1)
		else:
			current_package.global_position = Vector3(0, 0, 0)

	# Add to scene
	add_child(current_package)

	print("Bakery: Package spawned at position: ", current_package.global_position)

func _on_package_emptied() -> void:
	"""Called when package is emptied"""
	print("Bakery: Package emptied")
	current_package = null
