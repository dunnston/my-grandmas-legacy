extends Node3D

# BagStation - Shopping bag at counter for bagging customer items
# Player stands nearby and presses B to transfer items from holding inventory to bag

signal items_bagged()

# Node references
@onready var interaction_area: Area3D = $InteractionArea

# State
var player_nearby: Node3D = null
var is_checkout_active: bool = false
var bag_ui: Control = null
var interaction_indicator: Node3D = null

func _ready() -> void:
	# Add to group so player can find us
	add_to_group("bag_station")

	# Create bag inventory
	InventoryManager.create_inventory("shopping_bag")

	# Connect interaction area
	if interaction_area:
		interaction_area.body_entered.connect(_on_body_entered)
		interaction_area.body_exited.connect(_on_body_exited)

	# Create interaction indicator
	_create_interaction_indicator()

	# Create bag UI
	_create_bag_ui()

	print("BagStation ready: ", name)

func _process(_delta: float) -> void:
	# Update prompt visibility when player is nearby
	if player_nearby:
		_update_bag_prompt()

func _on_body_entered(body: Node3D) -> void:
	print("BagStation: Body entered area: ", body.name)
	if body.has_method("get_inventory_id"):
		player_nearby = body
		print("BagStation: Player entered bag area!")
		if is_checkout_active:
			print("[E] to bag items")
		_update_bag_prompt()
	else:
		print("BagStation: Body doesn't have get_inventory_id method")

func _on_body_exited(body: Node3D) -> void:
	print("BagStation: Body exited area: ", body.name)
	if body == player_nearby:
		player_nearby = null
		print("BagStation: Player left bag area!")
		_hide_bag_prompt()

func _update_bag_prompt() -> void:
	"""Show/hide the bag prompt based on player position and inventory"""
	if not player_nearby:
		_hide_bag_prompt()
		return

	# Only show if player has items to bag
	var carry_inventory = InventoryManager.get_inventory("player_carry")
	print("BagStation: Updating prompt - carry inventory has %d items" % carry_inventory.size())

	if carry_inventory.is_empty():
		print("BagStation: No items to bag, hiding prompt")
		_hide_bag_prompt()
		return

	# Show the prompt
	print("BagStation: Showing bag prompt!")
	_show_bag_prompt()

func _show_bag_prompt() -> void:
	"""Display the bag prompt on HUD"""
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_bag_prompt"):
		print("BagStation: Calling HUD.show_bag_prompt()")
		hud.show_bag_prompt()
	else:
		print("BagStation: HUD not found or missing show_bag_prompt method!")

func _hide_bag_prompt() -> void:
	"""Hide the bag prompt from HUD"""
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("hide_bag_prompt"):
		hud.hide_bag_prompt()

# Removed get_interaction_prompt() and interact() -
# Bag now works only with proximity + B key, not E interaction
# This prevents blocking raycast to customer/register

func open_bag_ui() -> void:
	"""Open bag transfer UI"""
	print("BagStation: open_bag_ui() - bag_ui exists: ", bag_ui != null)

	# Check if player has items to bag
	var carry_inventory = InventoryManager.get_inventory("player_carry")
	if carry_inventory.is_empty():
		print("No items in carry inventory - nothing to bag")
		return

	if bag_ui and bag_ui.has_method("show_transfer"):
		print("Calling bag_ui.show_transfer('player_carry', 'shopping_bag')")
		bag_ui.show_transfer("player_carry", "shopping_bag")
	else:
		print("ERROR: Bag UI not initialized or missing show_transfer method!")

func activate_for_checkout() -> void:
	"""Called when checkout starts"""
	is_checkout_active = true
	InventoryManager.clear_inventory("shopping_bag")
	print("Bag station activated for checkout")

func deactivate() -> void:
	"""Called when checkout ends"""
	is_checkout_active = false
	InventoryManager.clear_inventory("shopping_bag")
	print("Bag station deactivated")

func get_bagged_items() -> Dictionary:
	"""Get items currently in the bag"""
	return InventoryManager.get_inventory("shopping_bag")

func _create_bag_ui() -> void:
	"""Create the bag transfer UI"""
	print("BagStation: Creating bag transfer UI...")

	var BagUIScript = preload("res://scripts/ui/bag_transfer_ui.gd")
	bag_ui = BagUIScript.new()
	bag_ui.name = "BagTransferUI"

	# Add to HUD (deferred to avoid "parent busy" error)
	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.add_child.call_deferred(bag_ui)
	else:
		get_tree().get_root().add_child.call_deferred(bag_ui)

	# Wait for deferred add to complete
	await get_tree().process_frame

	# Wait for ready
	if bag_ui and not bag_ui.is_node_ready():
		await get_tree().process_frame

	# Connect signals
	if bag_ui and bag_ui.has_signal("transfer_completed"):
		bag_ui.transfer_completed.connect(_on_transfer_completed)

	print("✓ Bag UI created")

func _on_transfer_completed() -> void:
	"""Called when player closes bag UI"""
	print("BagStation: Transfer completed, emitting items_bagged signal")
	items_bagged.emit()

func _create_interaction_indicator() -> void:
	"""Create the interaction indicator label"""
	var IndicatorScript = load("res://scripts/ui/interaction_indicator.gd")
	interaction_indicator = Node3D.new()
	interaction_indicator.set_script(IndicatorScript)
	interaction_indicator.name = "InteractionIndicator"
	interaction_indicator.position = Vector3(0, 0.5, 0)  # Above the bag
	add_child(interaction_indicator)

	# Wait for it to be ready
	await interaction_indicator.ready

	if interaction_indicator.has_method("set_text"):
		interaction_indicator.set_text("Shopping Bag")

func show_interaction_indicator() -> void:
	"""Called when player looks at this object"""
	if interaction_indicator and interaction_indicator.has_method("show_indicator"):
		interaction_indicator.show_indicator()

func hide_interaction_indicator() -> void:
	"""Called when player looks away"""
	if interaction_indicator and interaction_indicator.has_method("hide_indicator"):
		interaction_indicator.hide_indicator()
