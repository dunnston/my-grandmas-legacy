extends Node

# SceneManager - Handles scene transitions between bakery and apartment
# Singleton autoload for managing scene changes

signal scene_transition_started(from_scene: String, to_scene: String)
signal scene_transition_completed(scene_name: String)

var current_scene: Node = null
var current_scene_path: String = ""

# Scene paths
const BAKERY_SCENE: String = "res://scenes/bakery/bakery.tscn"
const APARTMENT_SCENE: String = "res://scenes/apartment/apartment.tscn"

func _ready() -> void:
	# Get initial scene
	var root: Window = get_tree().root
	current_scene = root.get_child(root.get_child_count() - 1)
	print("SceneManager initialized")

func transition_to_scene(scene_path: String) -> void:
	"""Transition to a new scene"""
	if scene_path == current_scene_path:
		print("Already in scene: ", scene_path)
		return

	scene_transition_started.emit(current_scene_path, scene_path)
	print("Transitioning from %s to %s" % [current_scene_path, scene_path])

	# Call deferred to avoid issues with signals
	call_deferred("_deferred_scene_change", scene_path)

func _deferred_scene_change(scene_path: String) -> void:
	"""Perform the actual scene change"""
	# Free current scene
	if current_scene:
		current_scene.free()

	# Load and instance new scene
	var new_scene_resource: PackedScene = load(scene_path)
	if new_scene_resource:
		current_scene = new_scene_resource.instantiate()
		get_tree().root.add_child(current_scene)
		get_tree().current_scene = current_scene
		current_scene_path = scene_path

		scene_transition_completed.emit(scene_path)
		print("Scene transition completed: ", scene_path)
	else:
		print("Error: Could not load scene: ", scene_path)

func go_to_bakery() -> void:
	"""Convenience function to go to bakery"""
	transition_to_scene(BAKERY_SCENE)

func go_to_apartment() -> void:
	"""Convenience function to go to apartment"""
	transition_to_scene(APARTMENT_SCENE)

func get_current_scene_name() -> String:
	"""Get the name of the current scene"""
	if current_scene:
		return current_scene.name
	return ""
