extends CanvasLayer

# ShopManagementMenu - Central hub for managing bakery operations
# Opens with M key, provides tabs for all management functions
# Based on shop-management.md design document

signal menu_opened()
signal menu_closed()

# Node references
@onready var panel: Panel = $Panel
@onready var tab_container: TabContainer = $Panel/MarginContainer/VBoxContainer/TabContainer
@onready var close_button: Button = $Panel/MarginContainer/VBoxContainer/CloseButton

# Tab panels (created dynamically)
var dashboard_panel: Control
var pricing_panel: Control
var staff_panel: Control
var marketing_panel: Control
var statistics_panel: Control
var events_panel: Control

# State
var is_open: bool = false

func _ready() -> void:
	# Hide by default
	hide()

	# Add to group for easy access
	add_to_group("shop_management_menu")

	# Create UI structure
	_create_ui()

	# Connect close button
	if close_button:
		close_button.pressed.connect(_on_close_pressed)

	print("ShopManagementMenu initialized - Press M to open")

func _create_ui() -> void:
	"""Create the main UI structure"""
	# If UI already exists from .tscn file, just create tabs
	if panel and tab_container:
		print("UI already exists from scene file, creating tabs")
		_create_all_tabs()
		return

	# Create Panel if it doesn't exist
	if not panel:
		panel = Panel.new()
		panel.name = "Panel"
		add_child(panel)

		# Set panel size and position (centered, 80% of screen)
		panel.set_anchors_preset(Control.PRESET_CENTER)
		panel.custom_minimum_size = Vector2(1000, 700)
		panel.position = Vector2(-500, -350)  # Center it

	# Create MarginContainer
	var margin = MarginContainer.new()
	margin.name = "MarginContainer"
	panel.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)

	# Create VBoxContainer for layout
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	margin.add_child(vbox)
	vbox.add_theme_constant_override("separation", 10)

	# Create title label
	var title_label = Label.new()
	title_label.text = "SHOP MANAGEMENT"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title_label)

	# Create TabContainer
	if not tab_container:
		tab_container = TabContainer.new()
		tab_container.name = "TabContainer"
		vbox.add_child(tab_container)
		tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL

	# Create Close button
	if not close_button:
		close_button = Button.new()
		close_button.name = "CloseButton"
		close_button.text = "Close (ESC / M)"
		close_button.custom_minimum_size = Vector2(150, 40)
		close_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		vbox.add_child(close_button)
		close_button.pressed.connect(_on_close_pressed)

	# Create all tabs
	_create_all_tabs()

func _create_all_tabs() -> void:
	"""Create all management tabs"""
	_create_dashboard_tab()
	_create_pricing_tab()
	_create_staff_tab()
	_create_marketing_tab()
	_create_statistics_tab()
	_create_events_tab()

# ============================================================================
# TAB 1: DASHBOARD
# ============================================================================

func _create_dashboard_tab() -> void:
	"""Create the Dashboard tab with quick overview"""
	var scroll = ScrollContainer.new()
	scroll.name = "Dashboard"
	tab_container.add_child(scroll)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 15)
	scroll.add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "DASHBOARD - Day %d" % GameManager.get_current_day()
	title.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title)

	# TODAY'S SUMMARY section
	var summary_label = Label.new()
	summary_label.text = "TODAY'S SUMMARY"
	summary_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(summary_label)

	var summary_panel = PanelContainer.new()
	vbox.add_child(summary_panel)

	var summary_grid = GridContainer.new()
	summary_grid.columns = 2
	summary_grid.add_theme_constant_override("h_separation", 40)
	summary_grid.add_theme_constant_override("v_separation", 10)
	summary_panel.add_child(summary_grid)

	# Financial stats
	var revenue_label = Label.new()
	revenue_label.name = "RevenueLabel"
	revenue_label.text = "Revenue: $%.2f" % EconomyManager.get_daily_revenue()
	summary_grid.add_child(revenue_label)

	var expenses_label = Label.new()
	expenses_label.name = "ExpensesLabel"
	expenses_label.text = "Expenses: $%.2f" % EconomyManager.get_daily_expenses()
	summary_grid.add_child(expenses_label)

	var profit_label = Label.new()
	profit_label.name = "ProfitLabel"
	var profit = EconomyManager.get_daily_profit()
	profit_label.text = "Profit: $%.2f" % profit
	profit_label.modulate = Color.GREEN if profit >= 0 else Color.RED
	summary_grid.add_child(profit_label)

	var customers_label = Label.new()
	customers_label.name = "CustomersLabel"
	customers_label.text = "Customers: %d" % CustomerManager.customers_served_today
	summary_grid.add_child(customers_label)

	# REPUTATION section
	var rep_label = Label.new()
	rep_label.text = "REPUTATION"
	rep_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(rep_label)

	var rep_panel = PanelContainer.new()
	vbox.add_child(rep_panel)

	var rep_vbox = VBoxContainer.new()
	rep_panel.add_child(rep_vbox)

	var rep_value = Label.new()
	var reputation = ProgressionManager.get_reputation()
	rep_value.text = "🌟 %d/100" % reputation
	rep_value.add_theme_font_size_override("font_size", 18)
	rep_vbox.add_child(rep_value)

	var rep_bar = ProgressBar.new()
	rep_bar.min_value = 0
	rep_bar.max_value = 100
	rep_bar.value = reputation
	rep_bar.custom_minimum_size = Vector2(400, 30)
	rep_vbox.add_child(rep_bar)

	var rep_status = Label.new()
	rep_status.text = _get_reputation_status(reputation)
	rep_vbox.add_child(rep_status)

	# QUICK STATS section
	var stats_label = Label.new()
	stats_label.text = "QUICK STATS"
	stats_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(stats_label)

	var stats_panel = PanelContainer.new()
	vbox.add_child(stats_panel)

	var stats_vbox = VBoxContainer.new()
	stats_panel.add_child(stats_vbox)

	var avg_satisfaction = 0.0
	if CustomerManager.customers_served_today > 0:
		avg_satisfaction = CustomerManager.total_satisfaction_today / CustomerManager.customers_served_today

	var satisfaction_stat = Label.new()
	satisfaction_stat.text = "• Average Customer Satisfaction: %s %.0f%%" % [_get_emoji_for_satisfaction(avg_satisfaction), avg_satisfaction]
	stats_vbox.add_child(satisfaction_stat)

	var cash_stat = Label.new()
	cash_stat.text = "• Cash on Hand: $%.2f" % EconomyManager.get_current_cash()
	stats_vbox.add_child(cash_stat)

	dashboard_panel = scroll

func _get_reputation_status(reputation: int) -> String:
	"""Get status text based on reputation level"""
	if reputation >= 90:
		return "Status: \"Legendary Bakery\""
	elif reputation >= 75:
		return "Status: \"Famous Local Spot\""
	elif reputation >= 60:
		return "Status: \"Popular Bakery\""
	elif reputation >= 40:
		return "Status: \"Decent Establishment\""
	elif reputation >= 25:
		return "Status: \"Struggling Business\""
	else:
		return "Status: \"In Trouble\""

func _get_emoji_for_satisfaction(satisfaction: float) -> String:
	"""Get emoji based on satisfaction level"""
	if satisfaction >= 80:
		return "😊"
	elif satisfaction >= 60:
		return "🙂"
	elif satisfaction >= 40:
		return "😐"
	else:
		return "☹️"

# ============================================================================
# TAB 2: PRICING
# ============================================================================

func _create_pricing_tab() -> void:
	"""Create the Pricing tab for setting item prices"""
	var scroll = ScrollContainer.new()
	scroll.name = "Pricing"
	tab_container.add_child(scroll)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(vbox)

	# Title and instructions
	var title = Label.new()
	title.text = "PRICING MANAGER"
	title.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title)

	var instructions = Label.new()
	instructions.text = "Set prices for your baked goods. Higher prices = more profit but fewer sales.\nCustomers have different price tolerances based on quality, reputation, and type."
	instructions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instructions.custom_minimum_size = Vector2(800, 0)
	vbox.add_child(instructions)

	# Recipe list container
	var recipe_list = VBoxContainer.new()
	recipe_list.name = "RecipeList"
	recipe_list.add_theme_constant_override("separation", 5)
	vbox.add_child(recipe_list)

	# Populate with unlocked recipes
	_populate_pricing_list(recipe_list)

	pricing_panel = scroll

func _populate_pricing_list(recipe_list: VBoxContainer) -> void:
	"""Populate the recipe list with pricing controls"""
	var unlocked_recipes = RecipeManager.get_all_unlocked_recipes()

	if unlocked_recipes.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No recipes unlocked yet!"
		recipe_list.add_child(empty_label)
		return

	# Group recipes by category
	var categories = {}
	for recipe in unlocked_recipes:
		var category = recipe.get("category", "other")
		if not categories.has(category):
			categories[category] = []
		categories[category].append(recipe)

	# Display by category
	for category in categories:
		# Category header
		var category_label = Label.new()
		category_label.text = category.to_upper() + "S"
		category_label.add_theme_font_size_override("font_size", 16)
		category_label.modulate = Color(0.8, 0.8, 1.0)
		recipe_list.add_child(category_label)

		# Add each recipe in this category
		for recipe in categories[category]:
			_add_pricing_row(recipe_list, recipe)

		# Add spacing between categories
		var spacer = Control.new()
		spacer.custom_minimum_size = Vector2(0, 10)
		recipe_list.add_child(spacer)

func _add_pricing_row(container: VBoxContainer, recipe: Dictionary) -> void:
	"""Add a pricing control row for one recipe"""
	var panel = PanelContainer.new()
	container.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	panel.add_child(vbox)

	# Recipe name
	var name_label = Label.new()
	name_label.text = recipe.name
	name_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(name_label)

	# Info row: Cost, Suggested Price, Market Range
	var info_hbox = HBoxContainer.new()
	info_hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(info_hbox)

	var cost = RecipeManager.get_recipe_cost(recipe.id)
	var base_price = recipe.get("base_price", 0.0)
	var min_market = base_price * 0.8
	var max_market = base_price * 1.5

	var cost_label = Label.new()
	cost_label.text = "Cost: $%.2f" % cost
	cost_label.modulate = Color(0.9, 0.9, 0.9)
	info_hbox.add_child(cost_label)

	var market_label = Label.new()
	market_label.text = "Market Range: $%.2f - $%.2f" % [min_market, max_market]
	market_label.modulate = Color(0.8, 0.8, 1.0)
	info_hbox.add_child(market_label)

	var suggested_label = Label.new()
	suggested_label.text = "Suggested: $%.2f" % base_price
	suggested_label.modulate = Color(0.8, 1.0, 0.8)
	info_hbox.add_child(suggested_label)

	# Price control row
	var control_hbox = HBoxContainer.new()
	control_hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(control_hbox)

	# Decrease button
	var decrease_btn = Button.new()
	decrease_btn.text = "-"
	decrease_btn.custom_minimum_size = Vector2(40, 30)
	decrease_btn.pressed.connect(_on_decrease_price.bind(recipe.id, container))
	control_hbox.add_child(decrease_btn)

	# Price display (SpinBox for direct input)
	var price_spin = SpinBox.new()
	price_spin.name = "PriceSpinBox_" + recipe.id
	price_spin.custom_minimum_size = Vector2(120, 30)
	price_spin.min_value = cost * 0.5  # Can't go below 50% of cost
	price_spin.max_value = base_price * 3.0  # Can't go above 3x base price
	price_spin.step = 0.50
	price_spin.prefix = "$"
	price_spin.value = RecipeManager.get_effective_price(recipe.id)
	price_spin.value_changed.connect(_on_price_spinbox_changed.bind(recipe.id, container))
	control_hbox.add_child(price_spin)

	# Increase button
	var increase_btn = Button.new()
	increase_btn.text = "+"
	increase_btn.custom_minimum_size = Vector2(40, 30)
	increase_btn.pressed.connect(_on_increase_price.bind(recipe.id, container))
	control_hbox.add_child(increase_btn)

	# Reset button
	var reset_btn = Button.new()
	reset_btn.text = "Reset to Suggested"
	reset_btn.custom_minimum_size = Vector2(150, 30)
	reset_btn.pressed.connect(_on_reset_price.bind(recipe.id, container))
	control_hbox.add_child(reset_btn)

	# Status row: Profit and Price Zone
	var status_hbox = HBoxContainer.new()
	status_hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(status_hbox)

	var current_price = RecipeManager.get_effective_price(recipe.id)
	var profit = current_price - cost
	var profit_pct = (profit / cost * 100.0) if cost > 0 else 0.0

	var profit_label = Label.new()
	profit_label.name = "ProfitLabel_" + recipe.id
	profit_label.text = "Profit: $%.2f (%.0f%%)" % [profit, profit_pct]
	profit_label.modulate = Color.GREEN if profit > 0 else Color.RED
	status_hbox.add_child(profit_label)

	var zone_label = Label.new()
	zone_label.name = "ZoneLabel_" + recipe.id
	zone_label.text = _get_price_zone(current_price, base_price, cost)
	status_hbox.add_child(zone_label)

func _get_price_zone(current_price: float, base_price: float, cost: float) -> String:
	"""Determine the price zone and return a colored label"""
	var ratio = current_price / base_price if base_price > 0 else 1.0

	if current_price < cost:
		return "🔴 LOSING MONEY!"
	elif ratio < 0.8:
		return "🔴 Too Low (Missing profit)"
	elif ratio <= 1.2:
		return "🟢 Good (Most customers buy)"
	elif ratio <= 1.5:
		return "🟡 High (Tourists/regulars only)"
	else:
		return "🔴 Too High (Few buyers)"

func _on_decrease_price(recipe_id: String, container: VBoxContainer) -> void:
	"""Decrease price by $0.50"""
	var current = RecipeManager.get_effective_price(recipe_id)
	var new_price = max(current - 0.50, 0.50)
	RecipeManager.set_player_price(recipe_id, new_price)
	_update_pricing_display(recipe_id, container)

func _on_increase_price(recipe_id: String, container: VBoxContainer) -> void:
	"""Increase price by $0.50"""
	var current = RecipeManager.get_effective_price(recipe_id)
	var recipe = RecipeManager.get_recipe(recipe_id)
	var base_price = recipe.get("base_price", 10.0)
	var new_price = min(current + 0.50, base_price * 3.0)
	RecipeManager.set_player_price(recipe_id, new_price)
	_update_pricing_display(recipe_id, container)

func _on_price_spinbox_changed(new_price: float, recipe_id: String, container: VBoxContainer) -> void:
	"""Handle direct price input from spinbox"""
	RecipeManager.set_player_price(recipe_id, new_price)
	_update_pricing_display(recipe_id, container)

func _on_reset_price(recipe_id: String, container: VBoxContainer) -> void:
	"""Reset price to suggested base price"""
	RecipeManager.clear_player_price(recipe_id)
	_update_pricing_display(recipe_id, container)

func _update_pricing_display(recipe_id: String, container: VBoxContainer) -> void:
	"""Update the display after price change"""
	# Get updated price
	var current_price = RecipeManager.get_effective_price(recipe_id)
	var recipe = RecipeManager.get_recipe(recipe_id)
	var cost = RecipeManager.get_recipe_cost(recipe_id)
	var base_price = recipe.get("base_price", 10.0)

	# Find the spinbox and labels
	var spinbox = container.find_child("PriceSpinBox_" + recipe_id, true, false)
	var profit_label = container.find_child("ProfitLabel_" + recipe_id, true, false)
	var zone_label = container.find_child("ZoneLabel_" + recipe_id, true, false)

	# Update spinbox value (block signals to prevent recursion)
	if spinbox:
		spinbox.set_block_signals(true)
		spinbox.value = current_price
		spinbox.set_block_signals(false)
		print("Updated spinbox for %s to $%.2f" % [recipe_id, current_price])

	# Update profit label
	if profit_label:
		var profit = current_price - cost
		var profit_pct = (profit / cost * 100.0) if cost > 0 else 0.0
		profit_label.text = "Profit: $%.2f (%.0f%%)" % [profit, profit_pct]
		profit_label.modulate = Color.GREEN if profit > 0 else Color.RED

	# Update zone label
	if zone_label:
		zone_label.text = _get_price_zone(current_price, base_price, cost)

# ============================================================================
# TAB 3: STAFF (Placeholder)
# ============================================================================

func _create_staff_tab() -> void:
	"""Create the Staff management tab (placeholder)"""
	var scroll = ScrollContainer.new()
	scroll.name = "Staff"
	tab_container.add_child(scroll)

	var vbox = VBoxContainer.new()
	scroll.add_child(vbox)

	var title = Label.new()
	title.text = "STAFF MANAGEMENT"
	title.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title)

	var placeholder = Label.new()
	placeholder.text = "Staff hiring and management coming soon!\n\nThis tab will allow you to:\n• Hire bakers, cashiers, and cleaners\n• Assign staff to phases\n• Manage wages and morale\n• View staff performance"
	placeholder.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(placeholder)

	staff_panel = scroll

# ============================================================================
# TAB 4: MARKETING (Placeholder)
# ============================================================================

func _create_marketing_tab() -> void:
	"""Create the Marketing tab (placeholder)"""
	var scroll = ScrollContainer.new()
	scroll.name = "Marketing"
	tab_container.add_child(scroll)

	var vbox = VBoxContainer.new()
	scroll.add_child(vbox)

	var title = Label.new()
	title.text = "MARKETING & ADVERTISING"
	title.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title)

	var placeholder = Label.new()
	placeholder.text = "Marketing campaigns coming soon!\n\nThis tab will allow you to:\n• Purchase newspaper ads\n• Run social media campaigns\n• Book radio spots\n• View active campaigns and their effects"
	placeholder.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(placeholder)

	marketing_panel = scroll

# ============================================================================
# TAB 5: STATISTICS (Placeholder)
# ============================================================================

func _create_statistics_tab() -> void:
	"""Create the Statistics tab (placeholder)"""
	var scroll = ScrollContainer.new()
	scroll.name = "Statistics"
	tab_container.add_child(scroll)

	var vbox = VBoxContainer.new()
	scroll.add_child(vbox)

	var title = Label.new()
	title.text = "STATISTICS & ANALYTICS"
	title.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title)

	var placeholder = Label.new()
	placeholder.text = "Detailed statistics coming soon!\n\nThis tab will show:\n• Reputation history graph\n• Revenue/profit trends\n• Customer metrics\n• Top selling items\n• Expense breakdown"
	placeholder.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(placeholder)

	statistics_panel = scroll

# ============================================================================
# TAB 6: EVENTS & PROJECTIONS (Placeholder)
# ============================================================================

func _create_events_tab() -> void:
	"""Create the Events & Projections tab (placeholder)"""
	var scroll = ScrollContainer.new()
	scroll.name = "Events"
	tab_container.add_child(scroll)

	var vbox = VBoxContainer.new()
	scroll.add_child(vbox)

	var title = Label.new()
	title.text = "EVENTS & TRAFFIC PROJECTIONS"
	title.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title)

	var placeholder = Label.new()
	placeholder.text = "Event planning coming soon!\n\nThis tab will show:\n• Upcoming special events\n• Food critic visits\n• Daily traffic forecast\n• Preparation recommendations"
	placeholder.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(placeholder)

	events_panel = scroll

# ============================================================================
# MENU CONTROL
# ============================================================================

func _input(event: InputEvent) -> void:
	"""Handle input for opening/closing menu"""
	if event.is_action_pressed("open_shop_menu"):  # M key
		toggle_menu()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") and is_open:  # ESC key
		close_menu()
		get_viewport().set_input_as_handled()

func toggle_menu() -> void:
	"""Toggle menu open/closed"""
	if is_open:
		close_menu()
	else:
		open_menu()

func open_menu() -> void:
	"""Open the shop management menu"""
	if is_open:
		return

	is_open = true
	show()
	GameManager.pause_game()

	# Capture mouse for UI interaction
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# Refresh all tabs
	_refresh_all_tabs()

	# Set to dashboard tab by default
	if tab_container:
		tab_container.current_tab = 0

	menu_opened.emit()
	print("Shop Management Menu opened - Press ESC or M to close")

func close_menu() -> void:
	"""Close the shop management menu"""
	if not is_open:
		return

	is_open = false
	hide()
	GameManager.resume_game()

	# Restore mouse capture for camera control
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	menu_closed.emit()
	print("Shop Management Menu closed")

func _on_close_pressed() -> void:
	"""Handle close button press"""
	close_menu()

func _refresh_all_tabs() -> void:
	"""Refresh data in all tabs"""
	# Refresh dashboard with current data
	if dashboard_panel:
		# Update labels
		var revenue_label = dashboard_panel.find_child("RevenueLabel", true, false)
		if revenue_label:
			revenue_label.text = "Revenue: $%.2f" % EconomyManager.get_daily_revenue()

		var expenses_label = dashboard_panel.find_child("ExpensesLabel", true, false)
		if expenses_label:
			expenses_label.text = "Expenses: $%.2f" % EconomyManager.get_daily_expenses()

		var profit_label = dashboard_panel.find_child("ProfitLabel", true, false)
		if profit_label:
			var profit = EconomyManager.get_daily_profit()
			profit_label.text = "Profit: $%.2f" % profit
			profit_label.modulate = Color.GREEN if profit >= 0 else Color.RED

		var customers_label = dashboard_panel.find_child("CustomersLabel", true, false)
		if customers_label:
			customers_label.text = "Customers: %d" % CustomerManager.customers_served_today

	# Refresh pricing panel
	if pricing_panel:
		var recipe_list = pricing_panel.find_child("RecipeList", true, false)
		if recipe_list:
			# Clear and repopulate
			for child in recipe_list.get_children():
				child.queue_free()
			_populate_pricing_list(recipe_list)
