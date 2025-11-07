extends Control

# DevMenu - Developer/Debug menu for testing game systems
# Press ` (backtick) to toggle

# UI Sections
@onready var main_panel: PanelContainer = $PanelContainer
@onready var tab_container: TabContainer = $PanelContainer/MarginContainer/VBoxContainer/TabContainer

# Economy tab
@onready var cash_label: Label = $PanelContainer/MarginContainer/VBoxContainer/TabContainer/Economy/VBoxContainer/CashLabel
@onready var set_cash_input: SpinBox = $PanelContainer/MarginContainer/VBoxContainer/TabContainer/Economy/VBoxContainer/SetCash/SpinBox

# Inventory tab - will populate dynamically
@onready var ingredients_grid: GridContainer = $PanelContainer/MarginContainer/VBoxContainer/TabContainer/Inventory/ScrollContainer/VBoxContainer/Ingredients/GridContainer
@onready var products_grid: GridContainer = $PanelContainer/MarginContainer/VBoxContainer/TabContainer/Inventory/ScrollContainer/VBoxContainer/Products/GridContainer

# Customer tab
@onready var spawn_count_input: SpinBox = $PanelContainer/MarginContainer/VBoxContainer/TabContainer/Customers/VBoxContainer/SpawnMultiple/SpinBox
@onready var active_customers_label: Label = $PanelContainer/MarginContainer/VBoxContainer/TabContainer/Customers/VBoxContainer/ActiveCustomersLabel

# Time tab
@onready var current_phase_label: Label = $PanelContainer/MarginContainer/VBoxContainer/TabContainer/Time/VBoxContainer/CurrentPhaseLabel
@onready var current_day_label: Label = $PanelContainer/MarginContainer/VBoxContainer/TabContainer/Time/VBoxContainer/CurrentDayLabel
@onready var time_scale_label: Label = $PanelContainer/MarginContainer/VBoxContainer/TabContainer/Time/VBoxContainer/TimeScaleLabel
@onready var set_day_input: SpinBox = $PanelContainer/MarginContainer/VBoxContainer/TabContainer/Time/VBoxContainer/SetDay/SpinBox

# All available items
var all_ingredients: Array[String] = ["flour", "sugar", "eggs", "butter", "milk", "yeast", "chocolate_chips", "blueberries", "vanilla", "salt"]
var all_products: Array[String] = ["white_bread", "chocolate_chip_cookies", "blueberry_muffins"]

func _ready() -> void:
	# Start hidden
	hide()

	# Populate inventory buttons
	_populate_inventory_buttons()

	# Connect economy signals
	EconomyManager.money_changed.connect(_update_cash_display)
	GameManager.phase_changed.connect(_update_phase_display)
	GameManager.day_changed.connect(_update_day_display)
	GameManager.time_scale_changed.connect(_update_time_scale_display)

	# Initial display update
	_update_cash_display(EconomyManager.current_cash)
	_update_phase_display(GameManager.current_phase)
	_update_day_display(GameManager.current_day)
	_update_time_scale_display(GameManager.time_scale)

	print("DevMenu initialized - Press ` to toggle")

func _input(event: InputEvent) -> void:
	# Toggle with backtick key
	if event is InputEventKey and event.pressed and event.keycode == KEY_QUOTELEFT:
		toggle_menu()
		get_viewport().set_input_as_handled()

func toggle_menu() -> void:
	visible = !visible

	if visible:
		# Pause game when menu opens
		GameManager.pause_game()
		# Update all displays
		_update_all_displays()
		print("DevMenu opened")
	else:
		# Resume game when menu closes
		GameManager.resume_game()
		print("DevMenu closed")

func _update_all_displays() -> void:
	_update_cash_display(EconomyManager.current_cash)
	_update_phase_display(GameManager.current_phase)
	_update_day_display(GameManager.current_day)
	_update_time_scale_display(GameManager.time_scale)
	_update_customer_count()

func _populate_inventory_buttons() -> void:
	# Clear existing buttons
	for child in ingredients_grid.get_children():
		child.queue_free()
	for child in products_grid.get_children():
		child.queue_free()

	# Create ingredient buttons
	for ingredient in all_ingredients:
		var button := Button.new()
		button.text = ingredient.capitalize() + " x10"
		button.pressed.connect(_add_ingredient.bind(ingredient, 10))
		ingredients_grid.add_child(button)

	# Create product buttons
	for product in all_products:
		var button := Button.new()
		var recipe = RecipeManager.get_recipe(product)
		var display_name = recipe.get("name", product.capitalize())
		button.text = display_name + " x5"
		button.pressed.connect(_add_product.bind(product, 5))
		products_grid.add_child(button)

# ============================================================================
# ECONOMY FUNCTIONS
# ============================================================================

func _update_cash_display(amount: float) -> void:
	if cash_label:
		cash_label.text = "Current Cash: $%.2f" % amount

func _on_add_100_pressed() -> void:
	EconomyManager.add_money(100.0, "[DEV] Added $100")

func _on_add_500_pressed() -> void:
	EconomyManager.add_money(500.0, "[DEV] Added $500")

func _on_add_1000_pressed() -> void:
	EconomyManager.add_money(1000.0, "[DEV] Added $1000")

func _on_set_cash_pressed() -> void:
	var target_cash: float = set_cash_input.value
	var current_cash: float = EconomyManager.current_cash
	var difference: float = target_cash - current_cash

	if difference > 0:
		EconomyManager.add_money(difference, "[DEV] Set cash to $%.2f" % target_cash)
	elif difference < 0:
		EconomyManager.remove_money(abs(difference), "[DEV] Set cash to $%.2f" % target_cash)

# ============================================================================
# INVENTORY FUNCTIONS
# ============================================================================

func _add_ingredient(ingredient_id: String, quantity: int) -> void:
	InventoryManager.add_item("player", ingredient_id, quantity)
	print("[DEV] Added %d x %s to player inventory" % [quantity, ingredient_id])

func _add_product(product_id: String, quantity: int) -> void:
	InventoryManager.add_item("player", product_id, quantity)
	print("[DEV] Added %d x %s to player inventory" % [quantity, product_id])

func _on_clear_inventory_pressed() -> void:
	InventoryManager.clear_inventory("player")
	print("[DEV] Cleared player inventory")

func _on_fill_ingredients_pressed() -> void:
	for ingredient in all_ingredients:
		InventoryManager.add_item("player", ingredient, 50)
	print("[DEV] Filled player inventory with 50 of each ingredient")

# ============================================================================
# CUSTOMER FUNCTIONS
# ============================================================================

func _update_customer_count() -> void:
	if active_customers_label:
		var count = CustomerManager.active_customers.size()
		active_customers_label.text = "Active Customers: %d" % count

func _on_spawn_customer_pressed() -> void:
	if GameManager.current_phase != GameManager.Phase.BUSINESS:
		print("[DEV] Warning: Not in BUSINESS phase. Spawning anyway...")

	CustomerManager.spawn_customer()
	_update_customer_count()
	print("[DEV] Spawned 1 customer")

func _on_spawn_multiple_pressed() -> void:
	var count: int = int(spawn_count_input.value)

	if GameManager.current_phase != GameManager.Phase.BUSINESS:
		print("[DEV] Warning: Not in BUSINESS phase. Spawning anyway...")

	for i in range(count):
		CustomerManager.spawn_customer()
		# Small delay between spawns
		await get_tree().create_timer(0.2).timeout

	_update_customer_count()
	print("[DEV] Spawned %d customers" % count)

func _on_clear_customers_pressed() -> void:
	CustomerManager.clear_all_customers()
	_update_customer_count()
	print("[DEV] Cleared all customers")

func _on_start_spawning_pressed() -> void:
	CustomerManager.start_spawning()
	print("[DEV] Customer spawning enabled")

func _on_stop_spawning_pressed() -> void:
	CustomerManager.stop_spawning()
	print("[DEV] Customer spawning disabled")

# ============================================================================
# TIME/PHASE FUNCTIONS
# ============================================================================

func _update_phase_display(phase: GameManager.Phase) -> void:
	if current_phase_label:
		var phase_names = ["BAKING", "BUSINESS", "CLEANUP", "PLANNING"]
		current_phase_label.text = "Current Phase: " + phase_names[phase]

func _update_day_display(day: int) -> void:
	if current_day_label:
		current_day_label.text = "Current Day: %d" % day

func _update_time_scale_display(scale: float) -> void:
	if time_scale_label:
		if scale == 0.0:
			time_scale_label.text = "Time Scale: PAUSED"
		else:
			time_scale_label.text = "Time Scale: %.1fx" % scale

func _on_pause_pressed() -> void:
	GameManager.set_time_scale(0.0)
	print("[DEV] Time paused")

func _on_speed_1x_pressed() -> void:
	GameManager.set_time_scale(1.0)
	print("[DEV] Time scale: 1x")

func _on_speed_2x_pressed() -> void:
	GameManager.set_time_scale(2.0)
	print("[DEV] Time scale: 2x")

func _on_speed_3x_pressed() -> void:
	GameManager.set_time_scale(3.0)
	print("[DEV] Time scale: 3x")

func _on_next_phase_pressed() -> void:
	var current = GameManager.current_phase
	match current:
		GameManager.Phase.BAKING:
			GameManager.start_business_phase()
		GameManager.Phase.BUSINESS:
			GameManager.start_cleanup_phase()
		GameManager.Phase.CLEANUP:
			GameManager.start_planning_phase()
		GameManager.Phase.PLANNING:
			GameManager.end_day()
	print("[DEV] Advanced to next phase")

func _on_set_baking_pressed() -> void:
	GameManager.start_baking_phase()
	print("[DEV] Set phase to BAKING")

func _on_set_business_pressed() -> void:
	GameManager.start_business_phase()
	print("[DEV] Set phase to BUSINESS")

func _on_set_cleanup_pressed() -> void:
	GameManager.start_cleanup_phase()
	print("[DEV] Set phase to CLEANUP")

func _on_set_planning_pressed() -> void:
	GameManager.start_planning_phase()
	print("[DEV] Set phase to PLANNING")

func _on_advance_day_pressed() -> void:
	GameManager.end_day()
	print("[DEV] Advanced to next day")

func _on_set_day_pressed() -> void:
	var target_day: int = int(set_day_input.value)
	GameManager.current_day = target_day
	GameManager.day_changed.emit(target_day)
	_update_day_display(target_day)
	print("[DEV] Set day to %d" % target_day)

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

func _on_print_debug_pressed() -> void:
	print("\n=== DEV MENU DEBUG INFO ===")
	print("Day: %d" % GameManager.current_day)
	print("Phase: %s" % GameManager.Phase.keys()[GameManager.current_phase])
	print("Cash: $%.2f" % EconomyManager.current_cash)
	print("Time Scale: %.1fx" % GameManager.time_scale)
	print("Active Customers: %d" % CustomerManager.active_customers.size())

	var player_inv = InventoryManager.get_inventory("player")
	print("Player Inventory:")
	if player_inv.is_empty():
		print("  (empty)")
	else:
		for item_id in player_inv:
			print("  %s: %d" % [item_id, player_inv[item_id]])
	print("==========================\n")

func _on_quick_save_pressed() -> void:
	SaveManager.save_game()
	print("[DEV] Game saved")

func _on_quick_load_pressed() -> void:
	SaveManager.load_game()
	_update_all_displays()
	print("[DEV] Game loaded")

func _on_close_pressed() -> void:
	toggle_menu()
