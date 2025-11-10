extends Sprite3D

# InteractPrompt - Shows "E" key icon above interactable objects
# Automatically shows/hides based on parent equipment's player_nearby state

@export var vertical_offset: float = 1.5  # How high above the object to display
@export var check_interval: float = 0.1  # How often to check player_nearby state (performance)

var parent_equipment: Node3D = null
var check_timer: float = 0.0

func _ready() -> void:
	# Find parent equipment node (should be the root of the equipment scene)
	parent_equipment = get_parent()

	# Set up sprite properties
	billboard = BaseMaterial3D.BILLBOARD_ENABLED  # Always face camera
	texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST  # Pixel-perfect rendering
	pixel_size = 0.01  # Size of each pixel in world units
	modulate = Color(1, 1, 1, 0.9)  # Slightly transparent

	# Start hidden
	visible = false

	# Position above parent
	position.y = vertical_offset

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
	if parent_equipment.has("player_nearby"):
		# Show prompt if player is nearby
		visible = parent_equipment.player_nearby != null
	else:
		visible = false
