extends Node3D

# CoolingRack - Cools baked goods before they can be placed in display case
# GDD Reference: Section 4.1.2, Lines 222-224
# Items require 30-60 second cooldown
# Rushing (removing too early) reduces quality

signal cooling_started(item_name: String)
signal cooling_complete(item_name: String, quality_data: Dictionary)
signal item_rushed(item_name: String, quality_penalty: float)

@export var cooling_time: float = 45.0  # Default 45 seconds (30-60 range from GDD)
@export var max_slots: int = 6  # Can cool multiple items at once

# Node references
@onready var interaction_area: Area3D = $InteractionArea
@onready var mesh: CSGBox3D = $RackMesh

# Cooling slots - each slot tracks one cooling item
var cooling_slots: Array[Dictionary] = []
var player_nearby: Node3D = null

func _ready() -> void:
	# Create inventory for this station
	InventoryManager.create_inventory(get_inventory_id())

	# Initialize empty cooling slots
	for i in range(max_slots):
		cooling_slots.append({
			"occupied": false,
			"item_id": "",
			"timer": 0.0,
			"target_time": 0.0,
			"quality_data": {}
		})

	# Connect interaction area
	if interaction_area:
		interaction_area.body_entered.connect(_on_body_entered)
		interaction_area.body_exited.connect(_on_body_exited)

	print("Cooling Rack ready: ", name, " (", max_slots, " slots)")

func _process(delta: float) -> void:
	# Update all cooling timers
	if GameManager and not GameManager.is_game_paused():
		var time_scale = GameManager.get_time_scale() if GameManager else 1.0

		for slot in cooling_slots:
			if slot.occupied:
				slot.timer += delta * time_scale

				# Auto-complete when done
				if slot.timer >= slot.target_time:
					_complete_cooling_slot(slot)

# Interaction system
func _on_body_entered(body: Node3D) -> void:
	if body.has_method("get_inventory_id"):
		player_nearby = body
		print("Player near cooling rack")

func _on_body_exited(body: Node3D) -> void:
	if body == player_nearby:
		player_nearby = null
		print("Player left cooling rack")

# Core cooling methods
func can_add_item() -> bool:
	"""Check if there's an empty slot"""
	for slot in cooling_slots:
		if not slot.occupied:
			return true
	return false

func add_item_to_cool(item_id: String, quality_data: Dictionary = {}) -> bool:
	"""Add a hot item to the cooling rack"""
	# Find first empty slot
	for slot in cooling_slots:
		if not slot.occupied:
			slot.occupied = true
			slot.item_id = item_id
			slot.timer = 0.0
			slot.target_time = cooling_time
			slot.quality_data = quality_data.duplicate()

			# Add to inventory for tracking
			InventoryManager.add_item(get_inventory_id(), item_id, 1, quality_data)

			print("Added %s to cooling rack (slot %d, needs %.0fs)" % [item_id, cooling_slots.find(slot), cooling_time])
			cooling_started.emit(item_id)
			return true

	print("Cooling rack is full!")
	return false

func _complete_cooling_slot(slot: Dictionary) -> void:
	"""Complete cooling for a slot"""
	if not slot.occupied:
		return

	var item_id = slot.item_id
	var quality_data = slot.quality_data

	print("%s finished cooling" % item_id)
	cooling_complete.emit(item_id, quality_data)

	# Keep in inventory but mark as cooled (player can remove anytime)
	# Don't auto-remove - let player take when ready

func remove_item(item_id: String, force_early: bool = false) -> Dictionary:
	"""Remove an item from the cooling rack (returns quality_data)"""
	# Find the slot with this item
	for i in range(cooling_slots.size()):
		var slot = cooling_slots[i]
		if slot.occupied and slot.item_id == item_id:
			var quality_data = slot.quality_data.duplicate()
			var was_rushed = slot.timer < slot.target_time

			if was_rushed and not force_early:
				print("WARNING: %s removed too early (%.0fs/%.0fs)" % [item_id, slot.timer, slot.target_time])

			# Apply quality penalty if rushed
			if was_rushed:
				var completion_ratio = slot.timer / slot.target_time
				var penalty = _calculate_rush_penalty(completion_ratio)

				if quality_data.has("quality"):
					quality_data.quality = max(0, quality_data.quality - penalty)

				print("Item rushed! Quality penalty: -%.0f%% (new quality: %.0f%%)" % [penalty, quality_data.get("quality", 0)])
				item_rushed.emit(item_id, penalty)

			# Remove from slot
			slot.occupied = false
			slot.item_id = ""
			slot.timer = 0.0
			slot.target_time = 0.0
			slot.quality_data = {}

			# Remove from inventory
			InventoryManager.remove_item(get_inventory_id(), item_id, 1)

			return quality_data

	push_warning("Item not found on cooling rack: ", item_id)
	return {}

func _calculate_rush_penalty(completion_ratio: float) -> float:
	"""Calculate quality penalty for rushing (GDD: reduces quality)"""
	# 0% complete = -30% quality
	# 50% complete = -15% quality
	# 75% complete = -7.5% quality
	# 100% complete = 0% penalty
	var max_penalty = BalanceConfig.EQUIPMENT.get("cooling_rack_rush_penalty", 30.0)
	return max_penalty * (1.0 - completion_ratio)

# Helper methods
func get_cooling_progress(item_id: String) -> float:
	"""Get cooling progress for an item (0.0 to 1.0)"""
	for slot in cooling_slots:
		if slot.occupied and slot.item_id == item_id:
			return clamp(slot.timer / slot.target_time, 0.0, 1.0)
	return 0.0

func get_cooling_items() -> Array[String]:
	"""Get list of all items currently cooling"""
	var items: Array[String] = []
	for slot in cooling_slots:
		if slot.occupied:
			items.append(slot.item_id)
	return items

func get_available_slots() -> int:
	"""Get number of empty slots"""
	var count = 0
	for slot in cooling_slots:
		if not slot.occupied:
			count += 1
	return count

func get_inventory_id() -> String:
	return "cooling_rack_" + name

# Save/Load support
func get_save_data() -> Dictionary:
	return {
		"cooling_slots": cooling_slots.duplicate(true)
	}

func load_save_data(data: Dictionary) -> void:
	if data.has("cooling_slots"):
		cooling_slots = data["cooling_slots"].duplicate(true)

		# Restore inventory from slots
		for slot in cooling_slots:
			if slot.occupied:
				InventoryManager.add_item(get_inventory_id(), slot.item_id, 1, slot.quality_data)

	print("Cooling rack data loaded")
