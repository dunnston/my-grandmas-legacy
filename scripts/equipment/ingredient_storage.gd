extends Node3D

# IngredientStorage - Starting point for gathering ingredients

signal ingredients_taken(player_id: String)

# Node references
@onready var interaction_area: Area3D = $InteractionArea

# State
var player_nearby: Node3D = null

# Starter ingredients (Phase 2: includes all ingredients for 3 starter recipes)
const STARTER_INGREDIENTS = {
	"flour": 10,
	"sugar": 10,
	"eggs": 10,
	"butter": 10,
	"milk": 10,
	"yeast": 10,
	"salt": 10,
	"chocolate_chips": 10,
	"blueberries": 10
}

func _ready() -> void:
	# Create inventory for this station
	InventoryManager.create_inventory(get_inventory_id())

	# Stock with starter ingredients
	for ingredient in STARTER_INGREDIENTS:
		InventoryManager.add_item(get_inventory_id(), ingredient, STARTER_INGREDIENTS[ingredient])

	# Connect interaction area
	if interaction_area:
		interaction_area.body_entered.connect(_on_body_entered)
		interaction_area.body_exited.connect(_on_body_exited)

	print("IngredientStorage ready: ", name)
	print("Stocked with starter ingredients")

# Interaction system
func _on_body_entered(body: Node3D) -> void:
	if body.has_method("get_inventory_id"):
		player_nearby = body
		print("[E] to get Ingredients")

func _on_body_exited(body: Node3D) -> void:
	if body == player_nearby:
		player_nearby = null

func get_interaction_prompt() -> String:
	return "[E] Get Ingredients"

func interact(player: Node3D) -> void:
	open_storage_ui(player)

func open_storage_ui(player: Node3D) -> void:
	print("\n=== INGREDIENT STORAGE ===")
	print("Available ingredients:")
	InventoryManager.print_inventory(get_inventory_id())
	print("\nYour inventory:")
	InventoryManager.print_inventory("player")

	print("\nTaking a batch of ingredients...")
	take_ingredient_batch(player)

func take_ingredient_batch(player: Node3D) -> void:
	# Take a batch of ingredients (enough for multiple recipes)
	var batch = {
		"flour": 5,
		"sugar": 3,
		"eggs": 3,
		"butter": 3,
		"milk": 2,
		"yeast": 2,
		"salt": 2,
		"chocolate_chips": 4,
		"blueberries": 4
	}

	print("\nTaking ingredients:")
	for ingredient in batch:
		var quantity = batch[ingredient]
		if InventoryManager.transfer_item(get_inventory_id(), "player", ingredient, quantity):
			print("  Took ", quantity, "x ", ingredient)
		else:
			print("  Error: Could not take ", ingredient)

	print("\nDone! Check your inventory:")
	InventoryManager.print_inventory("player")
	print("\nNow go to the Mixing Bowl to craft!")

	ingredients_taken.emit("player")

	# Restock for testing (unlimited ingredients in Phase 2 baking phase)
	restock()

func restock() -> void:
	# Keep storage fully stocked for testing
	for ingredient in STARTER_INGREDIENTS:
		var current = InventoryManager.get_item_quantity(get_inventory_id(), ingredient)
		if current < STARTER_INGREDIENTS[ingredient]:
			var needed = STARTER_INGREDIENTS[ingredient] - current
			InventoryManager.add_item(get_inventory_id(), ingredient, needed)

func get_inventory_id() -> String:
	return "ingredient_storage_" + name
