extends Node3D

# Sink - Station for getting water and washing dishes

signal water_collected()
signal dishes_washed()
signal dish_spawned(dish_type: String)
signal sink_full()

@export var fill_time: float = 3.0  # 3 seconds to fill water
@export var wash_time: float = 3.0  # 3 seconds to wash one dish
@export var dish_spawn_interval: float = 60.0  # Spawn a dish every 60 seconds (in-game time)
@export var max_dishes: int = 10  # Maximum dishes before sink is "full"

# Node references
@onready var interaction_area: Area3D = $InteractionArea
@onready var progress_bar_container: Node3D = $ProgressBarContainer
@onready var progress_bar: ProgressBar = $ProgressBarContainer/SubViewport/ProgressBar
@onready var interact_prompt: Node3D = $InteractPrompt
@onready var dirty_dishes_container: Node3D = $DirtyDishesContainer
@onready var mode_label: Label3D = $ModeLabel

# State
enum SinkState { IDLE, FILLING_WATER, WASHING_DISHES }
enum SinkMode { GET_WATER, WASH_DISHES }
var current_state: SinkState = SinkState.IDLE
var current_mode: SinkMode = SinkMode.GET_WATER
var fill_timer: float = 0.0
var wash_timer: float = 0.0
var player_nearby: Node3D = null
var is_filling: bool = false  # Keep for compatibility

# Dirty dishes system
var dish_spawn_timer: float = 0.0
var spawned_dishes: Array[Node3D] = []
var dish_types: Array[String] = ["plate", "cup", "fork", "baking_sheet"]

func _ready() -> void:
	# Connect interaction area
	if interaction_area:
		interaction_area.body_entered.connect(_on_body_entered)
		interaction_area.body_exited.connect(_on_body_exited)

	# Hide progress bar initially
	if progress_bar_container:
		progress_bar_container.visible = false

	# Hide prompt initially
	if interact_prompt:
		interact_prompt.visible = false

	# Hide mode label initially
	if mode_label:
		mode_label.visible = false

	print("Sink ready: ", name)

func _input(event: InputEvent) -> void:
	# Handle mode toggle (F key)
	if player_nearby and event is InputEventKey:
		if event.keycode == KEY_F and event.pressed and not event.echo:
			toggle_mode()

func _process(delta: float) -> void:
	if GameManager.is_game_paused():
		return

	var scaled_delta = delta * GameManager.get_time_scale()

	# Handle dirty dish spawning
	if spawned_dishes.size() < max_dishes:
		dish_spawn_timer += scaled_delta
		if dish_spawn_timer >= dish_spawn_interval:
			spawn_dirty_dish()
			dish_spawn_timer = 0.0

	match current_state:
		SinkState.IDLE:
			# Wait for player to hold E
			if player_nearby and Input.is_action_pressed("interact"):
				if current_mode == SinkMode.GET_WATER:
					start_filling_water()
				elif current_mode == SinkMode.WASH_DISHES:
					if spawned_dishes.size() > 0:
						start_washing_dish()

		SinkState.FILLING_WATER:
			# Player is actively filling water
			if player_nearby and Input.is_action_pressed("interact"):
				# Continue filling
				fill_timer += delta  # Use real delta, not scaled (player action)

				# Update progress bar
				if progress_bar:
					var progress_percent = (fill_timer / fill_time) * 100.0
					progress_bar.value = progress_percent

				if fill_timer >= fill_time:
					complete_filling_water()
			else:
				# Player released E or walked away - cancel filling
				stop_filling_water()

		SinkState.WASHING_DISHES:
			# Player is actively washing a dish
			if player_nearby and Input.is_action_pressed("interact"):
				# Continue washing
				wash_timer += delta  # Use real delta, not scaled (player action)

				# Update progress bar
				if progress_bar:
					var progress_percent = (wash_timer / wash_time) * 100.0
					progress_bar.value = progress_percent

				if wash_timer >= wash_time:
					complete_washing_dish()
			else:
				# Player released E or walked away - cancel washing
				stop_washing_dish()

func _on_body_entered(body: Node3D) -> void:
	if body.has_method("get_inventory_id"):
		player_nearby = body
		update_prompt()

func _on_body_exited(body: Node3D) -> void:
	if body == player_nearby:
		player_nearby = null
		is_filling = false
		update_prompt()

		# Hide progress bar if player leaves
		if progress_bar_container:
			progress_bar_container.visible = false
		fill_timer = 0.0

func get_interaction_prompt() -> String:
	if current_mode == SinkMode.GET_WATER:
		return "[Hold E] Get water | [Q] Switch to wash dishes"
	else:  # WASH_DISHES mode
		if spawned_dishes.size() > 0:
			return "[Hold E] Wash dish (%d left) | [Q] Switch to get water" % spawned_dishes.size()
		else:
			return "No dirty dishes | [Q] Switch to get water"

func interact(player: Node3D) -> void:
	"""Called when player presses E - now handled by holding E in _process"""
	# Note: Hold-to-interact is now handled in _process function
	# This is kept for compatibility but the main interaction is hold-based
	pass

func start_filling_water() -> void:
	"""Player started holding E to fill water"""
	current_state = SinkState.FILLING_WATER
	is_filling = true

	# Show progress bar
	if progress_bar_container:
		progress_bar_container.visible = true
	if progress_bar:
		progress_bar.value = 0.0

	print("[Sink] Player started filling water...")

func stop_filling_water() -> void:
	"""Player released E before completing"""
	if current_state == SinkState.FILLING_WATER:
		current_state = SinkState.IDLE
		is_filling = false
		fill_timer = 0.0

		# Hide progress bar
		if progress_bar_container:
			progress_bar_container.visible = false
		if progress_bar:
			progress_bar.value = 0.0

		print("[Sink] Player stopped filling water")

func complete_filling_water() -> void:
	"""Player has successfully filled water"""
	print("✓ Water collected!")

	# Add water to player inventory
	if player_nearby:
		InventoryManager.add_item("player", "water", 1)
		print("  +1 Water added to inventory")

	water_collected.emit()

	# Reset state
	current_state = SinkState.IDLE
	is_filling = false
	fill_timer = 0.0

	# Hide progress bar
	if progress_bar_container:
		progress_bar_container.visible = false
	if progress_bar:
		progress_bar.value = 0.0

func toggle_mode() -> void:
	"""Toggle between Get Water and Wash Dishes modes"""
	if current_mode == SinkMode.GET_WATER:
		current_mode = SinkMode.WASH_DISHES
		print("[Sink] Switched to WASH DISHES mode")
	else:
		current_mode = SinkMode.GET_WATER
		print("[Sink] Switched to GET WATER mode")

	update_mode_label()
	update_prompt()

func start_washing_dish() -> void:
	"""Player started holding E to wash a dish"""
	if spawned_dishes.size() == 0:
		print("[Sink] No dishes to wash!")
		return

	current_state = SinkState.WASHING_DISHES
	wash_timer = 0.0

	# Show progress bar
	if progress_bar_container:
		progress_bar_container.visible = true
	if progress_bar:
		progress_bar.value = 0.0

	print("[Sink] Player started washing dish... (%d dishes remaining)" % spawned_dishes.size())

func stop_washing_dish() -> void:
	"""Player released E before completing"""
	if current_state == SinkState.WASHING_DISHES:
		current_state = SinkState.IDLE
		wash_timer = 0.0

		# Hide progress bar
		if progress_bar_container:
			progress_bar_container.visible = false
		if progress_bar:
			progress_bar.value = 0.0

		print("[Sink] Player stopped washing dish")

func complete_washing_dish() -> void:
	"""Player has successfully washed a dish"""
	if spawned_dishes.size() == 0:
		print("[Sink] No dishes to wash!")
		return

	# Remove the oldest dish (FIFO - first in, first out)
	var dish_to_remove = spawned_dishes[0]
	spawned_dishes.erase(dish_to_remove)

	if is_instance_valid(dish_to_remove):
		dish_to_remove.queue_free()

	print("✓ Dish washed! (%d dishes remaining)" % spawned_dishes.size())
	dishes_washed.emit()

	# Reset state
	current_state = SinkState.IDLE
	wash_timer = 0.0

	# Hide progress bar
	if progress_bar_container:
		progress_bar_container.visible = false
	if progress_bar:
		progress_bar.value = 0.0

	update_prompt()

func update_prompt() -> void:
	"""Update the interaction prompt based on state"""
	if not player_nearby:
		if interact_prompt:
			interact_prompt.visible = false
		if mode_label:
			mode_label.visible = false
		return

	if current_state == SinkState.IDLE or current_state == SinkState.FILLING_WATER or current_state == SinkState.WASHING_DISHES:
		if interact_prompt:
			interact_prompt.visible = true
		update_mode_label()
	else:
		if interact_prompt:
			interact_prompt.visible = false
		if mode_label:
			mode_label.visible = false

func update_mode_label() -> void:
	"""Update the mode label text"""
	if not mode_label:
		return

	if not player_nearby:
		mode_label.visible = false
		return

	mode_label.visible = true

	if current_mode == SinkMode.GET_WATER:
		# Currently in GET_WATER mode - can switch to WASH_DISHES
		mode_label.text = "[Hold E] Fill water\n[F] Switch to wash dishes"
		mode_label.modulate = Color(0.5, 0.8, 1.0)  # Light blue
	else:  # WASH_DISHES mode
		# Currently in WASH_DISHES mode - can switch to GET_WATER
		if spawned_dishes.size() > 0:
			mode_label.text = "[Hold E] Wash (%d left)\n[F] Switch to get water" % spawned_dishes.size()
			mode_label.modulate = Color(1.0, 0.8, 0.5)  # Orange/yellow
		else:
			mode_label.text = "No dirty dishes\n[F] Switch to get water"
			mode_label.modulate = Color(0.7, 0.7, 0.7)  # Gray

func get_progress() -> float:
	"""Get filling progress (for UI/automation)"""
	if not is_filling:
		return 0.0
	return fill_timer / fill_time

# ============================================================================
# DIRTY DISH SPAWNING SYSTEM
# ============================================================================

func spawn_dirty_dish() -> void:
	"""Spawn a random dirty dish in the sink"""
	if spawned_dishes.size() >= max_dishes:
		print("[Sink] Sink is full! Cannot spawn more dishes.")
		sink_full.emit()
		return

	# Pick a random dish type
	var dish_type: String = dish_types.pick_random()

	# Create the dish mesh
	var dish: Node3D = create_dish_placeholder(dish_type)

	# Position the dish in the sink (stacked/scattered)
	var spawn_position: Vector3 = get_dish_spawn_position()
	dish.position = spawn_position

	# Add random rotation for variety
	dish.rotation_degrees.y = randf_range(0, 360)

	# Add to scene
	if dirty_dishes_container:
		dirty_dishes_container.add_child(dish)
		spawned_dishes.append(dish)

		print("[Sink] Spawned dirty %s (%d/%d dishes)" % [dish_type, spawned_dishes.size(), max_dishes])
		dish_spawned.emit(dish_type)

		# Update mode label to show new dish count
		if player_nearby and current_mode == SinkMode.WASH_DISHES:
			update_mode_label()

		if spawned_dishes.size() >= max_dishes:
			print("[Sink] ⚠️ Sink is now FULL!")
			sink_full.emit()

func create_dish_placeholder(dish_type: String) -> Node3D:
	"""Create a CSG placeholder for a dish"""
	var container = Node3D.new()
	container.name = "Dirty_" + dish_type

	var mesh: CSGPrimitive3D = null

	match dish_type:
		"plate":
			# Flat cylinder for plate
			mesh = CSGCylinder3D.new()
			mesh.radius = 0.15
			mesh.height = 0.02
			mesh.material = create_dish_material(Color(0.9, 0.9, 0.85))  # Off-white

		"cup":
			# Cylinder for cup
			mesh = CSGCylinder3D.new()
			mesh.radius = 0.06
			mesh.height = 0.12
			mesh.material = create_dish_material(Color(0.8, 0.85, 0.9))  # Light blue

		"fork":
			# Small box for fork
			mesh = CSGBox3D.new()
			mesh.size = Vector3(0.03, 0.02, 0.18)
			mesh.material = create_dish_material(Color(0.7, 0.7, 0.7))  # Silver

		"baking_sheet":
			# Flat box for baking sheet
			mesh = CSGBox3D.new()
			mesh.size = Vector3(0.3, 0.02, 0.4)
			mesh.material = create_dish_material(Color(0.3, 0.3, 0.35))  # Dark metal

	if mesh:
		container.add_child(mesh)

	return container

func create_dish_material(base_color: Color) -> StandardMaterial3D:
	"""Create a material for dirty dishes"""
	var mat = StandardMaterial3D.new()
	mat.albedo_color = base_color.darkened(0.3)  # Make it look dirty
	mat.metallic = 0.2
	mat.roughness = 0.8
	return mat

func get_dish_spawn_position() -> Vector3:
	"""Get a spawn position for a new dish"""
	# Get all spawn point markers
	var spawn_points: Array[Node] = []
	if dirty_dishes_container:
		for child in dirty_dishes_container.get_children():
			if child is Marker3D:
				spawn_points.append(child)

	# If we have spawn markers, use them
	if spawn_points.size() > 0:
		# Pick a random spawn point
		var marker: Marker3D = spawn_points.pick_random()

		# Add slight random offset for variety
		var random_offset = Vector3(
			randf_range(-0.05, 0.05),
			randf_range(-0.02, 0.02),
			randf_range(-0.05, 0.05)
		)

		return marker.position + random_offset
	else:
		# Fallback: Stack dishes with slight random offset (old method)
		var stack_height = spawned_dishes.size() * 0.03
		var random_offset = Vector2(randf_range(-0.1, 0.1), randf_range(-0.1, 0.1))
		return Vector3(random_offset.x, 0.5 + stack_height, random_offset.y)

func clear_all_dishes() -> void:
	"""Remove all dirty dishes from the sink"""
	for dish in spawned_dishes:
		if is_instance_valid(dish):
			dish.queue_free()

	spawned_dishes.clear()
	dish_spawn_timer = 0.0
	print("[Sink] All dishes cleared!")

func get_dish_count() -> int:
	"""Get the current number of dirty dishes"""
	return spawned_dishes.size()

func is_sink_full() -> bool:
	"""Check if sink is full"""
	return spawned_dishes.size() >= max_dishes

# ============================================================================
# DEBUG HELPERS
# ============================================================================

func force_spawn_dish() -> void:
	"""Debug: Force spawn a dish immediately"""
	spawn_dirty_dish()

func force_fill_sink() -> void:
	"""Debug: Fill sink to max capacity immediately"""
	while spawned_dishes.size() < max_dishes:
		spawn_dirty_dish()

# ============================================================================
# AUTOMATION METHODS (for staff AI)
# ============================================================================

func can_collect_water() -> bool:
	"""Check if water can be collected"""
	return current_state == SinkState.IDLE

func auto_collect_water(amount: int = 1) -> bool:
	"""Collect water automatically (called by staff AI)"""
	if not can_collect_water():
		return false

	# Instant completion for AI
	print("[Sink] Auto-collected %d water" % amount)
	water_collected.emit()
	return true
