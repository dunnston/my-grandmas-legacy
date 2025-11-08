extends EquipmentUIBase

# MixingBowlUI - For mixing bowl interaction
# Shows ingredient slots on left, player inventory on right
# Shows mixing timer and finished product slot

var mixing_bowl_script: Node = null

# Additional UI components
var timer_label: Label
var status_label: Label
var finished_product_button: Button

var status_container: VBoxContainer
var status_display_created: bool = false

func _ready() -> void:
	super._ready()
	if equipment_label:
		equipment_label.text = "Mixing Bowl"

func _create_status_display() -> void:
	"""Create timer and status labels (called lazily on first open)"""
	if status_display_created or not equipment_container:
		return

	status_container = VBoxContainer.new()
	status_container.custom_minimum_size = Vector2(0, 60)

	status_label = Label.new()
	status_label.text = "Idle"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_container.add_child(status_label)

	timer_label = Label.new()
	timer_label.text = ""
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_container.add_child(timer_label)

	# Add to equipment side, after label
	var parent = equipment_container.get_parent()
	if parent:
		parent.add_child(status_container)
		parent.move_child(status_container, 1)
		status_display_created = true

func open_ui_with_equipment(equipment_inv_id: String, player_inv_id: String, equipment_node: Node) -> void:
	"""Open UI with reference to mixing bowl equipment"""
	mixing_bowl_script = equipment_node
	_create_status_display()  # Create status display on first open
	open_ui(equipment_inv_id, player_inv_id)

func _process(delta: float) -> void:
	if not visible or not mixing_bowl_script:
		return

	# Update timer display
	if mixing_bowl_script.is_mixing:
		var progress = mixing_bowl_script.mixing_timer
		var total = mixing_bowl_script.target_mix_time
		var remaining = total - progress

		status_label.text = "Mixing..."
		timer_label.text = "Time remaining: %.1fs / %.1fs" % [remaining, total]

		# Show progress bar
		var percent = (progress / total) * 100
		timer_label.text += " (%.0f%%)" % percent
	elif mixing_bowl_script.has_finished_item:
		status_label.text = "Ready!"
		timer_label.text = "Click finished product to collect"
	else:
		status_label.text = "Idle"
		timer_label.text = "Add ingredients to start"

func _refresh_equipment_inventory() -> void:
	"""Override to show ingredient slots and finished product"""
	# Clear existing buttons
	for button in equipment_buttons:
		button.queue_free()
	equipment_buttons.clear()

	# Get inventory
	var inventory = InventoryManager.get_inventory(equipment_inventory_id)

	# Show current ingredients
	var ingredient_label = Label.new()
	ingredient_label.text = "Current Ingredients:"
	ingredient_label.modulate = Color(0.8, 0.8, 0.8)
	equipment_container.add_child(ingredient_label)
	equipment_buttons.append(ingredient_label)  # Track for cleanup

	if inventory.is_empty():
		var empty_label = Label.new()
		empty_label.text = "(Empty - add from your inventory)"
		empty_label.modulate = Color(0.6, 0.6, 0.6)
		equipment_container.add_child(empty_label)
		equipment_buttons.append(empty_label)
	else:
		for item_id in inventory:
			var quantity = inventory[item_id]
			if quantity > 0:
				# Skip the finished product (it's shown separately)
				if mixing_bowl_script and mixing_bowl_script.has_finished_item and item_id == mixing_bowl_script.current_item:
					continue

				var button = _create_item_button(item_id, quantity)
				button.disabled = mixing_bowl_script.is_mixing  # Can't remove while mixing
				button.pressed.connect(_on_equipment_item_clicked.bind(item_id))
				equipment_container.add_child(button)
				equipment_buttons.append(button)

	# Add "Start Mixing" button if we have ingredients and not currently mixing
	if not inventory.is_empty() and mixing_bowl_script and not mixing_bowl_script.is_mixing and not mixing_bowl_script.has_finished_item:
		var start_button = Button.new()
		start_button.text = "▶ Start Mixing"
		start_button.custom_minimum_size = Vector2(200, 50)
		start_button.modulate = Color(0.2, 0.8, 0.2)
		start_button.pressed.connect(_on_start_mixing_pressed)
		equipment_container.add_child(start_button)
		equipment_buttons.append(start_button)

	# Show finished product if available
	if mixing_bowl_script and mixing_bowl_script.has_finished_item:
		var separator = HSeparator.new()
		equipment_container.add_child(separator)
		equipment_buttons.append(separator)

		var finished_label = Label.new()
		finished_label.text = "Finished Product:"
		finished_label.modulate = Color(0.2, 0.8, 0.2)
		equipment_container.add_child(finished_label)
		equipment_buttons.append(finished_label)

		finished_product_button = Button.new()
		finished_product_button.text = "✓ %s (Click to collect)" % _get_item_display_name(mixing_bowl_script.current_item)
		finished_product_button.custom_minimum_size = Vector2(200, 50)
		finished_product_button.pressed.connect(_on_collect_finished_product)
		equipment_container.add_child(finished_product_button)
		equipment_buttons.append(finished_product_button)

func _on_player_item_clicked(item_id: String) -> void:
	"""Add ingredient from player inventory to mixing bowl"""
	if not mixing_bowl_script:
		return

	# Can't add while mixing
	if mixing_bowl_script.is_mixing:
		print("Can't add ingredients while mixing!")
		return

	# Remove from player
	if InventoryManager.remove_item(player_inventory_id, item_id, 1):
		# Add to mixing bowl
		InventoryManager.add_item(equipment_inventory_id, item_id, 1)

		print("Added %s to mixing bowl" % item_id)
		item_transferred.emit(player_inventory_id, equipment_inventory_id, item_id)

		# Check if we can start mixing (mixing bowl script will handle this)
		# Refresh display
		_refresh_inventories()

func _on_equipment_item_clicked(item_id: String) -> void:
	"""Remove ingredient from mixing bowl (if not mixing)"""
	if not mixing_bowl_script:
		return

	# Can't remove while mixing
	if mixing_bowl_script.is_mixing:
		print("Can't remove ingredients while mixing!")
		return

	# Remove from mixing bowl
	if InventoryManager.remove_item(equipment_inventory_id, item_id, 1):
		# Add back to player
		InventoryManager.add_item(player_inventory_id, item_id, 1)

		print("Removed %s from mixing bowl" % item_id)
		item_transferred.emit(equipment_inventory_id, player_inventory_id, item_id)

		# Refresh display
		_refresh_inventories()

func _on_collect_finished_product() -> void:
	"""Collect finished product from mixing bowl"""
	if not mixing_bowl_script or not mixing_bowl_script.has_finished_item:
		return

	var item_id = mixing_bowl_script.current_item

	# Remove from mixing bowl
	InventoryManager.remove_item(equipment_inventory_id, item_id, 1)

	# Add to player
	InventoryManager.add_item(player_inventory_id, item_id, 1)

	# Clear mixing bowl state
	mixing_bowl_script.has_finished_item = false
	mixing_bowl_script.current_item = ""

	print("Collected %s from mixing bowl" % item_id)

	# Refresh display
	_refresh_inventories()

func _on_start_mixing_pressed() -> void:
	"""Check for valid recipe and start mixing"""
	if not mixing_bowl_script:
		return

	# Get current ingredients in the bowl
	var bowl_inventory = InventoryManager.get_inventory(equipment_inventory_id)

	# Check each unlocked recipe to see if we can make it
	var unlocked_recipes = RecipeManager.get_all_unlocked_recipes()
	for recipe in unlocked_recipes:
		if RecipeManager.can_craft_recipe(recipe["id"], bowl_inventory):
			print("Starting to mix: %s" % recipe["name"])
			mixing_bowl_script.start_crafting(recipe, recipe["id"])
			_refresh_inventories()
			return

	# No valid recipe found
	print("These ingredients don't match any known recipe!")
	# TODO: Show error message in UI
