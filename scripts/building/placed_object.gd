extends Node3D

# PlacedObject - Attached to every placed furniture/decoration item
# Handles interaction for destruction/refund

# Item data
var item_id: String = ""

# Outline for selection
var outline_mesh: MeshInstance3D = null
var is_hovered: bool = false

func _ready() -> void:
	# Connect interaction area if it exists
	var area = get_node_or_null("InteractionArea")
	if area:
		area.mouse_entered.connect(_on_mouse_entered)
		area.mouse_exited.connect(_on_mouse_exited)
		area.input_event.connect(_on_input_event)

	# Create outline mesh for hover effect
	_create_outline()

func _create_outline() -> void:
	var visual = get_node_or_null("Visual")
	if not visual or not visual is CSGBox3D:
		return

	# Create wireframe outline
	outline_mesh = MeshInstance3D.new()
	outline_mesh.name = "Outline"

	# Create box mesh matching visual size
	var box_mesh = BoxMesh.new()
	box_mesh.size = visual.size * 1.05  # Slightly larger

	outline_mesh.mesh = box_mesh

	# Create outline material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 1.0, 0.0, 0.5)  # Yellow
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED

	outline_mesh.material_override = material
	outline_mesh.visible = false

	add_child(outline_mesh)

func _on_mouse_entered() -> void:
	is_hovered = true
	if outline_mesh:
		outline_mesh.visible = true

func _on_mouse_exited() -> void:
	is_hovered = false
	if outline_mesh:
		outline_mesh.visible = false

func _on_input_event(_camera: Camera3D, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			# Right-click to destroy
			_show_destroy_confirmation()

func _show_destroy_confirmation() -> void:
	var upgrade = UpgradeManager.get_upgrade(item_id)
	if upgrade.is_empty():
		return

	var item_name = upgrade.get("name", item_id)
	var refund = upgrade.get("cost", 0.0)

	# For now, destroy immediately (TODO: add confirmation dialog)
	print("Destroying %s for $%.2f refund" % [item_name, refund])
	BuildingManager.destroy_object(self)

# Alternative interaction via player proximity
func interact(_player: Node3D) -> void:
	_show_destroy_confirmation()
