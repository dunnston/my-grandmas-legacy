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

@onready var ingredient_section: VBoxContainer = $Panel/VBoxContainer/IngredientSection
@onready var ingredient_container: VBoxContainer = $Panel/VBoxContainer/IngredientSection/IngredientContainer

@onready var next_day_button: Button = $Panel/VBoxContainer/NextDayButton

# State
var daily_report: Dictionary = {}
var ingredient_order: Dictionary = {}

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
