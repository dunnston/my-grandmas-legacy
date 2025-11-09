extends Node3D

# Oven - Bakes dough into finished products

signal baking_started(item_name: String)
signal baking_complete(result_item: String, quality_data: Dictionary)
signal item_burned

@export var baking_time: float = 300.0  # 5 minutes game time
@export var equipment_tier: int = 0  # 0 = basic, upgradeable later
@export var max_slots: int = 4  # Basic oven supports 4 simultaneous baking slots

# Node references
@onready var interaction_area: Area3D = $InteractionArea
@onready var mesh: CSGBox3D = $OvenMesh
@onready var light: OmniLight3D = $OvenLight

# Multi-slot baking state
# Each slot is a Dictionary with: {item_id, recipe_id, timer, target_time, started_at}
var baking_slots: Array[Dictionary] = []
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
	if baking_slots.is_empty() or not GameManager or GameManager.is_game_paused():
		return

	var time_scale = GameManager.get_time_scale() if GameManager else 1.0

	# Update all baking slots
	for i in range(baking_slots.size() - 1, -1, -1):  # Iterate backwards for safe removal
		var slot = baking_slots[i]
		slot.timer += delta * time_scale

		# Check if this slot is done
		if slot.timer >= slot.target_time:
			complete_baking_slot(i)

	# Update light intensity based on how many items are baking
	if light:
		if baking_slots.size() > 0:
			light.visible = true
			# Average progress of all slots
			var total_progress = 0.0
			for slot in baking_slots:
				total_progress += slot.timer / slot.target_time
			var avg_progress = total_progress / baking_slots.size()
			light.light_energy = 0.5 + avg_progress * 1.5
		else:
			light.visible = false

# Interaction system
func _on_body_entered(body: Node3D) -> void:
	if body.has_method("get_inventory_id"):
		player_nearby = body
		if baking_slots.size() > 0:
			print("[E] to check Oven (%d/%d slots)" % [baking_slots.size(), max_slots])
		else:
			print("[E] to use Oven")

func _on_body_exited(body: Node3D) -> void:
	if body == player_nearby:
		player_nearby = null

func get_interaction_prompt() -> String:
	if baking_slots.size() > 0:
		return "[E] Check Oven (%d/%d)" % [baking_slots.size(), max_slots]
	return "[E] Use Oven"

func interact(player: Node3D) -> void:
	# Always open the visual UI (it shows baking progress or allows loading new items)
	open_visual_oven_ui(player)

func open_visual_oven_ui(player: Node3D) -> void:
	"""Open the visual UI for the oven"""
	var hud = get_tree().get_first_node_in_group("hud")
	if not hud:
		print("ERROR: Could not find HUD!")
		return
	var ui_manager = hud.get_equipment_ui_manager()
	if not ui_manager:
		print("ERROR: Could not find Equipment UI Manager!")
		return
	ui_manager.show_oven_ui(get_inventory_id(), player.get_inventory_id(), self)

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

func start_baking(item_id: String, quality_data: Dictionary = {}) -> bool:
	"""Start baking an item in a new slot. Returns true if successful."""
	# Check if oven is full
	if baking_slots.size() >= max_slots:
		print("Oven is full! (%d/%d slots)" % [baking_slots.size(), max_slots])
		return false

	var recipe_id = _get_recipe_from_dough(item_id)
	if recipe_id == "":
		print("Error: Unknown recipe for ", item_id)
		return false

	# Get baking time from RecipeManager
	if not RecipeManager:
		print("Error: RecipeManager not available")
		return false
	var recipe: Dictionary = RecipeManager.get_recipe(recipe_id)
	if recipe.is_empty():
		print("Error: Recipe not found in RecipeManager: ", recipe_id)
		return false

	# Create new baking slot
	var slot: Dictionary = {
		"item_id": item_id,
		"recipe_id": recipe_id,
		"timer": 0.0,
		"target_time": recipe.get("baking_time", 300.0),
		"started_at": Time.get_unix_time_from_system(),
		"input_quality": quality_data
	}

	baking_slots.append(slot)

	print("Started baking ", item_id, " (", recipe.get("name", ""), ") in slot ", baking_slots.size(), "/", max_slots)
	print("Target baking time: ", slot.target_time, " seconds")
	baking_started.emit(item_id)

	# Visual feedback
	if light:
		light.visible = true
		light.light_color = Color(1.0, 0.6, 0.2)  # Orange glow

	if mesh:
		# CSGBox3D uses .material property, not surface override
		var mat = mesh.material
		if not mat:
			# Create material if it doesn't exist
			mat = StandardMaterial3D.new()
			mesh.material = mat
		if mat and mat is StandardMaterial3D:
			mat.emission_enabled = true
			mat.emission = Color(1.0, 0.4, 0.1)
			mat.emission_energy = 0.3

	return true

func complete_baking_slot(slot_index: int) -> void:
	"""Complete baking for a specific slot"""
	if slot_index < 0 or slot_index >= baking_slots.size():
		print("Error: Invalid slot index ", slot_index)
		return

	var slot = baking_slots[slot_index]
	var result = _get_baked_result(slot.item_id)
	print("\n=== DING! Slot %d/%d ====" % [slot_index + 1, max_slots])

	# Get combined equipment tier (mixer + oven)
	var combined_tier: int = equipment_tier  # Start with oven tier

	# Try to find the mixing bowl to add its tier bonus
	var mixing_bowl = get_node_or_null("../MixingBowl")
	if mixing_bowl and "equipment_tier" in mixing_bowl:
		var mixer_tier: int = mixing_bowl.equipment_tier
		combined_tier += mixer_tier
		if mixer_tier > 0:
			print("Equipment bonuses: Mixer (Tier %d) + Oven (Tier %d) = Total Tier %d" % [mixer_tier, equipment_tier, combined_tier])

	# Calculate quality based on timing and equipment
	var quality_data: Dictionary = {}
	if QualityManager:
		quality_data = QualityManager.calculate_quality(
			slot.recipe_id,
			slot.timer,          # actual time
			slot.target_time,    # target time
			combined_tier        # combined equipment quality bonus
		)
	else:
		# Fallback quality data if QualityManager not available
		quality_data = {
			"quality": 70.0,
			"tier": 1,
			"tier_name": "NORMAL",
			"is_legendary": false,
			"price_multiplier": 1.0
		}

	print("Baking complete! ", result, " is ready!")
	print("Quality: %.1f%% (%s)%s" % [
		quality_data.get("quality", 70.0),
		quality_data.get("tier_name", "NORMAL"),
		" ✨ LEGENDARY!" if quality_data.get("is_legendary", false) else ""
	])

	# Remove the dough/batter from oven inventory
	InventoryManager.remove_item(get_inventory_id(), slot.item_id, 1)

	# Add finished product to oven inventory WITH quality metadata
	var metadata: Dictionary = {
		"quality_data": quality_data,
		"baked_time": Time.get_unix_time_from_system(),
		"recipe_id": slot.recipe_id
	}

	InventoryManager.add_item(get_inventory_id(), result, 1, metadata)

	print("✓ Quality data saved with item!")

	# Track recipe mastery for achievements
	if AchievementManager:
		AchievementManager.track_recipe_mastery(slot.recipe_id, quality_data.get("tier_name", ""))

	baking_complete.emit(result, quality_data)

	# Remove this slot from baking_slots
	baking_slots.remove_at(slot_index)

	# Turn off visual feedback if no more items baking
	if baking_slots.is_empty():
		if light:
			light.visible = false

		if mesh:
			# CSGBox3D uses .material property, not surface override
			var mat = mesh.material
			if mat and mat is StandardMaterial3D:
				mat.emission_enabled = false

func get_inventory_id() -> String:
	return "oven_" + name

func get_baking_progress() -> float:
	"""Get average baking progress across all slots"""
	if baking_slots.is_empty():
		return 0.0
	var total_progress = 0.0
	for slot in baking_slots:
		total_progress += slot.timer / slot.target_time
	return total_progress / baking_slots.size()

func get_slot_count() -> int:
	"""Get number of active baking slots"""
	return baking_slots.size()

func get_max_slots() -> int:
	"""Get maximum number of baking slots"""
	return max_slots

func is_slot_available() -> bool:
	"""Check if there's room for another item"""
	return baking_slots.size() < max_slots

func get_slot_info(item_id: String) -> Dictionary:
	"""Get baking info for a specific item by ID"""
	for slot in baking_slots:
		if slot.item_id == item_id:
			return {
				"timer": slot.timer,
				"target_time": slot.target_time,
				"progress": slot.timer / slot.target_time,
				"is_done": slot.timer >= slot.target_time
			}
	return {
		"timer": 0.0,
		"target_time": 0.0,
		"progress": 0.0,
		"is_done": false
	}

# ============================================================================
# AUTOMATION METHODS (for staff AI)
# ============================================================================

func auto_load_item(item_id: String) -> bool:
	"""Load dough/batter into oven automatically (called by Baker AI)"""
	if not is_slot_available():
		return false

	# Add item to oven inventory
	InventoryManager.add_item(get_inventory_id(), item_id, 1)

	# Start baking in a new slot
	if start_baking(item_id):
		print("[Oven] Auto-loaded ", item_id, " in slot ", baking_slots.size(), "/", max_slots)
		return true

	return false

func auto_collect_baked_goods() -> bool:
	"""Collect finished baked goods automatically (called by Baker AI)"""
	# Check if there are any finished items in the oven inventory
	var inventory = InventoryManager.get_inventory(get_inventory_id())
	for item_id in inventory:
		# Finished items are those that don't end with _dough or _batter
		if not (item_id.ends_with("_dough") or item_id.ends_with("_batter")):
			# Found a finished item - transfer to display case or player
			print("[Oven] Auto-collected ", item_id)
			return true

	return false

func has_finished_items() -> bool:
	"""Check if there are any finished baked goods ready to collect"""
	var inventory = InventoryManager.get_inventory(get_inventory_id())
	for item_id in inventory:
		if not (item_id.ends_with("_dough") or item_id.ends_with("_batter")):
			return true
	return false
