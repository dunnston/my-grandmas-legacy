extends CharacterBody3D

# Employee - Visual character controlled by AI scripts (BakerAI, CashierAI, CleanerAI)
# This is a simple container - NO AI logic here! AI is in separate scripts.

# Employee properties
var employee_id: String = ""
var employee_name: String = ""
var employee_role: String = ""  # "baker", "cashier", "cleaner"

# Node references
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
var animation_player: AnimationPlayer = null  # Found dynamically

func _ready() -> void:
	# Configure navigation agent
	if navigation_agent:
		navigation_agent.path_desired_distance = 0.5
		navigation_agent.target_desired_distance = 0.5
		navigation_agent.avoidance_enabled = true
		navigation_agent.radius = 0.5
		navigation_agent.height = 1.8

	# Randomly select and show one employee model (using customer models as placeholders)
	_select_random_employee_model()

func _select_random_employee_model() -> void:
	"""Show one random employee model from available models"""
	var models = []

	# Find all model nodes (CustomerModel1, CustomerModel2, etc.)
	for child in get_children():
		if child.name.begins_with("CustomerModel"):
			models.append(child)

	if models.is_empty():
		print("Employee: Warning - No employee models found!")
		return

	# Pick random model
	var selected_model = models[randi() % models.size()]
	selected_model.visible = true

	# Find and cache AnimationPlayer
	animation_player = _find_animation_player(selected_model)

	if animation_player and animation_player is AnimationPlayer:
		# Make sure AnimationPlayer is active (same as customer.gd)
		animation_player.active = true
		animation_player.process_mode = Node.PROCESS_MODE_INHERIT

		# Get the first animation
		var anims = animation_player.get_animation_list()
		if anims.size() > 0:
			var anim_name = anims[0]

			# Get the animation library and set loop mode
			var anim_lib = animation_player.get_animation_library("")
			if anim_lib and anim_lib.has_animation(anim_name):
				var animation = anim_lib.get_animation(anim_name)
				if animation:
					animation.loop_mode = Animation.LOOP_LINEAR

			# Play the animation immediately
			animation_player.play(anim_name)

			# Force update to ensure animation starts
			animation_player.advance(0.0)

			print("Employee: Animation started (", anim_name, ")")
		else:
			print("Employee: Warning - No animations found")
	else:
		print("Employee: Warning - Could not find AnimationPlayer")

func _find_animation_player(node: Node) -> AnimationPlayer:
	"""Recursively search for AnimationPlayer"""
	if node is AnimationPlayer:
		return node

	for child in node.get_children():
		if child is AnimationPlayer:
			return child

	for child in node.get_children():
		var result = _find_animation_player(child)
		if result:
			return result

	return null

# NO _process() or _physics_process() - AI scripts control this character!
