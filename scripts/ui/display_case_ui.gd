extends EquipmentUIBase

# DisplayCaseUI - For display case interaction
# Add items from player inventory to display case

func _ready() -> void:
	super._ready()
	equipment_label.text = "Display Case"
	player_label.text = "Your Cooled Goods"

func _on_player_item_clicked(item_id: String) -> void:
	"""Add item from player inventory to display case"""
	# Check if item is a finished baked good
	if item_id.ends_with("_dough") or item_id.ends_with("_batter"):
		print("%s needs to be baked and cooled first!" % item_id)
		return

	# Get metadata (quality data)
	var metadata = InventoryManager.get_item_metadata(player_inventory_id, item_id)

	# Remove from player
	if InventoryManager.remove_item(player_inventory_id, item_id, 1):
		# Add to display case
		InventoryManager.add_item(equipment_inventory_id, item_id, 1, metadata)

		print("Added %s to display case" % item_id)
		item_transferred.emit(player_inventory_id, equipment_inventory_id, item_id)

		# Refresh display
		_refresh_inventories()

func _on_equipment_item_clicked(item_id: String) -> void:
	"""Remove item from display case (return to player inventory)"""
	# Get metadata
	var metadata = InventoryManager.get_item_metadata(equipment_inventory_id, item_id)

	# Remove from display case
	if InventoryManager.remove_item(equipment_inventory_id, item_id, 1):
		# Add back to player
		InventoryManager.add_item(player_inventory_id, item_id, 1, metadata)

		print("Removed %s from display case" % item_id)
		item_transferred.emit(equipment_inventory_id, player_inventory_id, item_id)

		# Refresh display
		_refresh_inventories()

func _refresh_equipment_inventory() -> void:
	"""Override to show display case with quality indicators"""
	# Clear existing buttons
	for button in equipment_buttons:
		button.queue_free()
	equipment_buttons.clear()

	# Get inventory
	var inventory = InventoryManager.get_inventory(equipment_inventory_id)

	# Show capacity
	var capacity_label = Label.new()
	capacity_label.text = "Items: %d" % inventory.size()
	capacity_label.modulate = Color(0.8, 0.8, 0.8)
	equipment_container.add_child(capacity_label)
	equipment_buttons.append(capacity_label)

	var separator = HSeparator.new()
	equipment_container.add_child(separator)
	equipment_buttons.append(separator)

	if inventory.is_empty():
		var empty_label = Label.new()
		empty_label.text = "Display case is empty\nAdd items to sell!"
		empty_label.modulate = Color(0.6, 0.6, 0.6)
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		equipment_container.add_child(empty_label)
		equipment_buttons.append(empty_label)
	else:
		# Show each item with quality and price
		for item_id in inventory:
			var quantity = inventory[item_id]
			if quantity > 0:
				var item_container = VBoxContainer.new()
				item_container.custom_minimum_size = Vector2(200, 80)

				# Item button with quality indicator
				var metadata = InventoryManager.get_item_metadata(equipment_inventory_id, item_id)
				var quality_data = metadata.get("quality_data", {})
				var quality = quality_data.get("quality", 70)

				var item_button = Button.new()
				var display_name = _get_item_display_name(item_id)

				# Color code by quality
				var quality_color = _get_quality_color(quality)
				item_button.text = "%s x%d" % [display_name, quantity]
				item_button.modulate = quality_color
				item_button.custom_minimum_size = Vector2(200, 40)
				item_button.pressed.connect(_on_equipment_item_clicked.bind(item_id))
				item_container.add_child(item_button)

				# Quality and price label
				var info_label = Label.new()
				var price = _get_item_price(item_id, quality_data)
				info_label.text = "Quality: %.0f%% | Price: $%.2f" % [quality, price]
				info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				info_label.add_theme_font_size_override("font_size", 10)
				info_label.modulate = Color(0.8, 0.8, 0.8)
				item_container.add_child(info_label)

				equipment_container.add_child(item_container)
				equipment_buttons.append(item_container)

func _get_quality_color(quality: float) -> Color:
	"""Get color based on quality tier"""
	if quality >= 100:
		return Color(1.0, 0.8, 1.0)  # Perfect - pink
	elif quality >= 95:
		return Color(1.0, 0.5, 0.0)  # Excellent - orange
	elif quality >= 90:
		return Color(0.2, 1.0, 0.2)  # Good - green
	elif quality >= 70:
		return Color(1.0, 1.0, 1.0)  # Normal - white
	else:
		return Color(0.8, 0.8, 0.5)  # Poor - tan

func _get_item_price(item_id: String, quality_data: Dictionary) -> float:
	"""Get the price for an item"""
	if not RecipeManager:
		return 0.0

	var recipe = RecipeManager.get_recipe(item_id)
	if recipe.is_empty():
		return 0.0

	var base_price = recipe.get("base_price", 0.0)

	# Apply quality multiplier if QualityManager exists
	if QualityManager and not quality_data.is_empty():
		return QualityManager.get_price_for_quality(base_price, quality_data)

	return base_price
