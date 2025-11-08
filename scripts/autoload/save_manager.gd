extends Node

# SaveManager - Singleton for saving and loading game state
# Handles JSON persistence to user:// directory

# Signals
signal game_saved(slot: String)
signal game_loaded(slot: String)
signal save_failed(error: String)
signal load_failed(error: String)

# Constants
const SAVE_DIR: String = "user://saves/"
const SAVE_EXTENSION: String = ".json"
const DEFAULT_SAVE_SLOT: String = "autosave"
const MAX_SAVE_SLOTS: int = 5

# State
var current_save_slot: String = DEFAULT_SAVE_SLOT
var auto_save_enabled: bool = true

func _ready() -> void:
	print("SaveManager initialized")
	_ensure_save_directory_exists()

func _ensure_save_directory_exists() -> void:
	"""Create save directory if it doesn't exist"""
	var dir: DirAccess = DirAccess.open("user://")
	if dir and not dir.dir_exists("saves"):
		dir.make_dir("saves")
		print("Created saves directory")

func save_game(slot: String = DEFAULT_SAVE_SLOT) -> bool:
	"""Save current game state to specified slot"""
	print("\n=== SAVING GAME ===")
	print("Save slot: ", slot)

	var save_data: Dictionary = _collect_save_data()

	# Add metadata
	save_data["metadata"] = {
		"save_slot": slot,
		"save_time": Time.get_datetime_string_from_system(),
		"game_version": "0.4.0",  # Phase 4
		"day": GameManager.get_current_day(),
		"cash": EconomyManager.get_current_cash(),
		"reputation": ProgressionManager.get_reputation() if ProgressionManager else 50,
		"total_revenue": ProgressionManager.get_total_revenue() if ProgressionManager else 0.0
	}

	# Convert to JSON
	var json_string: String = JSON.stringify(save_data, "\t")

	# Write to file
	var file_path: String = _get_save_path(slot)
	var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)

	if not file:
		var error: String = "Failed to open save file: " + file_path
		push_error(error)
		save_failed.emit(error)
		return false

	file.store_string(json_string)
	file.close()

	current_save_slot = slot
	print("Game saved successfully to: ", file_path)
	print("===================\n")
	game_saved.emit(slot)
	return true

func load_game(slot: String = DEFAULT_SAVE_SLOT) -> bool:
	"""Load game state from specified slot"""
	print("\n=== LOADING GAME ===")
	print("Load slot: ", slot)

	var file_path: String = _get_save_path(slot)

	# Check if file exists
	if not FileAccess.file_exists(file_path):
		var error: String = "Save file not found: " + file_path
		push_warning(error)
		load_failed.emit(error)
		return false

	# Read file
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		var error: String = "Failed to open save file: " + file_path
		push_error(error)
		load_failed.emit(error)
		return false

	var json_string: String = file.get_as_text()
	file.close()

	# Parse JSON
	var json: JSON = JSON.new()
	var parse_result: Error = json.parse(json_string)

	if parse_result != OK:
		var error: String = "Failed to parse save file: " + json.get_error_message()
		push_error(error)
		load_failed.emit(error)
		return false

	var save_data: Dictionary = json.data

	# Apply save data to managers
	_apply_save_data(save_data)

	current_save_slot = slot
	print("Game loaded successfully from: ", file_path)
	print("====================\n")
	game_loaded.emit(slot)
	return true

func _collect_save_data() -> Dictionary:
	"""Collect save data from all game managers"""
	var data: Dictionary = {}

	# Game state
	data["game_manager"] = {
		"current_day": GameManager.get_current_day(),
		"current_phase": GameManager.get_current_phase(),
		"game_time": GameManager.game_time
	}

	# Economy
	data["economy_manager"] = EconomyManager.get_save_data()

	# Recipes
	data["recipe_manager"] = RecipeManager.get_save_data()

	# Customer stats
	data["customer_manager"] = CustomerManager.get_save_data()

	# Inventory (save all inventories)
	data["inventory_manager"] = InventoryManager.get_save_data()

	# Progression (milestones, reputation, unlocks)
	if ProgressionManager:
		data["progression_manager"] = ProgressionManager.get_save_data()

	# Story (letters read, narrative state)
	if StoryManager:
		data["story_manager"] = StoryManager.get_save_data()

	# Events (active events, completed events)
	if EventManager:
		data["event_manager"] = EventManager.get_save_data()

	# Marketing (campaigns, spending)
	if MarketingManager:
		data["marketing_manager"] = MarketingManager.get_save_data()

	print("Collected save data from all managers")
	return data

func _apply_save_data(data: Dictionary) -> void:
	"""Apply loaded save data to all game managers"""

	# Game state
	if data.has("game_manager"):
		var gm_data: Dictionary = data["game_manager"]
		if gm_data.has("current_day"):
			GameManager.current_day = gm_data["current_day"]
		if gm_data.has("current_phase"):
			GameManager.current_phase = gm_data["current_phase"]
		if gm_data.has("game_time"):
			GameManager.game_time = gm_data["game_time"]

	# Economy
	if data.has("economy_manager"):
		EconomyManager.load_save_data(data["economy_manager"])

	# Recipes
	if data.has("recipe_manager"):
		RecipeManager.load_save_data(data["recipe_manager"])

	# Customer stats
	if data.has("customer_manager"):
		CustomerManager.load_save_data(data["customer_manager"])

	# Inventory
	if data.has("inventory_manager"):
		InventoryManager.load_save_data(data["inventory_manager"])

	# Progression
	if data.has("progression_manager") and ProgressionManager:
		ProgressionManager.load_save_data(data["progression_manager"])

	# Story
	if data.has("story_manager") and StoryManager:
		StoryManager.load_save_data(data["story_manager"])

	# Events
	if data.has("event_manager") and EventManager:
		EventManager.load_save_data(data["event_manager"])

	# Marketing
	if data.has("marketing_manager") and MarketingManager:
		MarketingManager.load_save_data(data["marketing_manager"])

	print("Applied save data to all managers")

func auto_save() -> void:
	"""Perform automatic save"""
	if auto_save_enabled:
		print("Auto-saving...")
		save_game(DEFAULT_SAVE_SLOT)

func save_exists(slot: String) -> bool:
	"""Check if a save file exists for the given slot"""
	return FileAccess.file_exists(_get_save_path(slot))

func get_save_info(slot: String) -> Dictionary:
	"""Get metadata about a save file without fully loading it"""
	var file_path: String = _get_save_path(slot)

	if not FileAccess.file_exists(file_path):
		return {}

	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return {}

	var json_string: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	if json.parse(json_string) != OK:
		return {}

	var save_data: Dictionary = json.data
	return save_data.get("metadata", {})

func delete_save(slot: String) -> bool:
	"""Delete a save file"""
	var file_path: String = _get_save_path(slot)

	if not FileAccess.file_exists(file_path):
		return false

	var dir: DirAccess = DirAccess.open(SAVE_DIR)
	if dir:
		dir.remove(slot + SAVE_EXTENSION)
		print("Deleted save: ", slot)
		return true

	return false

func get_all_saves() -> Array[String]:
	"""Get list of all save slots"""
	var saves: Array[String] = []
	var dir: DirAccess = DirAccess.open(SAVE_DIR)

	if not dir:
		return saves

	dir.list_dir_begin()
	var file_name: String = dir.get_next()

	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(SAVE_EXTENSION):
			var slot_name: String = file_name.trim_suffix(SAVE_EXTENSION)
			saves.append(slot_name)
		file_name = dir.get_next()

	dir.list_dir_end()
	return saves

func _get_save_path(slot: String) -> String:
	"""Get full file path for a save slot"""
	return SAVE_DIR + slot + SAVE_EXTENSION

# Utility functions
func enable_auto_save(enabled: bool) -> void:
	"""Enable or disable auto-save"""
	auto_save_enabled = enabled
	print("Auto-save ", "enabled" if enabled else "disabled")

func get_current_slot() -> String:
	"""Get the currently active save slot"""
	return current_save_slot
