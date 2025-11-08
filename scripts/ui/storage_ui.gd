extends EquipmentUIBase

# StorageUI - For ingredient storage
# Click items in storage to add to player inventory

func _ready() -> void:
	super._ready()
	equipment_label.text = "Storage"

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
