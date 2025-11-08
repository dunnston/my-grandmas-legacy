extends EquipmentUIBase

# OvenUI - For oven interaction
# Shows multiple baking slots with individual timers
# Click items to remove from oven

var oven_script: Node = null

func _ready() -> void:
	super._ready()
	equipment_label.text = "Oven"

func open_ui_with_equipment(equipment_inv_id: String, player_inv_id: String, equipment_node: Node) -> void:
	"""Open UI with reference to oven equipment"""
	oven_script = equipment_node
	open_ui(equipment_inv_id, player_inv_id)

func _process(delta: float) -> void:
	if not visible or not oven_script:
		return

	# Update timer displays for baking items
	_refresh_equipment_inventory()

func _refresh_equipment_inventory() -> void:
	"""Override to show baking slots with individual timers"""
	# Clear existing buttons
	for button in equipment_buttons:
		button.queue_free()
	equipment_buttons.clear()

	if not oven_script:
		return

	# Show oven status
	var status_label = Label.new()
	if oven_script.is_baking:
		status_label.text = "Baking in progress..."
		status_label.modulate = Color(1.0, 0.8, 0.2)
	else:
		status_label.text = "Oven ready"
		status_label.modulate = Color(0.8, 0.8, 0.8)
	equipment_container.add_child(status_label)
	equipment_buttons.append(status_label)

	var separator1 = HSeparator.new()
	equipment_container.add_child(separator1)
	equipment_buttons.append(separator1)

	# Get inventory
	var inventory = InventoryManager.get_inventory(equipment_inventory_id)

	if inventory.is_empty():
		var empty_label = Label.new()
		empty_label.text = "Oven is empty"
		empty_label.modulate = Color(0.6, 0.6, 0.6)
		equipment_container.add_child(empty_label)
		equipment_buttons.append(empty_label)
	else:
		# Show each item with its baking progress
		for item_id in inventory:
			var quantity = inventory[item_id]
			if quantity > 0:
				# Create item display with timer
				var item_container = VBoxContainer.new()
				item_container.custom_minimum_size = Vector2(200, 80)

				# Item button
				var item_button = Button.new()
				var display_name = _get_item_display_name(item_id)

				# Calculate baking progress
				var bake_info = _get_baking_info(item_id)
				var progress_percent = (bake_info.progress / bake_info.total) * 100 if bake_info.total > 0 else 0
				var remaining = bake_info.total - bake_info.progress

				if bake_info.is_done:
					item_button.text = "✓ %s (DONE)" % display_name
					item_button.modulate = Color(0.2, 1.0, 0.2)
				else:
					item_button.text = "%s (%.0f%%)" % [display_name, progress_percent]

				item_button.custom_minimum_size = Vector2(200, 40)
				item_button.pressed.connect(_on_oven_item_clicked.bind(item_id))
				item_container.add_child(item_button)

				# Timer label
				var timer_label = Label.new()
				if bake_info.is_done:
					timer_label.text = "Ready to remove!"
					timer_label.modulate = Color(0.2, 1.0, 0.2)
				else:
					timer_label.text = "%.1fs / %.1fs remaining" % [remaining, bake_info.total]
					timer_label.modulate = Color(0.8, 0.8, 0.8)
				timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				item_container.add_child(timer_label)

				equipment_container.add_child(item_container)
				equipment_buttons.append(item_container)

func _get_baking_info(item_id: String) -> Dictionary:
	"""Get baking progress for an item"""
	if not oven_script:
		return {"progress": 0.0, "total": 0.0, "is_done": false}

	# For now, use oven's global timer
	# TODO: Multi-slot ovens with individual timers would need slot tracking
	return {
		"progress": oven_script.baking_timer,
		"total": oven_script.baking_time,
		"is_done": oven_script.has_finished_item
	}

func _on_oven_item_clicked(item_id: String) -> void:
	"""Remove item from oven"""
	if not oven_script:
		return

	# Get metadata (quality data, etc.)
	var metadata = InventoryManager.get_item_metadata(equipment_inventory_id, item_id)

	# Remove from oven
	if InventoryManager.remove_item(equipment_inventory_id, item_id, 1):
		# Add to player
		InventoryManager.add_item(player_inventory_id, item_id, 1, metadata)

		# Update oven state
		if oven_script.is_baking and oven_script.current_item == item_id:
			oven_script.is_baking = false
			oven_script.has_finished_item = false

		print("Removed %s from oven" % item_id)
		item_transferred.emit(equipment_inventory_id, player_inventory_id, item_id)

		# Refresh display
		_refresh_inventories()

func _on_player_item_clicked(item_id: String) -> void:
	"""Add item from player inventory to oven"""
	if not oven_script:
		return

	# Check if oven is full
	var inventory = InventoryManager.get_inventory(equipment_inventory_id)
	if inventory.size() >= 1:  # Simple oven: 1 slot only for now
		print("Oven is full!")
		return

	# Check if item is bakeable (has "_dough" or "_batter" suffix)
	if not (item_id.ends_with("_dough") or item_id.ends_with("_batter")):
		print("%s cannot be baked!" % item_id)
		return

	# Get metadata
	var metadata = InventoryManager.get_item_metadata(player_inventory_id, item_id)

	# Remove from player
	if InventoryManager.remove_item(player_inventory_id, item_id, 1):
		# Add to oven
		InventoryManager.add_item(equipment_inventory_id, item_id, 1, metadata)

		# Start baking if not already
		if oven_script.has_method("start_baking"):
			oven_script.start_baking(item_id, metadata.get("quality_data", {}))

		print("Added %s to oven" % item_id)
		item_transferred.emit(player_inventory_id, equipment_inventory_id, item_id)

		# Refresh display
		_refresh_inventories()
