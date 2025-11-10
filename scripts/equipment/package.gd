extends Node3D

# Package - Delivery package that player can interact with to retrieve ordered items
# Works like other equipment with InteractPrompt support

# Node references
@onready var interaction_area: Area3D = $InteractionArea
@onready var model: Node3D = $Model

# Player tracking (required for InteractPrompt to work)
var player_nearby: Node3D = null

func _ready() -> void:
	# Connect interaction area signals
	if interaction_area:
		interaction_area.body_entered.connect(_on_body_entered)
		interaction_area.body_exited.connect(_on_body_exited)

	# Register this package with DeliveryManager
	DeliveryManager.set_package_scene_reference(self)

	# Connect to package emptied signal
	DeliveryManager.package_emptied.connect(_on_package_emptied)

	print("Package spawned in scene")

func _on_body_entered(body: Node3D) -> void:
	"""Player entered interaction range"""
	if body.has_method("get_inventory_id"):
		player_nearby = body
		print("[E] to open Package")

func _on_body_exited(body: Node3D) -> void:
	"""Player left interaction range"""
	if body == player_nearby:
		player_nearby = null

func get_interaction_prompt() -> String:
	"""Return prompt text for this package"""
	return "[E] Open Package"

func interact(player: Node3D) -> void:
	"""Called when player presses E to interact"""
	if not DeliveryManager.is_package_available():
		print("Package is empty!")
		return

	# Open package UI
	var package_ui_scene = load("res://scenes/ui/package_ui.tscn")
	if package_ui_scene:
		var package_ui = package_ui_scene.instantiate()
		get_tree().root.add_child(package_ui)
		print("Package UI opened")

func _on_package_emptied() -> void:
	"""Package has been fully emptied - despawn"""
	print("Package emptied - despawning")

	# Remove from scene
	queue_free()
