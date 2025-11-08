extends CanvasLayer

# PlanningMenu - UI for the Planning phase
# Shows daily report, allows ingredient ordering, and starts next day

# Signals
signal next_day_started()

# Node references
@onready var panel: Panel = $Panel
@onready var day_label: Label = $Panel/VBoxContainer/DayLabel
@onready var report_section: VBoxContainer = $Panel/VBoxContainer/ReportSection
@onready var revenue_label: Label = $Panel/VBoxContainer/ReportSection/RevenueLabel
@onready var expenses_label: Label = $Panel/VBoxContainer/ReportSection/ExpensesLabel
@onready var profit_label: Label = $Panel/VBoxContainer/ReportSection/ProfitLabel
@onready var cash_label: Label = $Panel/VBoxContainer/ReportSection/CashLabel
@onready var satisfaction_label: Label = $Panel/VBoxContainer/ReportSection/SatisfactionLabel

@onready var tab_container: TabContainer = $Panel/VBoxContainer/TabContainer
@onready var ingredient_container: VBoxContainer = $Panel/VBoxContainer/TabContainer/Ingredients/ScrollContainer/IngredientContainer
@onready var campaign_container: VBoxContainer = $Panel/VBoxContainer/TabContainer/Marketing/ScrollContainer/CampaignContainer

@onready var next_day_button: Button = $Panel/VBoxContainer/NextDayButton

# State
var daily_report: Dictionary = {}
var ingredient_order: Dictionary = {}
var active_campaigns: Array = []

func _ready() -> void:
	hide()  # Hidden by default

	if next_day_button:
		next_day_button.pressed.connect(_on_next_day_pressed)

	print("PlanningMenu initialized")

func open_menu() -> void:
	"""Open the planning menu and display daily report"""
	show()
	GameManager.pause_game()

	# Generate and display reports
	_display_daily_report()
	_setup_ingredient_ordering()
	_setup_marketing_campaigns()

	print("\n=== PLANNING PHASE ===")
	print("Review your day and prepare for tomorrow!")

func close_menu() -> void:
	"""Close the planning menu"""
	hide()
	GameManager.resume_game()

func _display_daily_report() -> void:
	"""Display financial and customer reports"""
	# Get financial report
	var financial_report: Dictionary = EconomyManager.generate_daily_report()
	var customer_report: Dictionary = CustomerManager.generate_daily_customer_report()

	# Update day label
	if day_label:
		day_label.text = "Day %d Complete" % GameManager.get_current_day()

	# Update financial labels
	if revenue_label:
		revenue_label.text = "Revenue: $%.2f" % financial_report.get("revenue", 0.0)

	if expenses_label:
		expenses_label.text = "Expenses: $%.2f" % financial_report.get("expenses", 0.0)

	if profit_label:
		var profit: float = financial_report.get("profit", 0.0)
		var color: String = "green" if profit >= 0 else "red"
		profit_label.text = "[color=%s]Profit: $%.2f[/color]" % [color, profit]
		profit_label.add_theme_color_override("font_color", Color.GREEN if profit >= 0 else Color.RED)

	if cash_label:
		cash_label.text = "Cash on Hand: $%.2f" % financial_report.get("cash_on_hand", 0.0)

	if satisfaction_label:
		var avg_satisfaction: float = customer_report.get("average_satisfaction", 0.0)
		var customers_served: int = customer_report.get("customers_served", 0)
		satisfaction_label.text = "Customers: %d | Satisfaction: %.0f%%" % [customers_served, avg_satisfaction]

func _setup_ingredient_ordering() -> void:
	"""Set up ingredient ordering UI"""
	if not ingredient_container:
		return

	# Clear existing children
	for child in ingredient_container.get_children():
		child.queue_free()

	# Add ingredient ordering options
	var ingredients: Array = [
		"flour", "sugar", "eggs", "butter", "milk",
		"yeast", "chocolate_chips", "blueberries", "vanilla", "salt"
	]

	for ingredient_id in ingredients:
		_add_ingredient_order_row(ingredient_id)

func _add_ingredient_order_row(ingredient_id: String) -> void:
	"""Add a row for ordering an ingredient"""
	var hbox: HBoxContainer = HBoxContainer.new()
	ingredient_container.add_child(hbox)

	# Ingredient name
	var name_label: Label = Label.new()
	name_label.text = ingredient_id.capitalize()
	name_label.custom_minimum_size.x = 150
	hbox.add_child(name_label)

	# Price
	var price: float = EconomyManager.get_ingredient_price(ingredient_id)
	var price_label: Label = Label.new()
	price_label.text = "$%.2f" % price
	price_label.custom_minimum_size.x = 60
	hbox.add_child(price_label)

	# Decrease button
	var decrease_button: Button = Button.new()
	decrease_button.text = "-"
	decrease_button.custom_minimum_size.x = 30
	decrease_button.pressed.connect(_on_decrease_ingredient.bind(ingredient_id))
	hbox.add_child(decrease_button)

	# Quantity label
	var quantity_label: Label = Label.new()
	quantity_label.text = "0"
	quantity_label.name = "QuantityLabel_" + ingredient_id
	quantity_label.custom_minimum_size.x = 40
	quantity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hbox.add_child(quantity_label)

	# Increase button
	var increase_button: Button = Button.new()
	increase_button.text = "+"
	increase_button.custom_minimum_size.x = 30
	increase_button.pressed.connect(_on_increase_ingredient.bind(ingredient_id))
	hbox.add_child(increase_button)

	# Total cost label
	var cost_label: Label = Label.new()
	cost_label.text = "$0.00"
	cost_label.name = "CostLabel_" + ingredient_id
	cost_label.custom_minimum_size.x = 70
	hbox.add_child(cost_label)

func _on_increase_ingredient(ingredient_id: String) -> void:
	"""Increase ingredient order quantity"""
	if not ingredient_order.has(ingredient_id):
		ingredient_order[ingredient_id] = 0

	# Check if player can afford one more
	var price: float = EconomyManager.get_ingredient_price(ingredient_id)
	var total_cost: float = _calculate_total_order_cost() + price

	if total_cost > EconomyManager.get_current_cash():
		print("Cannot afford more %s!" % ingredient_id)
		return

	ingredient_order[ingredient_id] += 1
	_update_ingredient_display(ingredient_id)

func _on_decrease_ingredient(ingredient_id: String) -> void:
	"""Decrease ingredient order quantity"""
	if not ingredient_order.has(ingredient_id) or ingredient_order[ingredient_id] <= 0:
		return

	ingredient_order[ingredient_id] -= 1
	if ingredient_order[ingredient_id] == 0:
		ingredient_order.erase(ingredient_id)

	_update_ingredient_display(ingredient_id)

func _update_ingredient_display(ingredient_id: String) -> void:
	"""Update the quantity and cost labels for an ingredient"""
	var quantity: int = ingredient_order.get(ingredient_id, 0)
	var price: float = EconomyManager.get_ingredient_price(ingredient_id)
	var cost: float = quantity * price

	# Find labels
	var quantity_label: Label = ingredient_container.find_child("QuantityLabel_" + ingredient_id, true, false)
	var cost_label: Label = ingredient_container.find_child("CostLabel_" + ingredient_id, true, false)

	if quantity_label:
		quantity_label.text = str(quantity)

	if cost_label:
		cost_label.text = "$%.2f" % cost

func _calculate_total_order_cost() -> float:
	"""Calculate total cost of current order"""
	var total: float = 0.0
	for ingredient_id in ingredient_order:
		var quantity: int = ingredient_order[ingredient_id]
		var price: float = EconomyManager.get_ingredient_price(ingredient_id)
		total += quantity * price
	return total

func _on_next_day_pressed() -> void:
	"""Process ingredient order and start next day"""
	# Calculate total cost
	var total_cost: float = _calculate_total_order_cost()

	print("\n=== PROCESSING INGREDIENT ORDER ===")
	print("Total order cost: $%.2f" % total_cost)

	# Check if player can afford it
	if total_cost > 0 and not EconomyManager.can_afford(total_cost):
		print("ERROR: Cannot afford this order!")
		return

	# Process payment
	if total_cost > 0:
		EconomyManager.remove_money(total_cost, "Ingredient order")

	# Add ingredients to storage
	for ingredient_id in ingredient_order:
		var quantity: int = ingredient_order[ingredient_id]
		InventoryManager.add_item("ingredient_storage_IngredientStorage", ingredient_id, quantity)
		print("Ordered: %dx %s" % [quantity, ingredient_id])

	print("Order complete!")
	print("===================================\n")

	# Reset daily stats for new day
	EconomyManager.reset_daily_stats()
	CustomerManager.reset_daily_stats()

	# Clear order
	ingredient_order.clear()

	# Close menu and start next day
	close_menu()
	GameManager.end_day()

	next_day_started.emit()

func _setup_marketing_campaigns() -> void:
	"""Set up marketing campaign UI"""
	if not campaign_container:
		return

	# Clear existing children
	for child in campaign_container.get_children():
		child.queue_free()

	# Get all campaigns from MarketingManager
	var all_campaigns: Dictionary = MarketingManager.get_all_campaigns()
	active_campaigns = MarketingManager.get_active_campaigns()

	for campaign_id in all_campaigns.keys():
		var campaign: Dictionary = all_campaigns[campaign_id]
		_add_campaign_card(campaign_id, campaign)

func _add_campaign_card(campaign_id: String, campaign: Dictionary) -> void:
	"""Add a marketing campaign card to the UI"""
	var panel: PanelContainer = PanelContainer.new()
	campaign_container.add_child(panel)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	panel.add_child(vbox)

	# Campaign name
	var name_label: Label = Label.new()
	name_label.text = campaign.get("name", campaign_id.capitalize())
	name_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(name_label)

	# Description
	var desc_label: Label = Label.new()
	desc_label.text = campaign.get("description", "")
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(desc_label)

	# Effects and cost in HBox
	var hbox: HBoxContainer = HBoxContainer.new()
	vbox.add_child(hbox)

	# Effects
	var effects_label: Label = Label.new()
	var effects: Dictionary = campaign.get("effects", {})
	var traffic_mult: float = effects.get("traffic_multiplier", 1.0)
	var duration_days: int = campaign.get("duration_days", 0)
	var duration_text: String = " for %d day%s" % [duration_days, "s" if duration_days != 1 else ""] if duration_days > 0 else " (permanent)"
	effects_label.text = "Traffic: +%.0f%%%s" % [(traffic_mult - 1.0) * 100, duration_text]
	effects_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(effects_label)

	# Cost and launch button
	var cost: float = campaign.get("cost", 0.0)
	var cost_label: Label = Label.new()
	cost_label.text = "$%.2f" % cost
	cost_label.custom_minimum_size.x = 70
	hbox.add_child(cost_label)

	# Launch button
	var launch_button: Button = Button.new()
	var is_unlocked: bool = ProgressionManager.get_current_total_revenue() >= campaign.get("unlock_revenue", 0)
	var is_active: bool = _is_campaign_active(campaign_id)
	var can_afford: bool = EconomyManager.can_afford(cost)

	if not is_unlocked:
		launch_button.text = "🔒 Locked"
		launch_button.disabled = true
		launch_button.tooltip_text = "Unlock at $%.2f total revenue" % campaign.get("unlock_revenue", 0)
	elif is_active:
		launch_button.text = "✓ Active"
		launch_button.disabled = true
	elif not can_afford:
		launch_button.text = "Can't Afford"
		launch_button.disabled = true
	else:
		launch_button.text = "Launch"
		launch_button.pressed.connect(_on_launch_campaign.bind(campaign_id, cost))

	launch_button.custom_minimum_size.x = 90
	hbox.add_child(launch_button)

func _is_campaign_active(campaign_id: String) -> bool:
	"""Check if a campaign is currently active"""
	for campaign in active_campaigns:
		if campaign["id"] == campaign_id:
			return true
	return false

func _on_launch_campaign(campaign_id: String, cost: float) -> void:
	"""Launch a marketing campaign"""
	if not EconomyManager.can_afford(cost):
		print("Cannot afford this campaign!")
		return

	# Try to start campaign
	if MarketingManager.start_campaign(campaign_id):
		print("Launched campaign: ", campaign_id)
		# Refresh the UI to show it as active
		_setup_marketing_campaigns()
	else:
		print("Failed to launch campaign: ", campaign_id)
