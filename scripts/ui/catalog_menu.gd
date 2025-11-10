extends CanvasLayer

# CatalogMenu - Shop UI for purchasing equipment, ingredients, and decorations
# Can be opened anytime with 'C' key

# Node references
@onready var panel: Panel = $Panel
@onready var cash_label: Label = $Panel/VBoxContainer/HeaderSection/CashLabel
@onready var tab_container: TabContainer = $Panel/VBoxContainer/TabContainer
@onready var equipment_container: VBoxContainer = $Panel/VBoxContainer/TabContainer/Equipment/ScrollContainer/EquipmentContainer
@onready var ingredient_container: VBoxContainer = $Panel/VBoxContainer/TabContainer/Ingredients/ScrollContainer/IngredientContainer
@onready var decoration_container: VBoxContainer = $Panel/VBoxContainer/TabContainer/Decorations/ScrollContainer/DecorationContainer
@onready var close_button: Button = $Panel/VBoxContainer/CloseButton

# State
var ingredient_cart: Dictionary = {}  # ingredient_id: quantity
const INGREDIENT_STORAGE_ID: String = "ingredient_storage_IngredientStorage"

func _ready() -> void:
	hide()  # Hidden by default

	# Connect close button
	if close_button:
		close_button.pressed.connect(_on_close_pressed)

	# Add to catalog_menu group for easy access
	add_to_group("catalog_menu")

	print("CatalogMenu initialized - Press 'C' to open")

func _input(event: InputEvent) -> void:
	"""Handle catalog menu toggle"""
	if event.is_action_pressed("open_catalog"):
		if visible:
			close_menu()
		else:
			open_menu()
		get_viewport().set_input_as_handled()

func open_menu() -> void:
	"""Open the catalog menu"""
	show()
	GameManager.pause_game()

	# Refresh all displays
	_update_cash_display()
	_setup_equipment_tab()
	_setup_ingredients_tab()
	_setup_decorations_tab()

	print("\n=== CATALOG MENU OPENED ===")

func close_menu() -> void:
	"""Close the catalog menu"""
	# Clear ingredient cart
	ingredient_cart.clear()

	hide()
	GameManager.resume_game()
	print("=== CATALOG MENU CLOSED ===\n")

func _on_close_pressed() -> void:
	"""Close button pressed"""
	close_menu()

func _update_cash_display() -> void:
	"""Update the cash label"""
	if cash_label:
		cash_label.text = "Cash: $%.2f" % EconomyManager.get_current_cash()

# ============================================================================
# EQUIPMENT TAB
# ============================================================================

func _setup_equipment_tab() -> void:
	"""Set up equipment purchase UI"""
	if not equipment_container:
		return

	# Clear existing children
	for child in equipment_container.get_children():
		child.queue_free()

	# Add equipment categories
	_add_equipment_section("Ovens", [
		{"id": "oven_tier_1", "name": "Basic Oven Upgrade", "cost": BalanceConfig.EQUIPMENT.oven_tier_1_cost, "unlock": BalanceConfig.EQUIPMENT.oven_tier_1_unlock, "description": "4-slot oven with faster baking"},
		{"id": "oven_tier_2", "name": "Professional Oven", "cost": BalanceConfig.EQUIPMENT.oven_tier_2_cost, "unlock": BalanceConfig.EQUIPMENT.oven_tier_2_unlock, "description": "6-slot oven, even faster"},
		{"id": "oven_tier_3", "name": "Commercial Oven", "cost": BalanceConfig.EQUIPMENT.oven_tier_3_cost, "unlock": BalanceConfig.EQUIPMENT.oven_tier_3_unlock, "description": "8-slot industrial oven"},
	])

	_add_equipment_section("Mixing Bowls", [
		{"id": "mixer_tier_1", "name": "Stand Mixer", "cost": BalanceConfig.EQUIPMENT.mixer_tier_1_cost, "unlock": BalanceConfig.EQUIPMENT.mixer_tier_1_unlock, "description": "Faster mixing, better quality"},
		{"id": "mixer_tier_2", "name": "Professional Mixer", "cost": BalanceConfig.EQUIPMENT.mixer_tier_2_cost, "unlock": BalanceConfig.EQUIPMENT.mixer_tier_2_unlock, "description": "Much faster, excellent quality"},
		{"id": "mixer_tier_3", "name": "Commercial Mixer", "cost": BalanceConfig.EQUIPMENT.mixer_tier_3_cost, "unlock": BalanceConfig.EQUIPMENT.mixer_tier_3_unlock, "description": "Instant mixing, perfect quality"},
	])

	_add_equipment_section("Display Cases", [
		{"id": "display_tier_1", "name": "Small Display Case", "cost": BalanceConfig.EQUIPMENT.display_tier_1_cost, "unlock": BalanceConfig.EQUIPMENT.display_tier_1_unlock, "description": "Hold 5 different items"},
		{"id": "display_tier_2", "name": "Large Display Case", "cost": BalanceConfig.EQUIPMENT.display_tier_2_cost, "unlock": BalanceConfig.EQUIPMENT.display_tier_2_unlock, "description": "Hold 10 different items"},
	])

	_add_equipment_section("Cooling Racks", [
		{"id": "cooling_rack_tier_1", "name": "Basic Cooling Rack", "cost": BalanceConfig.EQUIPMENT.cooling_rack_tier_1_cost, "unlock": BalanceConfig.EQUIPMENT.cooling_rack_tier_1_unlock, "description": "Faster cooling"},
		{"id": "cooling_rack_tier_2", "name": "Professional Rack", "cost": BalanceConfig.EQUIPMENT.cooling_rack_tier_2_cost, "unlock": BalanceConfig.EQUIPMENT.cooling_rack_tier_2_unlock, "description": "10 slots, very fast cooling"},
	])

	_add_equipment_section("Special Equipment", [
		{"id": "decorating_station", "name": "Decorating Station", "cost": BalanceConfig.EQUIPMENT.decorating_station_cost, "unlock": BalanceConfig.EQUIPMENT.decorating_station_unlock, "description": "+30% value, +5% quality"},
		{"id": "register_tier_1", "name": "Modern Register", "cost": BalanceConfig.EQUIPMENT.register_tier_1_cost, "unlock": BalanceConfig.EQUIPMENT.register_tier_1_unlock, "description": "20% faster transactions"},
	])

func _add_equipment_section(section_name: String, items: Array) -> void:
	"""Add a section of equipment items"""
	# Section header
	var header: Label = Label.new()
	header.text = "--- %s ---" % section_name
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 18)
	equipment_container.add_child(header)

	# Add items
	for item in items:
		_add_equipment_card(item)

	# Spacer
	var spacer: Control = Control.new()
	spacer.custom_minimum_size.y = 10
	equipment_container.add_child(spacer)

func _add_equipment_card(item: Dictionary) -> void:
	"""Add an equipment purchase card"""
	var panel: PanelContainer = PanelContainer.new()
	equipment_container.add_child(panel)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	panel.add_child(vbox)

	# Item name and cost in HBox
	var hbox: HBoxContainer = HBoxContainer.new()
	vbox.add_child(hbox)

	var name_label: Label = Label.new()
	name_label.text = item.name
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(name_label)

	var cost_label: Label = Label.new()
	cost_label.text = "$%.2f" % item.cost
	cost_label.custom_minimum_size.x = 100
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hbox.add_child(cost_label)

	# Description
	var desc_label: Label = Label.new()
	desc_label.text = item.description
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(desc_label)

	# Purchase button
	var buy_button: Button = Button.new()

	# Check if unlocked, already owned, and affordable
	var total_revenue: float = ProgressionManager.get_total_revenue()
	var is_unlocked: bool = total_revenue >= item.unlock
	var is_owned: bool = UpgradeManager.is_upgrade_purchased(item.id)
	var can_afford: bool = EconomyManager.can_afford(item.cost)

	if not is_unlocked:
		buy_button.text = "🔒 Locked (Need $%.0f total revenue)" % item.unlock
		buy_button.disabled = true
	elif is_owned:
		buy_button.text = "✓ Owned"
		buy_button.disabled = true
	elif not can_afford:
		buy_button.text = "Can't Afford"
		buy_button.disabled = true
	else:
		buy_button.text = "Purchase"
		buy_button.pressed.connect(_on_purchase_equipment.bind(item))

	vbox.add_child(buy_button)

func _on_purchase_equipment(item: Dictionary) -> void:
	"""Purchase an equipment upgrade"""
	# Check if can afford
	if not EconomyManager.can_afford(item.cost):
		print("Cannot afford %s" % item.name)
		return

	# Charge the cost
	EconomyManager.remove_money(item.cost, "Equipment purchase: %s" % item.name)

	# Queue the equipment for delivery
	DeliveryManager.order_equipment(item.id, item.cost)

	print("Ordered: %s (will arrive tomorrow at 3 AM)" % item.name)

	# Refresh displays
	_update_cash_display()
	_setup_equipment_tab()

# ============================================================================
# INGREDIENTS TAB
# ============================================================================

func _setup_ingredients_tab() -> void:
	"""Set up ingredient ordering UI"""
	if not ingredient_container:
		return

	# Clear existing children
	for child in ingredient_container.get_children():
		child.queue_free()

	# Get all ingredients from balance config
	var ingredients: Dictionary = BalanceConfig.ECONOMY.ingredient_prices
	var ingredient_names: Array = ingredients.keys()
	ingredient_names.sort()

	# Add ingredient ordering rows
	for ingredient_id in ingredient_names:
		if ingredient_id == "water":  # Skip free ingredients
			continue
		_add_ingredient_row(ingredient_id)

	# Add total and purchase button at bottom
	var separator: HSeparator = HSeparator.new()
	ingredient_container.add_child(separator)

	var total_hbox: HBoxContainer = HBoxContainer.new()
	ingredient_container.add_child(total_hbox)

	var total_label: Label = Label.new()
	total_label.text = "Total:"
	total_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	total_label.add_theme_font_size_override("font_size", 18)
	total_hbox.add_child(total_label)

	var total_cost_label: Label = Label.new()
	total_cost_label.text = "$0.00"
	total_cost_label.name = "TotalCostLabel"
	total_cost_label.custom_minimum_size.x = 100
	total_cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	total_cost_label.add_theme_font_size_override("font_size", 18)
	total_hbox.add_child(total_cost_label)

	var purchase_button: Button = Button.new()
	purchase_button.text = "Purchase All Ingredients"
	purchase_button.name = "PurchaseIngredientsButton"
	purchase_button.pressed.connect(_on_purchase_ingredients)
	ingredient_container.add_child(purchase_button)

func _add_ingredient_row(ingredient_id: String) -> void:
	"""Add a row for ordering an ingredient"""
	var hbox: HBoxContainer = HBoxContainer.new()
	ingredient_container.add_child(hbox)

	# Ingredient name
	var name_label: Label = Label.new()
	name_label.text = ingredient_id.capitalize()
	name_label.custom_minimum_size.x = 200
	hbox.add_child(name_label)

	# Price
	var price: float = EconomyManager.get_ingredient_price(ingredient_id)
	var price_label: Label = Label.new()
	price_label.text = "$%.2f" % price
	price_label.custom_minimum_size.x = 70
	hbox.add_child(price_label)

	# Decrease button
	var decrease_button: Button = Button.new()
	decrease_button.text = "-"
	decrease_button.custom_minimum_size.x = 35
	decrease_button.pressed.connect(_on_decrease_ingredient.bind(ingredient_id))
	hbox.add_child(decrease_button)

	# Quantity label
	var quantity_label: Label = Label.new()
	quantity_label.text = "0"
	quantity_label.name = "QuantityLabel_" + ingredient_id
	quantity_label.custom_minimum_size.x = 50
	quantity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hbox.add_child(quantity_label)

	# Increase button
	var increase_button: Button = Button.new()
	increase_button.text = "+"
	increase_button.custom_minimum_size.x = 35
	increase_button.pressed.connect(_on_increase_ingredient.bind(ingredient_id))
	hbox.add_child(increase_button)

	# Subtotal label
	var subtotal_label: Label = Label.new()
	subtotal_label.text = "$0.00"
	subtotal_label.name = "SubtotalLabel_" + ingredient_id
	subtotal_label.custom_minimum_size.x = 80
	subtotal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hbox.add_child(subtotal_label)

func _on_increase_ingredient(ingredient_id: String) -> void:
	"""Increase ingredient order quantity"""
	if not ingredient_cart.has(ingredient_id):
		ingredient_cart[ingredient_id] = 0

	ingredient_cart[ingredient_id] += 1
	_update_ingredient_display(ingredient_id)
	_update_cart_total()

func _on_decrease_ingredient(ingredient_id: String) -> void:
	"""Decrease ingredient order quantity"""
	if not ingredient_cart.has(ingredient_id) or ingredient_cart[ingredient_id] <= 0:
		return

	ingredient_cart[ingredient_id] -= 1
	if ingredient_cart[ingredient_id] == 0:
		ingredient_cart.erase(ingredient_id)

	_update_ingredient_display(ingredient_id)
	_update_cart_total()

func _update_ingredient_display(ingredient_id: String) -> void:
	"""Update the quantity and subtotal labels for an ingredient"""
	var quantity: int = ingredient_cart.get(ingredient_id, 0)
	var price: float = EconomyManager.get_ingredient_price(ingredient_id)
	var subtotal: float = quantity * price

	# Find labels
	var quantity_label: Label = ingredient_container.find_child("QuantityLabel_" + ingredient_id, true, false)
	var subtotal_label: Label = ingredient_container.find_child("SubtotalLabel_" + ingredient_id, true, false)

	if quantity_label:
		quantity_label.text = str(quantity)

	if subtotal_label:
		subtotal_label.text = "$%.2f" % subtotal

func _update_cart_total() -> void:
	"""Update the total cart cost"""
	var total: float = _calculate_cart_total()

	var total_label: Label = ingredient_container.find_child("TotalCostLabel", true, false)
	if total_label:
		total_label.text = "$%.2f" % total

	# Enable/disable purchase button based on affordability
	var purchase_button: Button = ingredient_container.find_child("PurchaseIngredientsButton", true, false)
	if purchase_button:
		purchase_button.disabled = total <= 0 or not EconomyManager.can_afford(total)

func _calculate_cart_total() -> float:
	"""Calculate total cost of ingredient cart"""
	var total: float = 0.0
	for ingredient_id in ingredient_cart:
		var quantity: int = ingredient_cart[ingredient_id]
		var price: float = EconomyManager.get_ingredient_price(ingredient_id)
		total += quantity * price
	return total

func _on_purchase_ingredients() -> void:
	"""Purchase all ingredients in the cart"""
	var total_cost: float = _calculate_cart_total()

	if total_cost <= 0:
		print("Cart is empty!")
		return

	if not EconomyManager.can_afford(total_cost):
		print("Cannot afford this order!")
		return

	# Process payment
	EconomyManager.remove_money(total_cost, "Ingredient order")

	# Queue ingredients for delivery
	print("\n=== INGREDIENT ORDER PLACED ===")
	for ingredient_id in ingredient_cart:
		var quantity: int = ingredient_cart[ingredient_id]
		var price: float = EconomyManager.get_ingredient_price(ingredient_id)
		var item_cost: float = quantity * price
		DeliveryManager.order_ingredient(ingredient_id, quantity, item_cost)
		print("Ordered: %dx %s" % [quantity, ingredient_id])
	print("Total: $%.2f" % total_cost)
	print("Items will arrive tomorrow at 3 AM")
	print("================================\n")

	# Clear cart
	ingredient_cart.clear()

	# Refresh displays
	_update_cash_display()
	_setup_ingredients_tab()

# ============================================================================
# DECORATIONS TAB
# ============================================================================

func _setup_decorations_tab() -> void:
	"""Set up decorations purchase UI"""
	if not decoration_container:
		return

	# Clear existing children
	for child in decoration_container.get_children():
		child.queue_free()

	# Add decoration categories
	_add_decoration_section("Wall Paint", [
		{"id": "fresh_paint_white", "name": "Fresh White Paint", "cost": BalanceConfig.EQUIPMENT.fresh_paint_white_cost, "unlock": 0, "ambiance": BalanceConfig.EQUIPMENT.fresh_paint_white_ambiance, "description": "Clean white walls (+%d ambiance)" % BalanceConfig.EQUIPMENT.fresh_paint_white_ambiance},
		{"id": "warm_cream_paint", "name": "Warm Cream Paint", "cost": BalanceConfig.EQUIPMENT.warm_cream_paint_cost, "unlock": BalanceConfig.EQUIPMENT.warm_cream_paint_unlock, "ambiance": BalanceConfig.EQUIPMENT.warm_cream_paint_ambiance, "description": "Cozy cream walls (+%d ambiance)" % BalanceConfig.EQUIPMENT.warm_cream_paint_ambiance},
	])

	_add_decoration_section("Furniture", [
		{"id": "wooden_table", "name": "Wooden Table", "cost": BalanceConfig.EQUIPMENT.wooden_table_cost, "unlock": 0, "ambiance": BalanceConfig.EQUIPMENT.wooden_table_ambiance, "description": "Simple wooden table (+%d ambiance)" % BalanceConfig.EQUIPMENT.wooden_table_ambiance},
		{"id": "marble_table", "name": "Marble Table", "cost": BalanceConfig.EQUIPMENT.marble_table_cost, "unlock": BalanceConfig.EQUIPMENT.marble_table_unlock, "ambiance": BalanceConfig.EQUIPMENT.marble_table_ambiance, "description": "Elegant marble table (+%d ambiance)" % BalanceConfig.EQUIPMENT.marble_table_ambiance},
		{"id": "antique_table", "name": "Antique Table", "cost": BalanceConfig.EQUIPMENT.antique_table_cost, "unlock": BalanceConfig.EQUIPMENT.antique_table_unlock, "ambiance": BalanceConfig.EQUIPMENT.antique_table_ambiance, "description": "Vintage antique table (+%d ambiance)" % BalanceConfig.EQUIPMENT.antique_table_ambiance},
	])

	_add_decoration_section("Structural Upgrades", [
		{"id": "wall_repair", "name": "Wall Repair", "cost": BalanceConfig.EQUIPMENT.wall_repair_cost, "unlock": 0, "ambiance": BalanceConfig.EQUIPMENT.wall_repair_ambiance, "description": "Fix cracks and damage (+%d ambiance)" % BalanceConfig.EQUIPMENT.wall_repair_ambiance},
		{"id": "seating_expansion", "name": "Seating Expansion", "cost": BalanceConfig.EQUIPMENT.seating_expansion_cost, "unlock": BalanceConfig.EQUIPMENT.seating_expansion_unlock, "ambiance": 0, "description": "Add 5 more customer seats"},
		{"id": "kitchen_expansion", "name": "Kitchen Expansion", "cost": BalanceConfig.EQUIPMENT.kitchen_expansion_cost, "unlock": BalanceConfig.EQUIPMENT.kitchen_expansion_unlock, "ambiance": 0, "description": "Add 2 more equipment slots"},
	])

func _add_decoration_section(section_name: String, items: Array) -> void:
	"""Add a section of decoration items"""
	# Section header
	var header: Label = Label.new()
	header.text = "--- %s ---" % section_name
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 18)
	decoration_container.add_child(header)

	# Add items
	for item in items:
		_add_decoration_card(item)

	# Spacer
	var spacer: Control = Control.new()
	spacer.custom_minimum_size.y = 10
	decoration_container.add_child(spacer)

func _add_decoration_card(item: Dictionary) -> void:
	"""Add a decoration purchase card"""
	var panel: PanelContainer = PanelContainer.new()
	decoration_container.add_child(panel)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	panel.add_child(vbox)

	# Item name and cost in HBox
	var hbox: HBoxContainer = HBoxContainer.new()
	vbox.add_child(hbox)

	var name_label: Label = Label.new()
	name_label.text = item.name
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(name_label)

	var cost_label: Label = Label.new()
	cost_label.text = "$%.2f" % item.cost
	cost_label.custom_minimum_size.x = 100
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hbox.add_child(cost_label)

	# Description
	var desc_label: Label = Label.new()
	desc_label.text = item.description
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(desc_label)

	# Purchase button
	var buy_button: Button = Button.new()

	# Check if unlocked, already owned, and affordable
	var total_revenue: float = ProgressionManager.get_total_revenue()
	var is_unlocked: bool = total_revenue >= item.unlock
	var is_owned: bool = UpgradeManager.is_upgrade_purchased(item.id)
	var can_afford: bool = EconomyManager.can_afford(item.cost)

	if not is_unlocked:
		buy_button.text = "🔒 Locked (Need $%.0f total revenue)" % item.unlock
		buy_button.disabled = true
	elif is_owned:
		buy_button.text = "✓ Owned"
		buy_button.disabled = true
	elif not can_afford:
		buy_button.text = "Can't Afford"
		buy_button.disabled = true
	else:
		buy_button.text = "Purchase"
		buy_button.pressed.connect(_on_purchase_decoration.bind(item))

	vbox.add_child(buy_button)

func _on_purchase_decoration(item: Dictionary) -> void:
	"""Purchase a decoration"""
	# Check if can afford
	if not EconomyManager.can_afford(item.cost):
		print("Cannot afford %s" % item.name)
		return

	# Charge the cost
	EconomyManager.remove_money(item.cost, "Decoration purchase: %s" % item.name)

	# Queue the decoration for delivery
	DeliveryManager.order_decoration(item.id, item.cost)

	print("Ordered: %s (+%d ambiance) (will arrive tomorrow at 3 AM)" % [item.name, item.get("ambiance", 0)])

	# Refresh displays
	_update_cash_display()
	_setup_decorations_tab()
