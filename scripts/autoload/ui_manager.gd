extends Node

# UIManager - Singleton for managing UI quality of life features
# Handles hotkey responses, batch purchasing, confirmations, and UI polish

# Signals
signal quick_inventory_toggled(is_open: bool)
signal recipe_book_toggled(is_open: bool)
signal confirmation_requested(title: String, message: String, cost: float)
signal confirmation_result(accepted: bool)
signal tooltip_shown(text: String, position: Vector2)
signal tooltip_hidden()

# UI State
var quick_inventory_open: bool = false
var recipe_book_open: bool = false
var confirmation_dialog_open: bool = false

# Settings
var show_tooltips: bool = true
var confirm_expensive_purchases: bool = true
var expensive_threshold: float = 100.0  # Purchases over $100 require confirmation

func _ready() -> void:
	print("UIManager initialized")
	_setup_input_handlers()

func _setup_input_handlers() -> void:
	"""Set up input action listeners"""
	# Input actions are defined in project.godot
	print("UI hotkeys registered:")
	print("  Tab - Quick Inventory")
	print("  ESC - Pause Menu")
	print("  R - Recipe Book")
	print("  Space - Pause/Resume Time")
	print("  + - Speed Up Time")
	print("  - - Slow Down Time")

func _input(event: InputEvent) -> void:
	"""Handle global UI input"""

	# Quick Inventory (Tab)
	if event.is_action_pressed("quick_inventory"):
		toggle_quick_inventory()
		get_viewport().set_input_as_handled()

	# Recipe Book (R)
	if event.is_action_pressed("recipe_book"):
		toggle_recipe_book()
		get_viewport().set_input_as_handled()

	# Time control hotkeys
	if event.is_action_pressed("pause_time"):
		toggle_time_pause()
		get_viewport().set_input_as_handled()

	if event.is_action_pressed("speed_up_time"):
		increase_time_scale()
		get_viewport().set_input_as_handled()

	if event.is_action_pressed("slow_down_time"):
		decrease_time_scale()
		get_viewport().set_input_as_handled()

func toggle_quick_inventory() -> void:
	"""Toggle quick inventory display"""
	quick_inventory_open = !quick_inventory_open
	print("Quick Inventory: ", "OPEN" if quick_inventory_open else "CLOSED")
	quick_inventory_toggled.emit(quick_inventory_open)

func toggle_recipe_book() -> void:
	"""Toggle recipe book display"""
	recipe_book_open = !recipe_book_open
	print("Recipe Book: ", "OPEN" if recipe_book_open else "CLOSED")
	recipe_book_toggled.emit(recipe_book_open)

func toggle_time_pause() -> void:
	"""Pause/resume game time"""
	if GameManager:
		if GameManager.time_scale == 0.0:
			GameManager.set_time_scale(1.0)
			print("Time RESUMED (1x)")
		else:
			GameManager.set_time_scale(0.0)
			print("Time PAUSED")

func increase_time_scale() -> void:
	"""Increase time scale (1x -> 2x -> 3x)"""
	if GameManager:
		var current_scale: float = GameManager.time_scale
		if current_scale == 0.0:
			GameManager.set_time_scale(1.0)
			print("Time: 1x")
		elif current_scale < 1.0:
			GameManager.set_time_scale(1.0)
			print("Time: 1x")
		elif current_scale < 2.0:
			GameManager.set_time_scale(2.0)
			print("Time: 2x")
		elif current_scale < 3.0:
			GameManager.set_time_scale(3.0)
			print("Time: 3x (MAX)")
		else:
			print("Time: Already at maximum (3x)")

func decrease_time_scale() -> void:
	"""Decrease time scale (3x -> 2x -> 1x -> 0x)"""
	if GameManager:
		var current_scale: float = GameManager.time_scale
		if current_scale > 2.5:
			GameManager.set_time_scale(2.0)
			print("Time: 2x")
		elif current_scale > 1.5:
			GameManager.set_time_scale(1.0)
			print("Time: 1x")
		elif current_scale > 0.5:
			GameManager.set_time_scale(0.0)
			print("Time: PAUSED")
		else:
			print("Time: Already paused")

# Confirmation Dialog System
func request_confirmation(title: String, message: String, cost: float = 0.0) -> bool:
	"""Request user confirmation for an action
	Returns true if should proceed without confirmation
	Emits signal if confirmation needed"""

	# Skip confirmation if disabled or cost is low
	if not confirm_expensive_purchases or cost < expensive_threshold:
		return true

	# For now, just print and auto-confirm
	# In future, this will show a dialog and wait for user input
	print("\n=== CONFIRMATION REQUIRED ===")
	print("Title: %s" % title)
	print("Message: %s" % message)
	if cost > 0:
		print("Cost: $%.2f" % cost)
	print("Auto-confirming (UI not implemented yet)")
	print("=============================\n")

	confirmation_requested.emit(title, message, cost)
	return true

# Batch Purchasing Helper
func calculate_batch_purchase(ingredient_id: String, quantity: int) -> Dictionary:
	"""Calculate cost and availability for batch ingredient purchase"""
	var result: Dictionary = {
		"ingredient_id": ingredient_id,
		"quantity": quantity,
		"unit_price": 0.0,
		"total_cost": 0.0,
		"can_afford": false,
		"discount": 0.0
	}

	# Get ingredient price from EconomyManager
	if EconomyManager:
		result["unit_price"] = EconomyManager.get_ingredient_price(ingredient_id)
		result["total_cost"] = result["unit_price"] * quantity

		# Apply bulk discount for large orders (10+ items = 5% off, 25+ = 10% off)
		if quantity >= 25:
			result["discount"] = 0.10
		elif quantity >= 10:
			result["discount"] = 0.05

		if result["discount"] > 0:
			var discount_amount: float = result["total_cost"] * result["discount"]
			result["total_cost"] -= discount_amount
			print("Bulk discount applied: %.0f%% ($%.2f saved)" % [result["discount"] * 100, discount_amount])

		# Check if player can afford it
		result["can_afford"] = EconomyManager.get_current_cash() >= result["total_cost"]

	return result

func batch_purchase_ingredients(ingredient_id: String, quantity: int) -> bool:
	"""Purchase multiple units of an ingredient at once"""
	var calc: Dictionary = calculate_batch_purchase(ingredient_id, quantity)

	if not calc["can_afford"]:
		print("Cannot afford batch purchase: $%.2f needed, $%.2f available" %
			[calc["total_cost"], EconomyManager.get_current_cash()])
		return false

	# Request confirmation for expensive purchases
	var ingredient_name: String = ingredient_id.replace("_", " ").capitalize()
	var title: String = "Bulk Purchase"
	var message: String = "%d x %s for $%.2f?" % [quantity, ingredient_name, calc["total_cost"]]

	if not request_confirmation(title, message, calc["total_cost"]):
		print("Batch purchase cancelled by user")
		return false

	# Process purchase
	if EconomyManager and InventoryManager:
		EconomyManager.remove_money(calc["total_cost"], "Bulk purchase: %d x %s" % [quantity, ingredient_name])
		InventoryManager.add_to_player_inventory(ingredient_id, quantity)
		print("Purchased %d x %s for $%.2f" % [quantity, ingredient_name, calc["total_cost"]])
		return true

	return false

# Tooltip System
func show_tooltip(text: String, position: Vector2 = Vector2.ZERO) -> void:
	"""Show a tooltip at the given position"""
	if not show_tooltips:
		return

	tooltip_shown.emit(text, position)

func hide_tooltip() -> void:
	"""Hide the current tooltip"""
	tooltip_hidden.emit()

# UI Helper Functions
func format_currency(amount: float) -> String:
	"""Format currency for display"""
	return "$%.2f" % amount

func format_time(seconds: float) -> String:
	"""Format time in seconds to MM:SS"""
	var minutes: int = int(seconds) / 60
	var secs: int = int(seconds) % 60
	return "%02d:%02d" % [minutes, secs]

func format_percentage(value: float) -> String:
	"""Format percentage for display"""
	return "%.0f%%" % (value * 100)

func get_reputation_color(reputation: int) -> Color:
	"""Get color for reputation display"""
	if reputation >= 90:
		return Color(1.0, 0.84, 0.0)  # Gold
	elif reputation >= 75:
		return Color(0.0, 0.8, 0.0)   # Green
	elif reputation >= 60:
		return Color(0.6, 0.8, 0.4)   # Light green
	elif reputation >= 40:
		return Color(0.8, 0.8, 0.8)   # Gray
	elif reputation >= 25:
		return Color(0.9, 0.6, 0.0)   # Orange
	else:
		return Color(0.9, 0.1, 0.1)   # Red

func get_quality_color(quality: float) -> Color:
	"""Get color for quality display (0.0-1.0)"""
	if quality >= 0.95:
		return Color(1.0, 0.84, 0.0)  # Gold (Perfect/Legendary)
	elif quality >= 0.85:
		return Color(0.0, 0.8, 0.0)   # Green (Excellent)
	elif quality >= 0.70:
		return Color(0.6, 0.8, 0.4)   # Light green (Good)
	elif quality >= 0.50:
		return Color(0.8, 0.8, 0.8)   # Gray (Average)
	else:
		return Color(0.9, 0.6, 0.0)   # Orange (Below Average)

# Settings
func set_tooltips_enabled(enabled: bool) -> void:
	"""Enable or disable tooltips"""
	show_tooltips = enabled
	print("Tooltips: ", "ENABLED" if enabled else "DISABLED")

func set_confirmation_threshold(amount: float) -> void:
	"""Set the cost threshold for confirmation dialogs"""
	expensive_threshold = amount
	print("Confirmation threshold set to: $%.2f" % amount)

func enable_purchase_confirmations(enabled: bool) -> void:
	"""Enable or disable purchase confirmation dialogs"""
	confirm_expensive_purchases = enabled
	print("Purchase confirmations: ", "ENABLED" if enabled else "DISABLED")
