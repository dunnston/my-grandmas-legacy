extends Node3D

# MixingBowl - First crafting station for combining ingredients

signal crafting_started(recipe_name: String)
signal crafting_complete(result_item: String)

@export var mixing_time: float = 60.0  # 60 seconds to mix
@export var equipment_tier: int = 0  # 0 = basic, upgradeable later

# Node references
@onready var interaction_area: Area3D = $InteractionArea
@onready var mesh: MeshInstance3D = $BowlMesh
@onready var progress_bar_container: Node3D = $ProgressBarContainer
@onready var progress_bar: ProgressBar = $ProgressBarContainer/SubViewport/ProgressBar

# State
var is_crafting: bool = false
var crafting_timer: float = 0.0
var current_recipe: Dictionary = {}
var current_recipe_id: String = ""
var player_nearby: Node3D = null

# UI compatibility aliases
var is_mixing: bool:
	get: return is_crafting
	set(value): is_crafting = value

var mixing_timer: float:
	get: return crafting_timer
	set(value): crafting_timer = value

var target_mix_time: float:
	get: return mixing_time

var has_finished_item: bool = false
var current_item: String = ""

# Note: Recipes are now loaded dynamically from RecipeManager
# This allows access to all 27 recipes instead of just 3!

# Helper: Convert recipe_id to dough/batter result
func _get_dough_result(recipe_id: String) -> String:
	# Map recipe IDs to their intermediate product (dough/batter)
	match recipe_id:
		"white_bread": return "white_bread_dough"
		"chocolate_chip_cookies": return "cookie_dough"
		"blueberry_muffins": return "muffin_batter"
		"croissants": return "croissant_dough"
		"danish_pastries": return "danish_dough"
		"scones": return "scone_dough"
		"cinnamon_rolls": return "cinnamon_roll_dough"
		"sourdough": return "sourdough_dough"
		"baguettes": return "baguette_dough"
		"focaccia": return "focaccia_dough"
		"rye_bread": return "rye_dough"
		"multigrain_loaf": return "multigrain_dough"
		"birthday_cake": return "birthday_cake_batter"
		"wedding_cupcakes": return "wedding_cupcake_batter"
		"cheesecake": return "cheesecake_batter"
		"layer_cake": return "layer_cake_batter"
		"grandmothers_apple_pie": return "apple_pie_dough"
		"secret_recipe_cookies": return "secret_cookie_dough"
		"family_chocolate_cake": return "family_chocolate_batter"
		"holiday_specialty_bread": return "holiday_bread_dough"
		"french_macarons": return "macaron_batter"
		"german_stollen": return "stollen_dough"
		"italian_biscotti": return "biscotti_dough"
		"japanese_melon_pan": return "melon_pan_dough"
		"grandmothers_legendary_cake": return "legendary_cake_batter"
		"championship_recipe": return "championship_dough"
		"town_festival_winner": return "festival_winner_dough"
		_: return recipe_id + "_dough"  # Fallback

func _ready() -> void:
	# Create inventory for this station
	InventoryManager.create_inventory(get_inventory_id())

	# Connect interaction area
	if interaction_area:
		interaction_area.body_entered.connect(_on_body_entered)
		interaction_area.body_exited.connect(_on_body_exited)

	# Hide progress bar initially
	if progress_bar_container:
		progress_bar_container.visible = false

	print("MixingBowl ready: ", name)

func _process(delta: float) -> void:
	if is_crafting and not GameManager.is_game_paused():
		crafting_timer += delta * GameManager.get_time_scale()

		# Update progress bar
		if progress_bar:
			var progress_percent = (crafting_timer / mixing_time) * 100.0
			progress_bar.value = progress_percent

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
	# Always open the visual UI
	open_mixing_bowl_ui(player)

func open_mixing_bowl_ui(player: Node3D) -> void:
	"""Open the visual UI for the mixing bowl"""
	var hud = get_tree().get_first_node_in_group("hud")
	if not hud:
		print("ERROR: Could not find HUD!")
		return
	var ui_manager = hud.get_equipment_ui_manager()
	if not ui_manager:
		print("ERROR: Could not find Equipment UI Manager!")
		return
	ui_manager.show_mixing_bowl_ui(get_inventory_id(), player.get_inventory_id(), self)

func open_crafting_ui(player: Node3D) -> void:
	print("\n=== MIXING BOWL ===")

	# Get all unlocked recipes from RecipeManager
	var unlocked_recipes: Array[Dictionary] = RecipeManager.get_all_unlocked_recipes()

	if unlocked_recipes.is_empty():
		print("No recipes unlocked yet!")
		return

	print("Available recipes (%d unlocked):" % unlocked_recipes.size())
	for recipe in unlocked_recipes:
		print("  - ", recipe["name"])

	print("\nYour inventory:")
	InventoryManager.print_inventory("player")
	print("\nChecking which recipes you can make...")

	# Get player's current inventory
	var player_inventory: Dictionary = InventoryManager.get_inventory("player")

	# Check each unlocked recipe to see if player has ingredients
	var craftable_recipe: Dictionary = {}
	var craftable_recipe_id: String = ""

	for recipe in unlocked_recipes:
		if RecipeManager.can_craft_recipe(recipe["id"], player_inventory):
			print("✓ Can make: ", recipe["name"])
			craftable_recipe = recipe
			craftable_recipe_id = recipe["id"]
			break  # Use first craftable recipe found
		else:
			print("✗ Missing ingredients for: ", recipe["name"])

	if not craftable_recipe.is_empty():
		print("\nStarting to mix ", craftable_recipe["name"], "...")
		transfer_ingredients_and_start("player", craftable_recipe, craftable_recipe_id)
	else:
		print("\nYou don't have ingredients for any recipe.")
		print("Go to the ingredient storage first!")

func transfer_ingredients_and_start(from_inventory: String, recipe: Dictionary, recipe_id: String = "") -> void:
	# Transfer ingredients from player to mixing bowl
	var station_inventory = get_inventory_id()
	var ingredients: Dictionary = recipe.get("ingredients", {})

	for ingredient in ingredients:
		var quantity: int = ingredients[ingredient]
		if not InventoryManager.transfer_item(from_inventory, station_inventory, ingredient, quantity):
			print("Error transferring ", ingredient)
			return

	start_crafting(recipe, recipe_id)

# Removed check_recipe_ingredients() - using RecipeManager.can_craft_recipe() instead

func start_crafting(recipe: Dictionary, recipe_id: String = "") -> void:
	current_recipe = recipe
	current_recipe_id = recipe_id
	is_crafting = true
	crafting_timer = 0.0
	mixing_time = recipe.get("mixing_time", 60.0)

	print("Started mixing ", recipe.get("name", "Unknown"), "! Wait ", mixing_time, " seconds...")
	crafting_started.emit(recipe.get("name", "Unknown"))

	# Show progress bar
	if progress_bar_container:
		progress_bar_container.visible = true
	if progress_bar:
		progress_bar.value = 0.0

	# Visual feedback (change color while mixing)
	if mesh and mesh.get_surface_override_material_count() > 0:
		var mat = mesh.get_surface_override_material(0)
		if mat:
			mat.albedo_color = Color(0.8, 0.6, 0.3)  # Mixing color

func complete_crafting() -> void:
	# Get the dough/batter result for this recipe
	var result: String = _get_dough_result(current_recipe_id)

	print("Mixing complete! ", result, " is ready!")
	print("(Quality will be determined when baked in the oven)")

	# Clear station ingredients (they were used)
	InventoryManager.clear_inventory(get_inventory_id())

	# Set finished item state (for UI)
	has_finished_item = true
	current_item = result

	# Add result to equipment inventory (not player - they need to collect it)
	InventoryManager.add_item(get_inventory_id(), result, 1)

	crafting_complete.emit(result)

	# Reset crafting state but keep finished item flag
	is_crafting = false
	crafting_timer = 0.0
	# Keep current_recipe and current_recipe_id for reference

	# Hide progress bar
	if progress_bar_container:
		progress_bar_container.visible = false

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

# ============================================================================
# AUTOMATION METHODS (for staff AI)
# ============================================================================

func auto_start_recipe(recipe_id: String, recipe_data: Dictionary, quality_mult: float = 1.0) -> bool:
	"""Start a recipe automatically (called by Baker AI)"""
	if is_crafting:
		return false

	current_recipe_id = recipe_id
	current_recipe = recipe_data
	is_crafting = true
	crafting_timer = 0.0
	mixing_time = recipe_data.get("mixing_time", 60.0)

	# Apply quality multiplier to the result (stored for when crafting completes)
	if not current_recipe.has("quality_multiplier"):
		current_recipe["quality_multiplier"] = quality_mult

	# Show progress bar
	if progress_bar_container:
		progress_bar_container.visible = true
	if progress_bar:
		progress_bar.value = 0.0

	print("[MixingBowl] Auto-started recipe: ", recipe_data.name, " (quality: ", int(quality_mult * 100), "%)")
	crafting_started.emit(recipe_data.name)
	return true
