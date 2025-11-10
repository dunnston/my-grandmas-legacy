extends Node3D

# Oven - Bakes dough into finished products

signal baking_started(item_name: String)
signal baking_complete(result_item: String, quality_data: Dictionary)
signal item_burned
signal cooking_state_changed(slot_index: int, new_state: int)

@export var baking_time: float = 300.0  # 5 minutes game time
@export var equipment_tier: int = 0  # 0 = basic, upgradeable later
@export var max_slots: int = 4  # Basic oven supports 4 simultaneous baking slots

# Cooking states
enum CookingState {
	UNDERCOOKED,  # Too early to remove
	COOKED,       # Safe to remove, good quality
	OPTIMAL,      # Perfect timing window, best quality
	WARNING,      # About to burn, still good quality
	BURNT         # Overcooked, poor quality
}

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

# Helper: Get cooking state for a slot
func get_cooking_state(slot: Dictionary) -> CookingState:
	"""Determine the current cooking state based on timer progress"""
	if slot.target_time <= 0:
		return CookingState.COOKED

	var progress = slot.timer / slot.target_time

	# Load thresholds from BalanceConfig
	var undercooked_end = BalanceConfig.EQUIPMENT.oven_undercooked_end
	var cooked_start = BalanceConfig.EQUIPMENT.oven_cooked_start
	var optimal_start = BalanceConfig.EQUIPMENT.oven_cooked_optimal_start
	var optimal_end = BalanceConfig.EQUIPMENT.oven_cooked_optimal_end
	var warning_time = BalanceConfig.EQUIPMENT.oven_warning_time
	var burnt_start = BalanceConfig.EQUIPMENT.oven_burnt_start

	if progress < undercooked_end:
		return CookingState.UNDERCOOKED
	elif progress >= burnt_start:
		return CookingState.BURNT
	elif progress >= warning_time:
		return CookingState.WARNING
	elif progress >= optimal_start and progress <= optimal_end:
		return CookingState.OPTIMAL
	else:
		return CookingState.COOKED

func get_cooking_state_name(state: CookingState) -> String:
	"""Get display name for cooking state"""
	match state:
		CookingState.UNDERCOOKED:
			return "Undercooked"
		CookingState.COOKED:
			return "Cooked"
		CookingState.OPTIMAL:
			return "PERFECT!"
		CookingState.WARNING:
			return "ALMOST BURNT!"
		CookingState.BURNT:
			return "Burnt"
		_:
			return "Unknown"

func get_cooking_state_color(state: CookingState) -> Color:
	"""Get color for cooking state display"""
	match state:
		CookingState.UNDERCOOKED:
			return Color(0.5, 0.5, 0.8)  # Blue
		CookingState.COOKED:
			return Color(0.3, 1.0, 0.3)  # Green
		CookingState.OPTIMAL:
			return Color(1.0, 0.9, 0.2)  # Gold
		CookingState.WARNING:
			return Color(1.0, 0.5, 0.0)  # Orange
		CookingState.BURNT:
			return Color(0.8, 0.2, 0.2)  # Red
		_:
			return Color.WHITE

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
	for i in range(baking_slots.size()):
		var slot = baking_slots[i]
		slot.timer += delta * time_scale

		# Track cooking state changes
		var current_state = get_cooking_state(slot)
		var previous_state = slot.get("last_cooking_state", CookingState.UNDERCOOKED)

		if current_state != previous_state:
			slot.last_cooking_state = current_state
			cooking_state_changed.emit(i, current_state)

			# Print state change for debugging
			var state_name = get_cooking_state_name(current_state)
			print("Slot %d: %s -> %s" % [i + 1, get_cooking_state_name(previous_state), state_name])

	# Update light color based on cooking states
	if light and baking_slots.size() > 0:
		light.visible = true

		# Find the "worst" cooking state (most urgent)
		var worst_state = CookingState.UNDERCOOKED
		for slot in baking_slots:
			var state = get_cooking_state(slot)
			# Priority: BURNT > WARNING > OPTIMAL > COOKED > UNDERCOOKED
			if state == CookingState.BURNT:
				worst_state = CookingState.BURNT
				break
			elif state == CookingState.WARNING and worst_state != CookingState.BURNT:
				worst_state = CookingState.WARNING
			elif state == CookingState.OPTIMAL and worst_state not in [CookingState.BURNT, CookingState.WARNING]:
				worst_state = CookingState.OPTIMAL
			elif state == CookingState.COOKED and worst_state not in [CookingState.BURNT, CookingState.WARNING, CookingState.OPTIMAL]:
				worst_state = CookingState.COOKED

		# Set light color based on worst state
		light.light_color = get_cooking_state_color(worst_state)

		# Set light intensity based on average progress
		var total_progress = 0.0
		for slot in baking_slots:
			total_progress += slot.timer / slot.target_time
		var avg_progress = total_progress / baking_slots.size()
		light.light_energy = 0.5 + avg_progress * 1.5
	elif light:
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
		"input_quality": quality_data,
		"last_cooking_state": CookingState.UNDERCOOKED
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
	var cooking_state = get_cooking_state(slot)
	var state_name = get_cooking_state_name(cooking_state)
	var result = _get_baked_result(slot.item_id)

	print("\n=== Collecting from Slot %d/%d ====" % [slot_index + 1, max_slots])
	print("Cooking state: %s" % state_name)

	# Check if player is trying to collect undercooked item
	if cooking_state == CookingState.UNDERCOOKED:
		print("⚠ WARNING: This item is still undercooked!")
		print("⚠ Quality will be significantly reduced!")

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

	# Apply cooking state modifiers to quality
	var base_quality = quality_data.get("quality", 70.0)
	var modified_quality = base_quality

	match cooking_state:
		CookingState.UNDERCOOKED:
			# Cap quality at undercooked max
			var max_quality = BalanceConfig.EQUIPMENT.oven_undercooked_quality_max
			modified_quality = min(base_quality, max_quality)
			print("⚠ Undercooked penalty: Quality capped at %d%%" % max_quality)

		CookingState.OPTIMAL:
			# Bonus quality and legendary chance in optimal window
			var bonus = BalanceConfig.EQUIPMENT.oven_cooked_quality_bonus
			modified_quality = min(base_quality + bonus, 100.0)
			print("✨ Optimal timing bonus: +%d%% quality!" % bonus)

			# Increase legendary chance if perfect quality
			if quality_data.get("tier") == QualityManager.QualityTier.PERFECT:
				var extra_legendary_chance = BalanceConfig.EQUIPMENT.oven_perfection_chance_bonus
				if randf() < extra_legendary_chance:
					quality_data.is_legendary = true
					print("✨✨ LEGENDARY ITEM CREATED! ✨✨")

		CookingState.BURNT:
			# Cap quality at burnt max
			var max_quality = BalanceConfig.EQUIPMENT.oven_burnt_quality_max
			modified_quality = min(base_quality, max_quality)
			print("🔥 BURNT! Quality capped at %d%%" % max_quality)
			item_burned.emit()

		CookingState.WARNING:
			print("⚠ Close call! Item was almost burnt.")

	# Update quality data with modified values
	quality_data.quality = modified_quality
	quality_data.tier = QualityManager.get_quality_tier(modified_quality)
	quality_data.tier_name = QualityManager.QualityTier.keys()[quality_data.tier]
	quality_data.price_multiplier = QualityManager.QUALITY_PRICE_MULTIPLIERS[quality_data.tier]

	print("Baking complete! ", result, " collected!")
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
			var cooking_state = get_cooking_state(slot)
			return {
				"timer": slot.timer,
				"target_time": slot.target_time,
				"progress": slot.timer / slot.target_time,
				"is_done": slot.timer >= slot.target_time,
				"cooking_state": cooking_state,
				"cooking_state_name": get_cooking_state_name(cooking_state),
				"cooking_state_color": get_cooking_state_color(cooking_state)
			}
	return {
		"timer": 0.0,
		"target_time": 0.0,
		"progress": 0.0,
		"is_done": false,
		"cooking_state": CookingState.UNDERCOOKED,
		"cooking_state_name": "Unknown",
		"cooking_state_color": Color.WHITE
	}

func get_slot_info_by_index(slot_index: int) -> Dictionary:
	"""Get baking info for a specific slot by index"""
	if slot_index < 0 or slot_index >= baking_slots.size():
		return {
			"timer": 0.0,
			"target_time": 0.0,
			"progress": 0.0,
			"is_done": false,
			"cooking_state": CookingState.UNDERCOOKED,
			"cooking_state_name": "Unknown",
			"cooking_state_color": Color.WHITE
		}

	var slot = baking_slots[slot_index]
	var cooking_state = get_cooking_state(slot)
	return {
		"timer": slot.timer,
		"target_time": slot.target_time,
		"progress": slot.timer / slot.target_time,
		"is_done": slot.timer >= slot.target_time,
		"cooking_state": cooking_state,
		"cooking_state_name": get_cooking_state_name(cooking_state),
		"cooking_state_color": get_cooking_state_color(cooking_state),
		"item_id": slot.item_id,
		"recipe_id": slot.recipe_id
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
