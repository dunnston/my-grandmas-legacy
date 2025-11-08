extends Area3D

# Stairs - Transition between bakery and apartment

signal stairs_activated(destination: String)

@export var destination_scene: String = ""  # Path to target scene
@export var prompt_text: String = "Go upstairs"

var player_nearby: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	if player_nearby and Input.is_action_just_pressed("interact"):
		activate()

func _on_body_entered(body: Node3D) -> void:
	if body.has_method("get_inventory_id"):
		player_nearby = true
		print("[E] to %s" % prompt_text)

func _on_body_exited(body: Node3D) -> void:
	if body.has_method("get_inventory_id"):
		player_nearby = false

func activate() -> void:
	if destination_scene != "":
		print("Transitioning to: %s" % destination_scene)
		stairs_activated.emit(destination_scene)
		# TODO: Implement scene transition via SceneManager
	else:
		print("No destination scene set for stairs!")
