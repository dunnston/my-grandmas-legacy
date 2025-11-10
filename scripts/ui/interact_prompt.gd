extends Sprite3D

# InteractPrompt - Shows "E" key icon above interactable objects
# Automatically shows/hides based on parent equipment's player_nearby state

@export var vertical_offset: float = 2.0  # How high above the object to display
@export var check_interval: float = 0.1  # How often to check player_nearby state (performance)
@export var icon_pixel_size: float = 0.001  # Size of each pixel in world units (smaller = smaller icon)

var parent_equipment: Node3D = null
var check_timer: float = 0.0

func _ready() -> void:
	# Find parent equipment node (should be the root of the equipment scene)
	parent_equipment = get_parent()

	# Set up sprite properties
	billboard = BaseMaterial3D.BILLBOARD_ENABLED  # Always face camera
	texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST  # Pixel-perfect rendering
	pixel_size = icon_pixel_size  # Size of each pixel in world units
	modulate = Color(1, 1, 1, 0.9)  # Slightly transparent

	# Start hidden
	visible = false

	# Position above parent
	position.y = vertical_offset

	# IMPORTANT: Cancel out parent's scale to maintain consistent prompt size
	# If parent is scaled 2x, we scale prompt 0.5x to cancel it out
	if parent_equipment:
		var parent_scale = parent_equipment.scale
		scale = Vector3(
			1.0 / parent_scale.x if parent_scale.x != 0 else 1.0,
			1.0 / parent_scale.y if parent_scale.y != 0 else 1.0,
			1.0 / parent_scale.z if parent_scale.z != 0 else 1.0
		)

	print("[InteractPrompt] Ready for: ", parent_equipment.name if parent_equipment else "Unknown")

func _process(delta: float) -> void:
	# Only check periodically for performance
	check_timer += delta
	if check_timer >= check_interval:
		check_timer = 0.0
		update_visibility()

func update_visibility() -> void:
	if not parent_equipment:
		visible = false
		return

	# Check if parent equipment has player_nearby variable
	if "player_nearby" in parent_equipment:
		# Show prompt if player is nearby
		visible = parent_equipment.player_nearby != null
	else:
		visible = false
