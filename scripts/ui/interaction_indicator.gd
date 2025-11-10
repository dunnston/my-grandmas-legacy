extends Node3D

# InteractionIndicator - Shows a label above interactable objects
# Automatically created by interactable objects

var label: Label3D = null
var background: MeshInstance3D = null
var interaction_text: String = ""

func _ready() -> void:
	# Create background quad
	background = MeshInstance3D.new()
	var quad_mesh = QuadMesh.new()
	quad_mesh.size = Vector2(2.0, 0.5)
	background.mesh = quad_mesh

	# Create material for background
	var bg_material = StandardMaterial3D.new()
	bg_material.albedo_color = Color(0.2, 0.2, 0.2, 0.8)
	bg_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bg_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bg_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	background.material_override = bg_material
	add_child(background)

	# Create label
	label = Label3D.new()
	label.text = interaction_text
	label.font_size = 32
	label.outline_size = 4
	label.outline_modulate = Color(0, 0, 0, 1)
	label.modulate = Color(1, 1, 0.5, 1)  # Yellow text
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 0, 0.01)  # Slightly in front of background
	add_child(label)

	# Start hidden
	hide()

func set_text(text: String) -> void:
	interaction_text = text
	if label:
		label.text = text
		# Adjust background size based on text length
		var text_width = text.length() * 0.15 + 0.5
		if background and background.mesh is QuadMesh:
			background.mesh.size = Vector2(text_width, 0.5)

func show_indicator() -> void:
	show()

func hide_indicator() -> void:
	hide()
