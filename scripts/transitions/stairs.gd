extends Area3D

# Stairs - Transition between bakery and apartment

signal stairs_activated(destination: String)

@export var destination_scene: String = ""  # Path to target scene
@export var prompt_text: String = "Go upstairs"

@onready var interact_prompt: Node3D = $InteractPrompt

var player_nearby: Node3D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# Hide prompt initially
	if interact_prompt:
		interact_prompt.visible = false

func _process(_delta: float) -> void:
	if player_nearby and Input.is_action_just_pressed("interact"):
		activate()

func _on_body_entered(body: Node3D) -> void:
	if body.has_method("get_inventory_id"):
		player_nearby = body
		update_prompt()
		print("[E] to %s" % prompt_text)

func _on_body_exited(body: Node3D) -> void:
	if body == player_nearby:
		player_nearby = null
		update_prompt()

func activate() -> void:
	if destination_scene != "":
		print("Transitioning to: %s" % destination_scene)
		stairs_activated.emit(destination_scene)

		# Use SceneManager to transition
		if SceneManager:
			SceneManager.transition_to_scene(destination_scene)
		else:
			push_error("SceneManager not found!")
	else:
		push_error("No destination scene set for stairs!")

func update_prompt() -> void:
	"""Update the interaction prompt visibility"""
	if interact_prompt:
		interact_prompt.visible = player_nearby != null

func get_interaction_prompt() -> String:
	"""Get the interaction prompt text"""
	return "[E] " + prompt_text
