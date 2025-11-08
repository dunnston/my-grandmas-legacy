extends Node

# EquipmentUIManager - Manages all equipment UIs
# Singleton that handles showing/hiding equipment interfaces

# UI references (loaded dynamically)
var storage_ui: Control
var mixing_bowl_ui: Control
var oven_ui: Control
var cooling_rack_ui: Control
var display_case_ui: Control

# Current active UI
var active_ui: Control = null

# Preload UI scenes
const STORAGE_UI_SCENE = preload("res://scenes/ui/storage_ui.tscn")
const MIXING_BOWL_UI_SCENE = preload("res://scenes/ui/mixing_bowl_ui.tscn")
const OVEN_UI_SCENE = preload("res://scenes/ui/oven_ui.tscn")
const COOLING_RACK_UI_SCENE = preload("res://scenes/ui/cooling_rack_ui.tscn")
const DISPLAY_CASE_UI_SCENE = preload("res://scenes/ui/display_case_ui.tscn")

func _ready() -> void:
	print("EquipmentUIManager ready")

func setup_uis(parent: Node) -> void:
	"""Initialize all UI instances and add them to parent"""
	# Create UIs
	storage_ui = STORAGE_UI_SCENE.instantiate()
	mixing_bowl_ui = MIXING_BOWL_UI_SCENE.instantiate()
	oven_ui = OVEN_UI_SCENE.instantiate()
	cooling_rack_ui = COOLING_RACK_UI_SCENE.instantiate()
	display_case_ui = DISPLAY_CASE_UI_SCENE.instantiate()

	# Add to parent
	parent.add_child(storage_ui)
	parent.add_child(mixing_bowl_ui)
	parent.add_child(oven_ui)
	parent.add_child(cooling_rack_ui)
	parent.add_child(display_case_ui)

	# Connect close signals
	storage_ui.ui_closed.connect(_on_ui_closed)
	mixing_bowl_ui.ui_closed.connect(_on_ui_closed)
	oven_ui.ui_closed.connect(_on_ui_closed)
	cooling_rack_ui.ui_closed.connect(_on_ui_closed)
	display_case_ui.ui_closed.connect(_on_ui_closed)

	print("Equipment UIs initialized")

func show_storage_ui(equipment_inv_id: String, player_inv_id: String) -> void:
	"""Show storage UI"""
	_close_current_ui()
	storage_ui.open_ui(equipment_inv_id, player_inv_id)
	active_ui = storage_ui

func show_mixing_bowl_ui(equipment_inv_id: String, player_inv_id: String, equipment_node: Node) -> void:
	"""Show mixing bowl UI"""
	_close_current_ui()
	mixing_bowl_ui.open_ui_with_equipment(equipment_inv_id, player_inv_id, equipment_node)
	active_ui = mixing_bowl_ui

func show_oven_ui(equipment_inv_id: String, player_inv_id: String, equipment_node: Node) -> void:
	"""Show oven UI"""
	_close_current_ui()
	oven_ui.open_ui_with_equipment(equipment_inv_id, player_inv_id, equipment_node)
	active_ui = oven_ui

func show_cooling_rack_ui(equipment_inv_id: String, player_inv_id: String, equipment_node: Node) -> void:
	"""Show cooling rack UI"""
	_close_current_ui()
	cooling_rack_ui.open_ui_with_equipment(equipment_inv_id, player_inv_id, equipment_node)
	active_ui = cooling_rack_ui

func show_display_case_ui(equipment_inv_id: String, player_inv_id: String) -> void:
	"""Show display case UI"""
	_close_current_ui()
	display_case_ui.open_ui(equipment_inv_id, player_inv_id)
	active_ui = display_case_ui

func _close_current_ui() -> void:
	"""Close the currently active UI"""
	if active_ui and active_ui.visible:
		active_ui.close_ui()
	active_ui = null

func _on_ui_closed() -> void:
	"""Called when any UI is closed"""
	active_ui = null
	# Release mouse
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func is_ui_open() -> bool:
	"""Check if any equipment UI is currently open"""
	return active_ui != null and active_ui.visible
