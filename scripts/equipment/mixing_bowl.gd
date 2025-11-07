extends Node3D

# MixingBowl - First crafting station for combining ingredients

signal crafting_started(recipe_name: String)
signal crafting_complete(result_item: String)

@export var mixing_time: float = 60.0  # 60 seconds to mix

# Node references
@onready var interaction_area: Area3D = $InteractionArea
@onready var mesh: MeshInstance3D = $BowlMesh

# State
var is_crafting: bool = false
var crafting_timer: float = 0.0
var current_recipe: Dictionary = {}
var player_nearby: Node3D = null

# Simple bread recipe (for Phase 1)
const BREAD_RECIPE = {
	"name": "bread_dough",
	"ingredients": {
		"flour": 2,
		"water": 1,
		"yeast": 1
	},
	"result": "bread_dough",
	"time": 60.0
}

func _ready() -> void:
	# Create inventory for this station
	InventoryManager.create_inventory(get_inventory_id())

	# Connect interaction area
	if interaction_area:
		interaction_area.body_entered.connect(_on_body_entered)
		interaction_area.body_exited.connect(_on_body_exited)

	print("MixingBowl ready: ", name)

func _process(delta: float) -> void:
	if is_crafting and not GameManager.is_game_paused():
		crafting_timer += delta * GameManager.get_time_scale()

		if crafting_timer >= mixing_time:
			complete_crafting()

# Interaction system
func _on_body_entered(body: Node3D) -> void:
	if body.has_method("get_inventory_id"):
		player_nearby = body
		print("[E] to use Mixing Bowl")

func _on_body_exited(body: Node3D) -> void:
	if body == player_nearby:
		player_nearby = null

func get_interaction_prompt() -> String:
	return "[E] Use Mixing Bowl"

func interact(player: Node3D) -> void:
	if is_crafting:
		print("Already mixing! Time remaining: ", mixing_time - crafting_timer, "s")
		return

	open_crafting_ui(player)

func open_crafting_ui(player: Node3D) -> void:
	print("\n=== MIXING BOWL ===")
	print("Recipe: Bread Dough")
	print("Required: 2x flour, 1x water, 1x yeast")
	print("\nYour inventory:")
	InventoryManager.print_inventory("player")
	print("\nTransfer ingredients? (This is placeholder - UI will be added)")
	print("For now, let's check if you have the ingredients...")

	# Check if player has ingredients
	if check_recipe_ingredients("player", BREAD_RECIPE):
		print("You have all ingredients! Starting to mix...")
		transfer_ingredients_and_start("player", BREAD_RECIPE)
	else:
		print("You don't have all the required ingredients.")
		print("Go to the ingredient storage first!")

func check_recipe_ingredients(inventory_id: String, recipe: Dictionary) -> bool:
	for ingredient in recipe.ingredients:
		var required: int = recipe.ingredients[ingredient]
		if not InventoryManager.has_item(inventory_id, ingredient, required):
			return false
	return true

func transfer_ingredients_and_start(from_inventory: String, recipe: Dictionary) -> void:
	# Transfer ingredients from player to mixing bowl
	var station_inventory = get_inventory_id()

	for ingredient in recipe.ingredients:
		var quantity: int = recipe.ingredients[ingredient]
		if not InventoryManager.transfer_item(from_inventory, station_inventory, ingredient, quantity):
			print("Error transferring ", ingredient)
			return

	start_crafting(recipe)

func start_crafting(recipe: Dictionary) -> void:
	current_recipe = recipe
	is_crafting = true
	crafting_timer = 0.0
	mixing_time = recipe.time

	print("Started mixing ", recipe.name, "! Wait ", mixing_time, " seconds...")
	crafting_started.emit(recipe.name)

	# Visual feedback (change color while mixing)
	if mesh and mesh.get_surface_override_material_count() > 0:
		var mat = mesh.get_surface_override_material(0)
		if mat:
			mat.albedo_color = Color(0.8, 0.6, 0.3)  # Mixing color

func complete_crafting() -> void:
	print("Mixing complete! ", current_recipe.result, " is ready!")

	# Clear station ingredients (they were used)
	InventoryManager.clear_inventory(get_inventory_id())

	# Add result to player inventory
	InventoryManager.add_item("player", current_recipe.result, 1)

	crafting_complete.emit(current_recipe.result)

	# Reset state
	is_crafting = false
	crafting_timer = 0.0
	current_recipe = {}

	# Visual feedback (reset color)
	if mesh and mesh.get_surface_override_material_count() > 0:
		var mat = mesh.get_surface_override_material(0)
		if mat:
			mat.albedo_color = Color(0.9, 0.9, 0.9)  # Default color

func get_inventory_id() -> String:
	return "mixing_bowl_" + name

func get_crafting_progress() -> float:
	if not is_crafting:
		return 0.0
	return crafting_timer / mixing_time
