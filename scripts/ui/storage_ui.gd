extends EquipmentUIBase

# StorageUI - For ingredient storage
# Click items in storage to add to player inventory

func _ready() -> void:
	super._ready()
	equipment_label.text = "Storage"

func _refresh_equipment_inventory() -> void:
	"""Override to add 'Transfer All' button"""
	# Call parent to show all items
	super._refresh_equipment_inventory()

	# Add "Transfer All" button if storage has items
	var storage_inventory = InventoryManager.get_inventory(equipment_inventory_id)
	if not storage_inventory.is_empty():
		var separator = HSeparator.new()
		equipment_container.add_child(separator)
		equipment_buttons.append(separator)

		var transfer_all_button = Button.new()
		transfer_all_button.text = "⬇ Transfer All to Inventory"
		transfer_all_button.custom_minimum_size = Vector2(200, 50)
		transfer_all_button.modulate = Color(0.2, 0.8, 1.0)  # Blue color
		transfer_all_button.pressed.connect(_on_transfer_all_pressed)
		equipment_container.add_child(transfer_all_button)
		equipment_buttons.append(transfer_all_button)

func _on_equipment_item_clicked(item_id: String) -> void:
	"""Transfer item from storage to player inventory"""
	# Remove from storage
	if InventoryManager.remove_item(equipment_inventory_id, item_id, 1):
		# Add to player
		InventoryManager.add_item(player_inventory_id, item_id, 1)

		print("Transferred %s from storage to player" % item_id)
		item_transferred.emit(equipment_inventory_id, player_inventory_id, item_id)

		# Refresh display
		_refresh_inventories()

func _on_player_item_clicked(item_id: String) -> void:
	"""Transfer item from player inventory back to storage"""
	# Remove from player
	if InventoryManager.remove_item(player_inventory_id, item_id, 1):
		# Add to storage
		InventoryManager.add_item(equipment_inventory_id, item_id, 1)

		print("Transferred %s from player to storage" % item_id)
		item_transferred.emit(player_inventory_id, equipment_inventory_id, item_id)

		# Refresh display
		_refresh_inventories()

func _on_transfer_all_pressed() -> void:
	"""Transfer all items from storage to player inventory"""
	var storage_inventory = InventoryManager.get_inventory(equipment_inventory_id)

	if storage_inventory.is_empty():
		print("Storage is empty!")
		return

	var total_items = 0
	var items_transferred = []

	# Create a copy of the inventory keys to avoid modifying during iteration
	var items_to_transfer = storage_inventory.keys()

	for item_id in items_to_transfer:
		var quantity = storage_inventory.get(item_id, 0)
		if quantity > 0:
			# Transfer all of this item
			if InventoryManager.transfer_item(equipment_inventory_id, player_inventory_id, item_id, quantity):
				total_items += quantity
				items_transferred.append("%s x%d" % [item_id, quantity])
				item_transferred.emit(equipment_inventory_id, player_inventory_id, item_id)

	print("Transferred all items from storage to inventory:")
	for item in items_transferred:
		print("  - %s" % item)
	print("Total: %d items transferred" % total_items)

	# Refresh display
	_refresh_inventories()
