extends Node3D

# Apartment - Player's living space above the bakery
# Contains bed (sleep/time skip), TV, bookshelf, grandma's photo

# Signals
signal player_rested(hours_skipped: int)
signal transition_to_bakery()
signal sleep_started()

# Node references
@onready var bed_interaction: Area3D = $Furniture/Bed/BedInteraction
@onready var tv_interaction: Area3D = $Furniture/TV/TVInteraction
@onready var bookshelf_interaction: Area3D = $Furniture/Bookshelf/BookshelfInteraction
@onready var photo_interaction: Area3D = $Furniture/GrandmaPhoto/PhotoInteraction
@onready var stairs_exit: Area3D = $StairsExit
@onready var sleep_controller: Node = $SleepController

var player_nearby_bed: bool = false
var player_nearby_tv: bool = false
var player_nearby_bookshelf: bool = false
var player_nearby_photo: bool = false
var player_nearby_stairs: bool = false

func _ready() -> void:
	# Connect interaction areas
	if bed_interaction:
		bed_interaction.body_entered.connect(_on_bed_entered)
		bed_interaction.body_exited.connect(_on_bed_exited)

	if tv_interaction:
		tv_interaction.body_entered.connect(_on_tv_entered)
		tv_interaction.body_exited.connect(_on_tv_exited)

	if bookshelf_interaction:
		bookshelf_interaction.body_entered.connect(_on_bookshelf_entered)
		bookshelf_interaction.body_exited.connect(_on_bookshelf_exited)

	if photo_interaction:
		photo_interaction.body_entered.connect(_on_photo_entered)
		photo_interaction.body_exited.connect(_on_photo_exited)

	if stairs_exit:
		stairs_exit.body_entered.connect(_on_stairs_entered)
		stairs_exit.body_exited.connect(_on_stairs_exited)

	# Connect sleep controller
	if sleep_controller:
		sleep_controller.sleep_sequence_complete.connect(_on_sleep_sequence_complete)

	print("Apartment scene loaded")

func _process(_delta: float) -> void:
	# Check for interactions
	if Input.is_action_just_pressed("interact"):
		if player_nearby_bed:
			interact_with_bed()
		elif player_nearby_tv:
			interact_with_tv()
		elif player_nearby_bookshelf:
			interact_with_bookshelf()
		elif player_nearby_photo:
			interact_with_photo()
		elif player_nearby_stairs:
			interact_with_stairs()

# Bed interactions
func _on_bed_entered(body: Node3D) -> void:
	if body.has_method("get_inventory_id"):
		player_nearby_bed = true
		print("[E] to rest and skip time")

func _on_bed_exited(body: Node3D) -> void:
	if body.has_method("get_inventory_id"):
		player_nearby_bed = false

func interact_with_bed() -> void:
	print("\n=== GOING TO SLEEP ===")
	print("You lie down on Grandma's comfortable bed...")

	# Start the sleep sequence with mini-game
	if sleep_controller:
		sleep_started.emit()
		sleep_controller.start_sleep_sequence()
	else:
		push_error("SleepController not found!")

# TV interactions
func _on_tv_entered(body: Node3D) -> void:
	if body.has_method("get_inventory_id"):
		player_nearby_tv = true
		print("[E] to watch TV")

func _on_tv_exited(body: Node3D) -> void:
	if body.has_method("get_inventory_id"):
		player_nearby_tv = false

func interact_with_tv() -> void:
	print("\n=== TV ===")
	print("You watch some relaxing cooking shows.")
	print("Grandma always loved these...")

	# Random cooking tips and hints
	var tips = [
		"The host emphasizes the importance of timing in baking. Quality depends on precision!",
		"A chef demonstrates equipment maintenance. Upgraded equipment really does make a difference!",
		"The show features customer testimonials. People love personalized service!",
		"They discuss seasonal ingredients and how freshness affects the final product.",
		"A segment on legendary bakers who perfected their craft through dedication."
	]

	print("\n📺 ", tips.pick_random())
	print("\nYou feel inspired and relaxed.")

	# Small reputation boost for taking time to learn
	if ProgressionManager.has_method("add_reputation"):
		ProgressionManager.add_reputation(2.0)
		print("+2 Reputation (learned something new)")

# Bookshelf interactions
func _on_bookshelf_entered(body: Node3D) -> void:
	if body.has_method("get_inventory_id"):
		player_nearby_bookshelf = true
		print("[E] to browse books")

func _on_bookshelf_exited(body: Node3D) -> void:
	if body.has_method("get_inventory_id"):
		player_nearby_bookshelf = false

func interact_with_bookshelf() -> void:
	print("\n=== BOOKSHELF ===")
	print("Grandma's collection of cookbooks and novels.")
	print("You find old recipe notes tucked between pages...")

	# Random recipe hints
	var hints = [
		"A handwritten note: 'Don't rush the rise! Bread needs time and patience.'",
		"A bookmark in 'French Pastries': 'Butter temperature is EVERYTHING for croissants!'",
		"Grandma's diary: 'Legendary bakes require legendary ingredients... and a bit of luck.'",
		"A recipe card falls out: 'Quality over quantity, dear. Better to make one perfect item than many mediocre ones.'",
		"An old letter: 'Your reputation in this town is built one customer at a time. Make them smile!'"
	]

	print("\n📖 ", hints.pick_random())
	print("\nYou feel connected to Grandma's wisdom.")

	# Recipe hint - show one locked recipe
	var unlocked = RecipeManager.get_all_unlocked_recipes()
	var total_recipes = RecipeManager.get_all_recipes().size()

	if unlocked.size() < total_recipes:
		print("\n💡 Hint: You have %d/%d recipes unlocked. Keep growing the business to unlock more!" % [unlocked.size(), total_recipes])

# Photo interactions
func _on_photo_entered(body: Node3D) -> void:
	if body.has_method("get_inventory_id"):
		player_nearby_photo = true
		print("[E] to view photo")

func _on_photo_exited(body: Node3D) -> void:
	if body.has_method("get_inventory_id"):
		player_nearby_photo = false

func interact_with_photo() -> void:
	print("\n=== GRANDMA'S PHOTO ===")
	print("A warm photo of your grandmother in her bakery.")
	print("She's smiling, flour on her apron, a tray of fresh bread in hand.")
	print("'I'm so proud of you' - you can almost hear her say.")
	print("\nYou feel motivated to continue her legacy.")

	# Check current progress
	var total_revenue = ProgressionManager.total_revenue if ProgressionManager.has_method("get_total_revenue") else 0.0
	var reputation = ProgressionManager.reputation if ProgressionManager.has_method("get_reputation") else 50.0
	var day = ProgressionManager.current_day if ProgressionManager.has_method("get_current_day") else 1

	print("\n💭 Current Progress:")
	print("   Day %d" % day)
	print("   Total Revenue: $%.2f" % total_revenue)
	print("   Reputation: %.0f%%" % reputation)

	# Motivational message based on progress
	if total_revenue >= 50000:
		print("\n✨ 'You've surpassed even my wildest dreams, dear. The bakery has never shone brighter!'")
	elif total_revenue >= 25000:
		print("\n✨ 'The whole town is talking about your baking! I knew you had it in you.'")
	elif total_revenue >= 10000:
		print("\n✨ 'You're really getting the hang of this! Keep going, I'm so proud.'")
	elif total_revenue >= 5000:
		print("\n✨ 'Every day you're getting better. Remember, it's about the journey!'")
	else:
		print("\n✨ 'Everyone starts somewhere, dear. Just keep baking with love!'")

	# Small morale boost
	if ProgressionManager.has_method("add_reputation"):
		ProgressionManager.add_reputation(3.0)
		print("\n+3 Reputation (renewed motivation)")

# Stairs interactions
func _on_stairs_entered(body: Node3D) -> void:
	if body.has_method("get_inventory_id"):
		player_nearby_stairs = true
		print("[E] to go downstairs to bakery")

func _on_stairs_exited(body: Node3D) -> void:
	if body.has_method("get_inventory_id"):
		player_nearby_stairs = false

func interact_with_stairs() -> void:
	print("Going downstairs to the bakery...")
	transition_to_bakery.emit()
	SceneManager.go_to_bakery()

# Sleep sequence callbacks
func _on_sleep_sequence_complete() -> void:
	"""Called when sleep sequence is fully complete"""
	print("[Apartment] Sleep sequence complete - player wakes up")

	# Check for active buffs
	var buff_info = SleepManager.get_active_buff()
	if buff_info.active:
		print("Morning buff active: %s %s" % [buff_info.icon, buff_info.name])

	# Re-enable player control
	var player = get_tree().get_first_node_in_group("player")
	if player:
		print("[Apartment] Re-enabling player control")
		# Make sure player input is enabled
		if player.has_method("set_process_input"):
			player.set_process_input(true)
		if player.has_method("set_physics_process"):
			player.set_physics_process(true)
		if player.has_method("set_process"):
			player.set_process(true)
	else:
		print("[Apartment] Warning: Could not find player node!")

	# Player can now move around apartment
	# Could show a wake-up message here

# Helper functions
func skip_time(hours: int) -> void:
	"""Skip forward in time (for rest/sleep) - DEPRECATED, use sleep system"""
	print("Skipping %d hours..." % hours)
	player_rested.emit(hours)
