extends Node3D

# Apartment - Player's living space above the bakery
# Contains bed (sleep/time skip), TV, bookshelf, grandma's photo

# Signals
signal player_rested(hours_skipped: int)
signal transition_to_bakery()

# Node references
@onready var bed_interaction: Area3D = $Furniture/Bed/BedInteraction
@onready var tv_interaction: Area3D = $Furniture/TV/TVInteraction
@onready var bookshelf_interaction: Area3D = $Furniture/Bookshelf/BookshelfInteraction
@onready var photo_interaction: Area3D = $Furniture/GrandmaPhoto/PhotoInteraction
@onready var stairs_exit: Area3D = $StairsExit

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
	print("\n=== REST ===")
	print("Skip ahead in time?")
	print("1. Skip 1 hour")
	print("2. Skip to next morning")
	print("3. Cancel")
	print("\nThis is a placeholder - UI needed for time skip options")
	# TODO: Implement rest UI dialog

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
	# TODO: Add small reputation boost or recipe hints

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
	# TODO: Could unlock recipe hints or lore

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
	# TODO: Add small morale boost or show story dialog

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

# Helper functions
func skip_time(hours: int) -> void:
	"""Skip forward in time (for rest/sleep)"""
	print("Skipping %d hours..." % hours)
	player_rested.emit(hours)
	# TODO: Integrate with GameManager time system
