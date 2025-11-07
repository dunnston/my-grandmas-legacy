extends Node3D

# Oven - Bakes dough into finished products

signal baking_started(item_name: String)
signal baking_complete(result_item: String)
signal item_burned

@export var baking_time: float = 300.0  # 5 minutes game time

# Node references
@onready var interaction_area: Area3D = $InteractionArea
@onready var mesh: MeshInstance3D = $OvenMesh
@onready var light: OmniLight3D = $OvenLight

# State
var is_baking: bool = false
var baking_timer: float = 0.0
var current_item: String = ""
var player_nearby: Node3D = null

# Baking recipes
const BAKING_RECIPES = {
	"bread_dough": {
		"result": "bread",
		"time": 300.0  # 5 minutes
	}
}

func _ready() -> void:
	# Create inventory for this station
	InventoryManager.create_inventory(get_inventory_id())

	# Connect interaction area
	if interaction_area:
		interaction_area.body_entered.connect(_on_body_entered)
		interaction_area.body_exited.connect(_on_body_exited)

	# Turn off light initially
	if light:
		light.visible = false

	print("Oven ready: ", name)

func _process(delta: float) -> void:
	if is_baking and not GameManager.is_game_paused():
		baking_timer += delta * GameManager.get_time_scale()

		# Update light intensity based on baking progress
		if light:
			light.light_energy = 0.5 + (baking_timer / baking_time) * 1.5

		if baking_timer >= baking_time:
			complete_baking()

# Interaction system
func _on_body_entered(body: Node3D) -> void:
	if body.has_method("get_inventory_id"):
		player_nearby = body
		if is_baking:
			print("[E] to check Oven")
		else:
			print("[E] to use Oven")

func _on_body_exited(body: Node3D) -> void:
	if body == player_nearby:
		player_nearby = null

func get_interaction_prompt() -> String:
	if is_baking:
		return "[E] Check Oven"
	return "[E] Use Oven"

func interact(player: Node3D) -> void:
	if is_baking:
		var time_remaining = baking_time - baking_timer
		print("Oven is baking! Time remaining: ", int(time_remaining), " seconds")
		print("Progress: ", int(get_baking_progress() * 100), "%")
		return

	open_oven_ui(player)

func open_oven_ui(player: Node3D) -> void:
	print("\n=== OVEN ===")
	print("Load dough to start baking")
	print("\nYour inventory:")
	InventoryManager.print_inventory("player")

	# Check if player has bakeable items
	var player_inventory = InventoryManager.get_inventory("player")
	var can_bake: bool = false

	for item_id in player_inventory.keys():
		if BAKING_RECIPES.has(item_id):
			print("\nYou can bake: ", item_id, " -> ", BAKING_RECIPES[item_id].result)
			print("Loading ", item_id, " into oven...")
			load_and_bake(player, item_id)
			can_bake = true
			break

	if not can_bake:
		print("You don't have any items to bake!")
		print("Try making bread dough at the mixing bowl first.")

func load_and_bake(player: Node3D, item_id: String) -> void:
	if not BAKING_RECIPES.has(item_id):
		print("Error: ", item_id, " cannot be baked")
		return

	# Transfer item from player to oven
	if InventoryManager.transfer_item("player", get_inventory_id(), item_id, 1):
		start_baking(item_id)
	else:
		print("Error: Could not load ", item_id, " into oven")

func start_baking(item_id: String) -> void:
	if not BAKING_RECIPES.has(item_id):
		return

	current_item = item_id
	is_baking = true
	baking_timer = 0.0
	baking_time = BAKING_RECIPES[item_id].time

	print("Started baking ", current_item, "!")
	print("Baking time: ", baking_time, " seconds")
	baking_started.emit(item_id)

	# Visual feedback
	if light:
		light.visible = true
		light.light_color = Color(1.0, 0.6, 0.2)  # Orange glow

	if mesh:
		var mat = mesh.get_surface_override_material(0)
		if mat:
			mat.emission_enabled = true
			mat.emission = Color(1.0, 0.4, 0.1)
			mat.emission_energy = 0.3

func complete_baking() -> void:
	var result = BAKING_RECIPES[current_item].result
	print("\n=== DING! ===")
	print("Baking complete! ", result, " is ready!")

	# Clear oven inventory (dough was consumed)
	InventoryManager.clear_inventory(get_inventory_id())

	# Add result to player inventory
	InventoryManager.add_item("player", result, 1)

	baking_complete.emit(result)

	# Reset state
	is_baking = false
	baking_timer = 0.0
	current_item = ""

	# Turn off visual feedback
	if light:
		light.visible = false

	if mesh:
		var mat = mesh.get_surface_override_material(0)
		if mat:
			mat.emission_enabled = false

func get_inventory_id() -> String:
	return "oven_" + name

func get_baking_progress() -> float:
	if not is_baking:
		return 0.0
	return baking_timer / baking_time
