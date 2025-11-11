extends Node3D

# StaffTarget - Simple waypoint marker for staff to stand at
# Place these in your scene and staff will walk to them

class_name StaffTarget

@export var target_name: String = "target"  # e.g., "sink", "trash", "register", "oven"
@export var target_type: String = "generic"  # e.g., "cleaner", "baker", "cashier", "any"

func _ready() -> void:
	# Make visible in editor but invisible in game
	if Engine.is_editor_hint():
		return

	# Hide any visual children during gameplay
	for child in get_children():
		if child is MeshInstance3D or child is CSGShape3D:
			child.visible = false
