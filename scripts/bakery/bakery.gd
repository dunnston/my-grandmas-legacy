extends Node3D

# Bakery - Main scene controller for the bakery
# Manages shop open/close, customer spawning, and UI

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

	# Connect to GameManager shop state changes
	GameManager.shop_state_changed.connect(_on_shop_state_changed)

	# Connect Planning Menu (if it exists)
	if planning_menu and planning_menu.has_signal("next_day_started"):
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

	# Update UI for initial closed state
	_on_shop_state_changed(false)

func _on_shop_state_changed(is_open: bool) -> void:
	"""Handle shop opening/closing"""
	print("Bakery: Shop state changed - Open: ", is_open)

	if is_open:
		_setup_shop_open()
	else:
		_setup_shop_closed()

func _setup_shop_open() -> void:
	"""Set up when shop opens"""
	print("Bakery: Shop is now OPEN")

	# Hide planning menu if visible
	if planning_menu and planning_menu.has_method("close_menu"):
		planning_menu.close_menu()

	# Update HUD
	if hud and hud.has_method("show_phase_info"):
		hud.show_phase_info("SHOP OPEN", "Serving customers!")

func _setup_shop_closed() -> void:
	"""Set up when shop closes"""
	print("Bakery: Shop is now CLOSED")

	# Update HUD
	if hud and hud.has_method("show_phase_info"):
		hud.show_phase_info("SHOP CLOSED", "Prepare goods or rest")

func _on_next_day_started() -> void:
	"""Called when player starts next day from planning menu"""
	print("Bakery: Next day started")

# Public methods for UI buttons
func open_shop() -> void:
	"""Manually open shop (called by UI button)"""
	GameManager.open_shop()

func close_shop() -> void:
	"""Manually close shop (called by UI button)"""
	GameManager.close_shop()

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
