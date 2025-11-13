extends EquipmentUIBase

# OvenUI - For oven interaction
# Shows multiple baking slots with individual timers
# Click items to remove from oven

var oven_script: Node = null
var last_slot_count: int = 0
var last_finished_count: int = 0
var slot_timer_labels: Array[Label] = []  # Track timer labels for live updates
var slot_buttons: Array[Button] = []  # Track slot buttons for live updates

func _ready() -> void:
	super._ready()
	equipment_label.text = "Oven"

func open_ui_with_equipment(equipment_inv_id: String, player_inv_id: String, equipment_node: Node) -> void:
	"""Open UI with reference to oven equipment"""
	oven_script = equipment_node
	open_ui(equipment_inv_id, player_inv_id)
	last_slot_count = -1  # Force initial refresh
	last_finished_count = -1

func _process(delta: float) -> void:
	if not visible or not oven_script:
		return

	# Update timer labels every frame without rebuilding UI
	_update_timer_displays()

	# Only rebuild UI if slot count or finished items changed
	var current_slot_count = oven_script.baking_slots.size() if "baking_slots" in oven_script else 0
	var inventory = InventoryManager.get_inventory(equipment_inventory_id)
	var current_finished_count = 0
	for item_id in inventory:
		if not (item_id.ends_with("_dough") or item_id.ends_with("_batter")):
			current_finished_count += inventory[item_id]

	if current_slot_count != last_slot_count or current_finished_count != last_finished_count:
		last_slot_count = current_slot_count
		last_finished_count = current_finished_count
		_refresh_equipment_inventory()

func _update_timer_displays() -> void:
	"""Update timer text without rebuilding UI"""
	if not oven_script or "baking_slots" not in oven_script:
		return

	# Update each slot's timer and button text
	for i in range(min(slot_timer_labels.size(), oven_script.baking_slots.size())):
		var slot = oven_script.baking_slots[i]
		var timer_label = slot_timer_labels[i]
		var slot_button = slot_buttons[i]

		if not is_instance_valid(timer_label) or not is_instance_valid(slot_button):
			continue

		# Get cooking state info
		var slot_info = oven_script.get_slot_info_by_index(i)
		var cooking_state = slot_info.get("cooking_state", 0)
		var state_name = slot_info.get("cooking_state_name", "Baking")
		var state_color = slot_info.get("cooking_state_color", Color.WHITE)

		var progress_percent = (slot.timer / slot.target_time) * 100 if slot.target_time > 0 else 0
		var remaining = slot.target_time - slot.timer
		var display_name = _get_item_display_name(slot.item_id)

		# Update button text with cooking state
		slot_button.text = "Slot %d: %s - %s" % [i + 1, display_name, state_name]
		slot_button.modulate = state_color

		# Update timer label with progress
		timer_label.text = "%.0f%% (%.1fs remaining)" % [progress_percent, max(0, remaining)]
		timer_label.modulate = state_color

func _refresh_equipment_inventory() -> void:
	"""Override to show baking slots with individual timers"""
	# Clear ALL children from equipment_container
	for child in equipment_container.get_children():
		equipment_container.remove_child(child)
		child.queue_free()  # Use queue_free() - safe now that we don't refresh every frame
	equipment_buttons.clear()
	slot_timer_labels.clear()
	slot_buttons.clear()

	if not oven_script:
		return

	# Show oven status with slot count
	var status_label = Label.new()
	var slot_count = oven_script.get_slot_count() if oven_script.has_method("get_slot_count") else 0
	var max_slots = oven_script.get_max_slots() if oven_script.has_method("get_max_slots") else 4

	if slot_count > 0:
		status_label.text = "Oven: %d/%d slots used" % [slot_count, max_slots]
		status_label.modulate = Color(1.0, 0.8, 0.2)
	else:
		status_label.text = "Oven ready (%d slots available)" % max_slots
		status_label.modulate = Color(0.8, 0.8, 0.8)
	equipment_container.add_child(status_label)
	# Don't append labels to equipment_buttons (it's typed as Array[Button])

	var separator1 = HSeparator.new()
	equipment_container.add_child(separator1)
	# Don't append separators to equipment_buttons

	# Show baking slots (not inventory, since inventory groups items)
	if "baking_slots" not in oven_script or oven_script.baking_slots.is_empty():
		var empty_label = Label.new()
		empty_label.text = "Oven is empty"
		empty_label.modulate = Color(0.6, 0.6, 0.6)
		equipment_container.add_child(empty_label)
		# Don't append labels to equipment_buttons
	else:
		# Show each baking slot individually with its own timer
		var slot_index = 0
		for slot in oven_script.baking_slots:
			var item_id = slot.item_id
			var display_name = _get_item_display_name(item_id)

			# Get cooking state info
			var slot_info = oven_script.get_slot_info_by_index(slot_index)
			var cooking_state = slot_info.get("cooking_state", 0)
			var state_name = slot_info.get("cooking_state_name", "Baking")
			var state_color = slot_info.get("cooking_state_color", Color.WHITE)

			# Create item display with timer
			var item_container = VBoxContainer.new()
			item_container.custom_minimum_size = Vector2(200, 80)

			# Item button
			var item_button = Button.new()

			# Calculate baking progress from slot data
			var progress_percent = (slot.timer / slot.target_time) * 100 if slot.target_time > 0 else 0
			var remaining = slot.target_time - slot.timer

			# Update button text with cooking state
			item_button.text = "Slot %d: %s - %s" % [slot_index + 1, display_name, state_name]
			item_button.modulate = state_color

			item_button.custom_minimum_size = Vector2(200, 40)
			item_button.pressed.connect(_on_oven_slot_clicked.bind(slot_index + 1))
			item_container.add_child(item_button)
			equipment_buttons.append(item_button)  # Track the button, not the container
			slot_buttons.append(item_button)  # Also track for live updates

			# Timer label with progress
			var timer_label = Label.new()
			timer_label.text = "%.0f%% (%.1fs remaining)" % [progress_percent, max(0, remaining)]
			timer_label.modulate = state_color
			timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			item_container.add_child(timer_label)
			slot_timer_labels.append(timer_label)  # Track for live updates

			equipment_container.add_child(item_container)

			slot_index += 1

	# Also show finished items in the oven inventory (these are done baking)
	var inventory = InventoryManager.get_inventory(equipment_inventory_id)
	var has_finished_products = false

	for item_id in inventory:
		# Only show finished products (not dough/batter)
		if not (item_id.ends_with("_dough") or item_id.ends_with("_batter")):
			var quantity = inventory[item_id]
			if quantity > 0:
				# Add separator and header only once
				if not has_finished_products:
					var separator2 = HSeparator.new()
					equipment_container.add_child(separator2)
					# Don't append separators to equipment_buttons

					var finished_label = Label.new()
					finished_label.text = "Finished Products:"
					finished_label.modulate = Color(0.2, 1.0, 0.2)
					equipment_container.add_child(finished_label)
					# Don't append labels to equipment_buttons
					has_finished_products = true

				# Create button for each finished product type
				var item_button = Button.new()
				var display_name = _get_item_display_name(item_id)
				item_button.text = "✓ %s x%d (Click to collect)" % [display_name, quantity]
				item_button.custom_minimum_size = Vector2(200, 40)
				item_button.modulate = Color(0.2, 1.0, 0.2)
				item_button.pressed.connect(_on_oven_item_clicked.bind(item_id))
				equipment_container.add_child(item_button)
				equipment_buttons.append(item_button)  # Only append actual buttons
				print("[OvenUI] Added finished product button for: ", item_id, " x", quantity)

func _get_baking_info(item_id: String) -> Dictionary:
	"""Get baking progress for an item"""
	if not oven_script:
		return {"progress": 0.0, "total": 0.0, "is_done": false}

	# Use oven's slot info for multi-slot support
	var slot_info = oven_script.get_slot_info(item_id)
	return {
		"progress": slot_info.get("timer", 0.0),
		"total": slot_info.get("target_time", 1.0),
		"is_done": slot_info.get("is_done", false)
	}

func _on_oven_slot_clicked(slot_index: int) -> void:
	"""Handle clicking on a baking slot - collect item or show warning"""
	if not oven_script:
		return

	# Adjust for 1-based display index (we show "Slot 1" but array is 0-indexed)
	var array_index = slot_index - 1

	if array_index < 0 or array_index >= oven_script.baking_slots.size():
		print("Invalid slot index!")
		return

	var slot = oven_script.baking_slots[array_index]

	# Get cooking state info
	var slot_info = oven_script.get_slot_info_by_index(array_index)
	var cooking_state = slot_info.get("cooking_state", 0)
	var state_name = slot_info.get("cooking_state_name", "Unknown")

	# Always allow collection - just warn if undercooked
	if cooking_state == oven_script.CookingState.UNDERCOOKED:
		print("⚠ WARNING: Item is still undercooked!")
		print("⚠ Quality will be significantly reduced if you collect it now.")
		print("⚠ Collecting anyway...")

	# Complete baking for this slot
	print("Collecting item from slot %d (State: %s)" % [slot_index, state_name])
	oven_script.complete_baking_slot(array_index)
	_refresh_inventories()

func _on_oven_item_clicked(item_id: String) -> void:
	"""Remove finished item from oven (for items in 'Finished Products' section)"""
	print("[OvenUI] _on_oven_item_clicked called for: ", item_id)

	if not oven_script:
		print("[OvenUI] ERROR: No oven script!")
		return

	# Get metadata (quality data, etc.)
	var metadata = InventoryManager.get_item_metadata(equipment_inventory_id, item_id)
	print("[OvenUI] Metadata: ", metadata)

	# Check what's in oven inventory
	var oven_inv = InventoryManager.get_inventory(equipment_inventory_id)
	print("[OvenUI] Oven inventory: ", oven_inv)

	# Remove from oven
	if InventoryManager.remove_item(equipment_inventory_id, item_id, 1):
		# Add to player
		InventoryManager.add_item(player_inventory_id, item_id, 1, metadata)

		print("[OvenUI] ✓ Successfully collected %s from oven" % item_id)
		item_transferred.emit(equipment_inventory_id, player_inventory_id, item_id)

		# Refresh display
		_refresh_inventories()
	else:
		print("[OvenUI] ✗ FAILED to remove %s from oven - not in inventory!" % item_id)

func _on_player_item_clicked(item_id: String) -> void:
	"""Add item from player inventory to oven"""
	if not oven_script:
		return

	# Check if oven is full (use oven's built-in slot check)
	if not oven_script.is_slot_available():
		var max_slots = oven_script.get_max_slots()
		print("Oven is full! (%d/%d slots)" % [max_slots, max_slots])
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

		# Start baking in a new slot
		if oven_script.has_method("start_baking"):
			var quality_data = metadata["quality_data"] if metadata.has("quality_data") else {}
			if oven_script.start_baking(item_id, quality_data):
				print("Added %s to oven (slot %d/%d)" % [item_id, oven_script.get_slot_count(), oven_script.get_max_slots()])
				item_transferred.emit(player_inventory_id, equipment_inventory_id, item_id)
			else:
				# Failed to start baking, return item to player
				InventoryManager.remove_item(equipment_inventory_id, item_id, 1)
				InventoryManager.add_item(player_inventory_id, item_id, 1, metadata)
				print("Failed to add %s to oven" % item_id)

		# Refresh display
		_refresh_inventories()
