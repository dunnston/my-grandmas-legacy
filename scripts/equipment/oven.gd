extends Node3D

# Oven - Bakes dough into finished products

signal baking_started(item_name: String)
signal baking_complete(result_item: String, quality_data: Dictionary)
signal item_burned

@export var baking_time: float = 300.0  # 5 minutes game time
@export var equipment_tier: int = 0  # 0 = basic, upgradeable later

# Node references
@onready var interaction_area: Area3D = $InteractionArea
@onready var mesh: CSGBox3D = $OvenMesh
@onready var light: OmniLight3D = $OvenLight

# State
var is_baking: bool = false
var baking_timer: float = 0.0
var target_bake_time: float = 0.0
var current_item: String = ""
var current_recipe_id: String = ""
var player_nearby: Node3D = null

# Note: Baking recipes are now loaded dynamically from RecipeManager
# This supports all 27 recipes instead of just 3!

# Helper: Convert dough/batter name back to recipe_id
func _get_recipe_from_dough(dough_id: String) -> String:
	# Map intermediate products back to recipe IDs
	var dough_to_recipe = {
		"white_bread_dough": "white_bread",
		"cookie_dough": "chocolate_chip_cookies",
		"muffin_batter": "blueberry_muffins",
		"croissant_dough": "croissants",
		"danish_dough": "danish_pastries",
		"scone_dough": "scones",
		"cinnamon_roll_dough": "cinnamon_rolls",
		"sourdough_dough": "sourdough",
		"baguette_dough": "baguettes",
		"focaccia_dough": "focaccia",
		"rye_dough": "rye_bread",
		"multigrain_dough": "multigrain_loaf",
		"birthday_cake_batter": "birthday_cake",
		"wedding_cupcake_batter": "wedding_cupcakes",
		"cheesecake_batter": "cheesecake",
		"layer_cake_batter": "layer_cake",
		"apple_pie_dough": "grandmothers_apple_pie",
		"secret_cookie_dough": "secret_recipe_cookies",
		"family_chocolate_batter": "family_chocolate_cake",
		"holiday_bread_dough": "holiday_specialty_bread",
		"macaron_batter": "french_macarons",
		"stollen_dough": "german_stollen",
		"biscotti_dough": "italian_biscotti",
		"melon_pan_dough": "japanese_melon_pan",
		"legendary_cake_batter": "grandmothers_legendary_cake",
		"championship_dough": "championship_recipe",
		"festival_winner_dough": "town_festival_winner"
	}

	return dough_to_recipe.get(dough_id, "")

# Helper: Get baked result from dough
func _get_baked_result(dough_id: String) -> String:
	var recipe_id = _get_recipe_from_dough(dough_id)
	return recipe_id if recipe_id != "" else dough_id.replace("_dough", "").replace("_batter", "")

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
	print("Load dough/batter to start baking")
	print("\nYour inventory:")
	InventoryManager.print_inventory("player")

	# Check if player has bakeable items (items ending in _dough or _batter)
	var player_inventory = InventoryManager.get_inventory("player")
	var can_bake: bool = false

	for item_id in player_inventory.keys():
		# Check if this is a dough or batter
		if item_id.ends_with("_dough") or item_id.ends_with("_batter"):
			var recipe_id = _get_recipe_from_dough(item_id)
			var result = _get_baked_result(item_id)

			if recipe_id != "":
				print("\nYou can bake: ", item_id, " -> ", result)
				print("Loading ", item_id, " into oven...")
				load_and_bake(player, item_id)
				can_bake = true
				break

	if not can_bake:
		print("You don't have any dough or batter to bake!")
		print("Try making some at the mixing bowl first.")

func load_and_bake(player: Node3D, item_id: String) -> void:
	var recipe_id = _get_recipe_from_dough(item_id)

	if recipe_id == "":
		print("Error: ", item_id, " cannot be baked (unknown recipe)")
		return

	# Transfer item from player to oven
	if InventoryManager.transfer_item("player", get_inventory_id(), item_id, 1):
		start_baking(item_id)
	else:
		print("Error: Could not load ", item_id, " into oven")

func start_baking(item_id: String) -> void:
	var recipe_id = _get_recipe_from_dough(item_id)

	if recipe_id == "":
		print("Error: Unknown recipe for ", item_id)
		return

	# Get baking time from RecipeManager
	var recipe: Dictionary = RecipeManager.get_recipe(recipe_id)
	if recipe.is_empty():
		print("Error: Recipe not found in RecipeManager: ", recipe_id)
		return

	current_item = item_id
	current_recipe_id = recipe_id
	is_baking = true
	baking_timer = 0.0
	target_bake_time = recipe.get("baking_time", 300.0)
	baking_time = target_bake_time

	print("Started baking ", current_item, " (", recipe.get("name", ""), ")!")
	print("Target baking time: ", target_bake_time, " seconds")
	baking_started.emit(item_id)

	# Visual feedback
	if light:
		light.visible = true
		light.light_color = Color(1.0, 0.6, 0.2)  # Orange glow

	if mesh:
		# Safely set material emission
		var mat = mesh.get_surface_override_material(0)
		if not mat:
			# Create material if it doesn't exist
			mat = StandardMaterial3D.new()
			mesh.set_surface_override_material(0, mat)
		if mat and mat is StandardMaterial3D:
			mat.emission_enabled = true
			mat.emission = Color(1.0, 0.4, 0.1)
			mat.emission_energy = 0.3

func complete_baking() -> void:
	var result = _get_baked_result(current_item)
	print("\n=== DING! ===")

	# Get combined equipment tier (mixer + oven)
	var combined_tier: int = equipment_tier  # Start with oven tier

	# Try to find the mixing bowl to add its tier bonus
	var mixing_bowl = get_node_or_null("../MixingBowl")
	if mixing_bowl and mixing_bowl.has_method("get"):
		var mixer_tier: int = mixing_bowl.get("equipment_tier") if "equipment_tier" in mixing_bowl else 0
		combined_tier += mixer_tier
		if mixer_tier > 0:
			print("Equipment bonuses: Mixer (Tier %d) + Oven (Tier %d) = Total Tier %d" % [mixer_tier, equipment_tier, combined_tier])

	# Calculate quality based on timing and equipment
	var quality_data: Dictionary = QualityManager.calculate_quality(
		current_recipe_id,
		baking_timer,        # actual time
		target_bake_time,    # target time
		combined_tier        # combined equipment quality bonus
	)

	print("Baking complete! ", result, " is ready!")
	print("Quality: %.1f%% (%s)%s" % [
		quality_data.quality,
		quality_data.tier_name,
		" ✨ LEGENDARY!" if quality_data.is_legendary else ""
	])

	# Clear oven inventory (dough was consumed)
	InventoryManager.clear_inventory(get_inventory_id())

	# Add result to player inventory WITH quality metadata
	var metadata: Dictionary = {
		"quality_data": quality_data,
		"baked_time": Time.get_unix_time_from_system(),
		"recipe_id": current_recipe_id
	}

	InventoryManager.add_item("player", result, 1, metadata)

	print("✓ Quality data saved with item!")

	# Track recipe mastery for achievements
	AchievementManager.track_recipe_mastery(current_recipe_id, quality_data.get("tier_name", ""))

	baking_complete.emit(result, quality_data)

	# Reset state
	is_baking = false
	baking_timer = 0.0
	target_bake_time = 0.0
	current_item = ""
	current_recipe_id = ""

	# Turn off visual feedback
	if light:
		light.visible = false

	if mesh:
		# Safely disable material emission
		var mat = mesh.get_surface_override_material(0)
		if mat and mat is StandardMaterial3D:
			mat.emission_enabled = false

func get_inventory_id() -> String:
	return "oven_" + name

func get_baking_progress() -> float:
	if not is_baking:
		return 0.0
	return baking_timer / baking_time
