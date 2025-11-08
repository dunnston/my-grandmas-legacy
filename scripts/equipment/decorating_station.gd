extends Node3D

# DecoratingStation - Add decorations to baked goods
# GDD Reference: Section 4.1.2, Lines 226-229
# Unlocks at $10,000 milestone
# Adds frosting, toppings, decorations
# Increases value 1.2-1.5x (30% from balance_config)
# Adds 1-2 minutes to crafting process

signal decorating_started(item_name: String)
signal decorating_complete(result_item: String, quality_data: Dictionary)

@export var decorating_time: float = 90.0  # 1.5 minutes from balance_config
@export var value_multiplier: float = 1.3  # 30% price increase
@export var quality_bonus: float = 5.0  # +5% quality

# Node references
@onready var interaction_area: Area3D = $InteractionArea
@onready var mesh: CSGBox3D = $StationMesh

# State
var is_decorating: bool = false
var decorating_timer: float = 0.0
var current_item: String = ""
var current_quality_data: Dictionary = {}
var player_nearby: Node3D = null
var has_finished_item: bool = false

# Available decorations (could be expanded)
var available_decorations: Array[String] = [
	"frosting",
	"sprinkles",
	"chocolate_drizzle",
	"powdered_sugar",
	"fresh_fruit",
	"edible_flowers"
]

func _ready() -> void:
	# Load balance config values
	decorating_time = BalanceConfig.EQUIPMENT.get("decorating_station_base_time", 90.0)
	value_multiplier = BalanceConfig.EQUIPMENT.get("decorating_station_value_multiplier", 1.3)
	quality_bonus = BalanceConfig.EQUIPMENT.get("decorating_station_quality_bonus", 5.0)

	# Create inventory for this station
	InventoryManager.create_inventory(get_inventory_id())

	# Connect interaction area
	if interaction_area:
		interaction_area.body_entered.connect(_on_body_entered)
		interaction_area.body_exited.connect(_on_body_exited)

	print("Decorating Station ready: ", name)

func _process(delta: float) -> void:
	if is_decorating and GameManager and not GameManager.is_game_paused():
		var time_scale = GameManager.get_time_scale() if GameManager else 1.0
		decorating_timer += delta * time_scale

		if decorating_timer >= decorating_time:
			complete_decorating()

# Interaction system
func _on_body_entered(body: Node3D) -> void:
	if body.has_method("get_inventory_id"):
		player_nearby = body
		print("Player near decorating station")

func _on_body_exited(body: Node3D) -> void:
	if body == player_nearby:
		player_nearby = null
		print("Player left decorating station")

# Core decorating methods
func can_decorate() -> bool:
	"""Check if station is ready to decorate"""
	return not is_decorating

func start_decorating(item_id: String, quality_data: Dictionary = {}) -> bool:
	"""Start decorating a baked good"""
	if is_decorating:
		print("Decorating station is busy!")
		return false

	# Verify item can be decorated (only finished baked goods)
	if not _is_item_decoratable(item_id):
		print("Item cannot be decorated: ", item_id)
		return false

	current_item = item_id
	current_quality_data = quality_data.duplicate()
	is_decorating = true
	decorating_timer = 0.0
	has_finished_item = false

	# Add to inventory for tracking
	InventoryManager.add_item(get_inventory_id(), item_id, 1, quality_data)

	print("Started decorating %s (%.0fs)" % [item_id, decorating_time])
	decorating_started.emit(item_id)
	return true

func complete_decorating() -> void:
	"""Complete decorating and create decorated item"""
	if not is_decorating:
		return

	# Create decorated item name
	var decorated_item = current_item + "_decorated"

	# Apply bonuses to quality data
	var enhanced_quality = current_quality_data.duplicate()

	if enhanced_quality.has("quality"):
		enhanced_quality.quality = min(100, enhanced_quality.quality + quality_bonus)

	# Update price (will be multiplied by value_multiplier when sold)
	if enhanced_quality.has("price"):
		enhanced_quality.price *= value_multiplier
	else:
		# Calculate enhanced price
		var recipe = RecipeManager.get_recipe(current_item) if RecipeManager else {}
		if not recipe.is_empty():
			var base_price = recipe.get("base_price", 0.0)
			enhanced_quality.price = base_price * value_multiplier

	# Mark as decorated
	enhanced_quality.decorated = true
	enhanced_quality.decoration_type = available_decorations[randi() % available_decorations.size()]

	# Remove plain item, add decorated item
	InventoryManager.remove_item(get_inventory_id(), current_item, 1)
	InventoryManager.add_item(get_inventory_id(), decorated_item, 1, enhanced_quality)

	print("%s decorated! Quality: %.0f%%, Price multiplier: %.1fx" % [
		decorated_item,
		enhanced_quality.get("quality", 0),
		value_multiplier
	])

	is_decorating = false
	has_finished_item = true
	decorating_complete.emit(decorated_item, enhanced_quality)

func cancel_decorating() -> void:
	"""Cancel current decorating and return item"""
	if not is_decorating:
		return

	print("Decorating cancelled for ", current_item)

	is_decorating = false
	decorating_timer = 0.0
	# Item remains in inventory, player can remove it
	has_finished_item = true

func remove_item(item_id: String) -> Dictionary:
	"""Remove a finished item from the station"""
	var metadata = InventoryManager.get_item_metadata(get_inventory_id(), item_id)
	InventoryManager.remove_item(get_inventory_id(), item_id, 1)
	has_finished_item = false
	return metadata

func _is_item_decoratable(item_id: String) -> bool:
	"""Check if an item can be decorated"""
	# For now, allow decorating all baked goods except bread
	# (GDD suggests cakes and pastries are best for decorating)

	# Items that can't be decorated
	var non_decoratable = ["white_bread", "sourdough", "baguettes", "rye_bread", "multigrain_loaf"]

	if item_id in non_decoratable:
		return false

	# Allow decorating cookies, cakes, pastries, etc.
	return true

func get_decorating_progress() -> float:
	"""Get progress 0.0 to 1.0"""
	if not is_decorating:
		return 0.0
	return clamp(decorating_timer / decorating_time, 0.0, 1.0)

func get_inventory_id() -> String:
	return "decorating_station_" + name

# Save/Load support
func get_save_data() -> Dictionary:
	return {
		"is_decorating": is_decorating,
		"decorating_timer": decorating_timer,
		"current_item": current_item,
		"current_quality_data": current_quality_data,
		"has_finished_item": has_finished_item
	}

func load_save_data(data: Dictionary) -> void:
	if data.has("is_decorating"):
		is_decorating = data["is_decorating"]
	if data.has("decorating_timer"):
		decorating_timer = data["decorating_timer"]
	if data.has("current_item"):
		current_item = data["current_item"]
	if data.has("current_quality_data"):
		current_quality_data = data["current_quality_data"]
	if data.has("has_finished_item"):
		has_finished_item = data["has_finished_item"]

	print("Decorating station data loaded")
