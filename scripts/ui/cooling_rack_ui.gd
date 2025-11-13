extends EquipmentUIBase

# CoolingRackUI - For cooling rack interaction
# Shows cooling items with timers
# Click items to remove

var cooling_rack_script: Node = null

func _ready() -> void:
	super._ready()
	equipment_label.text = "Cooling Rack"

func open_ui_with_equipment(equipment_inv_id: String, player_inv_id: String, equipment_node: Node) -> void:
	"""Open UI with reference to cooling rack equipment"""
	cooling_rack_script = equipment_node
	open_ui(equipment_inv_id, player_inv_id)

func _process(delta: float) -> void:
	if not visible or not cooling_rack_script:
		return

	# Update timer displays
	_refresh_equipment_inventory()

func _refresh_equipment_inventory() -> void:
	"""Override to show cooling items with individual timers"""
	# Clear existing buttons
	for button in equipment_buttons:
		button.queue_free()
	equipment_buttons.clear()

	if not cooling_rack_script:
		return

	# Show rack status
	var available_slots = cooling_rack_script.get_available_slots()
	var status_label = Label.new()
	status_label.text = "Available slots: %d / %d" % [available_slots, cooling_rack_script.max_slots]
	status_label.modulate = Color(0.8, 0.8, 0.8)
	equipment_container.add_child(status_label)
	equipment_buttons.append(status_label)

	var separator = HSeparator.new()
	equipment_container.add_child(separator)
	equipment_buttons.append(separator)

	# Get cooling items from slots
	var has_items = false
	for slot in cooling_rack_script.cooling_slots:
		if slot.occupied:
			has_items = true

			# Create item display with timer
			var item_container = VBoxContainer.new()
			item_container.custom_minimum_size = Vector2(200, 80)

			# Item button
			var item_button = Button.new()
			var display_name = _get_item_display_name(slot.item_id)

			# Calculate cooling progress
			var progress_percent = (slot.timer / slot.target_time) * 100
			var remaining = slot.target_time - slot.timer

			if slot.timer >= slot.target_time:
				item_button.text = "✓ %s (COOLED)" % display_name
				item_button.modulate = Color(0.2, 1.0, 0.2)
			else:
				item_button.text = "%s (%.0f%%)" % [display_name, progress_percent]

			item_button.custom_minimum_size = Vector2(200, 40)
			item_button.pressed.connect(_on_cooling_rack_item_clicked.bind(slot.item_id))
			item_container.add_child(item_button)

			# Timer label
			var timer_label = Label.new()
			if slot.timer >= slot.target_time:
				timer_label.text = "Ready to collect!"
				timer_label.modulate = Color(0.2, 1.0, 0.2)
			else:
				timer_label.text = "%.1fs / %.1fs" % [remaining, slot.target_time]
				timer_label.modulate = Color(1.0, 0.8, 0.2)
			timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			item_container.add_child(timer_label)

			# Warning if removing early
			if slot.timer < slot.target_time * 0.5:  # Less than 50% done
				var warning_label = Label.new()
				warning_label.text = "⚠ Removing early reduces quality!"
				warning_label.modulate = Color(1.0, 0.3, 0.3)
				warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				warning_label.add_theme_font_size_override("font_size", 10)
				item_container.add_child(warning_label)

			equipment_container.add_child(item_container)
			equipment_buttons.append(item_container)

	if not has_items:
		var empty_label = Label.new()
		empty_label.text = "Cooling rack is empty"
		empty_label.modulate = Color(0.6, 0.6, 0.6)
		equipment_container.add_child(empty_label)
		equipment_buttons.append(empty_label)

func _on_cooling_rack_item_clicked(item_id: String) -> void:
	"""Remove item from cooling rack"""
	if not cooling_rack_script:
		return

	# Remove from cooling rack (this handles quality penalty if rushed)
	var quality_data = cooling_rack_script.remove_item(item_id)

	# Add to player
	InventoryManager.add_item(player_inventory_id, item_id, 1, {"quality_data": quality_data})

	print("Removed %s from cooling rack" % item_id)
	item_transferred.emit(equipment_inventory_id, player_inventory_id, item_id)

	# Refresh display
	_refresh_inventories()

func _on_player_item_clicked(item_id: String) -> void:
	"""Add item from player inventory to cooling rack"""
	if not cooling_rack_script:
		return

	# Check if rack has space
	if not cooling_rack_script.can_add_item():
		print("Cooling rack is full!")
		return

	# Check if item can be cooled (finished baked goods only)
	if item_id.ends_with("_dough") or item_id.ends_with("_batter"):
		print("%s needs to be baked first!" % item_id)
		return

	# Get metadata
	var metadata = InventoryManager.get_item_metadata(player_inventory_id, item_id)

	# Remove from player
	if InventoryManager.remove_item(player_inventory_id, item_id, 1):
		# Add to cooling rack
		var quality_data = metadata["quality_data"] if metadata.has("quality_data") else {}
		cooling_rack_script.add_item_to_cool(item_id, quality_data)

		print("Added %s to cooling rack" % item_id)
		item_transferred.emit(player_inventory_id, equipment_inventory_id, item_id)

		# Refresh display
		_refresh_inventories()
