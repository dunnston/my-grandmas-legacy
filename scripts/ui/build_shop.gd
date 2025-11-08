extends VBoxContainer

# BuildShop - UI for browsing and purchasing placeable furniture/decorations
# Integrated into Planning Menu as a tab

# Signals
signal item_purchased(item_id: String)

# Node references
var category_tabs: TabContainer
var item_list: VBoxContainer
var info_panel: Panel
var purchase_button: Button

# Current selection
var selected_item_id: String = ""
var current_category: String = "furniture"

func _ready() -> void:
	_setup_ui()
	_refresh_items()

func _setup_ui() -> void:
	# Title
	var title = Label.new()
	title.text = "Build & Decorate Shop"
	title.add_theme_font_size_override("font_size", 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)

	# Category tabs
	category_tabs = TabContainer.new()
	category_tabs.custom_minimum_size.y = 400
	add_child(category_tabs)

	# Create tabs for each category
	_create_category_tab("Furniture", "furniture")
	_create_category_tab("Decorations", "decoration")
	_create_category_tab("Equipment", "equipment")

	category_tabs.tab_changed.connect(_on_category_changed)

	# Instructions
	var instructions = Label.new()
	instructions.text = "Purchase items to unlock them, then place them in your bakery during the Baking phase!"
	instructions.autowrap_mode = TextServer.AUTOWRAP_WORD
	add_child(instructions)

	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size.y = 10
	add_child(spacer)

func _create_category_tab(tab_name: String, category: String) -> void:
	var scroll = ScrollContainer.new()
	scroll.name = tab_name
	category_tabs.add_child(scroll)

	var container = VBoxContainer.new()
	container.name = "ItemList_" + category
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(container)

func _on_category_changed(tab: int) -> void:
	match tab:
		0:
			current_category = "furniture"
		1:
			current_category = "decoration"
		2:
			current_category = "equipment"
	_refresh_items()

func _refresh_items() -> void:
	"""Refresh the item list for the current category"""
	var container_name = "ItemList_" + current_category
	var container: VBoxContainer = null

	# Find the container
	for tab in category_tabs.get_children():
		var found = tab.get_node_or_null(container_name)
		if found:
			container = found
			break

	if not container:
		print("Container not found: %s" % container_name)
		return

	# Clear existing items
	for child in container.get_children():
		child.queue_free()

	# Get upgrades for this category
	var upgrades = UpgradeManager.get_upgrades_by_category(current_category)

	# Group by subcategory
	var by_subcategory: Dictionary = {}
	for upgrade_id in upgrades.keys():
		var upgrade = upgrades[upgrade_id]
		var subcategory = upgrade.get("subcategory", "other")

		if not by_subcategory.has(subcategory):
			by_subcategory[subcategory] = []

		by_subcategory[subcategory].append({
			"id": upgrade_id,
			"data": upgrade
		})

	# Display grouped items
	for subcategory in by_subcategory.keys():
		# Subcategory header
		var header = Label.new()
		header.text = subcategory.capitalize()
		header.add_theme_font_size_override("font_size", 18)
		header.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0))
		container.add_child(header)

		# Items in this subcategory
		for item in by_subcategory[subcategory]:
			_add_item_row(container, item.id, item.data)

		# Spacer
		var spacer = Control.new()
		spacer.custom_minimum_size.y = 10
		container.add_child(spacer)

func _add_item_row(container: VBoxContainer, item_id: String, upgrade: Dictionary) -> void:
	"""Add a row for a purchasable item"""
	var panel = Panel.new()
	panel.custom_minimum_size.y = 80
	container.add_child(panel)

	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(hbox)

	# Left side - Item info
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)

	# Name
	var name_label = Label.new()
	name_label.text = upgrade.get("name", item_id)
	name_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(name_label)

	# Description
	var desc_label = Label.new()
	desc_label.text = upgrade.get("description", "")
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(desc_label)

	# Stats
	var stats_label = Label.new()
	var stats_text = ""

	if upgrade.has("ambiance_bonus"):
		stats_text += "Ambiance: +%d  " % upgrade.ambiance_bonus
	if upgrade.has("equipment_tier"):
		stats_text += "Quality: +%d%%  " % (upgrade.equipment_tier * 2)
	if upgrade.has("capacity_bonus"):
		stats_text += "Capacity: +%d  " % upgrade.capacity_bonus

	stats_label.text = stats_text
	stats_label.add_theme_font_size_override("font_size", 12)
	stats_label.add_theme_color_override("font_color", Color(0.7, 1.0, 0.7))
	vbox.add_child(stats_label)

	# Right side - Price and button
	var right_vbox = VBoxContainer.new()
	right_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(right_vbox)

	# Price
	var price_label = Label.new()
	price_label.text = "$%.2f" % upgrade.get("cost", 0.0)
	price_label.add_theme_font_size_override("font_size", 18)
	price_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.5))
	right_vbox.add_child(price_label)

	# Check status
	var is_purchased = UpgradeManager.is_upgrade_purchased(item_id)
	var is_unlocked = UpgradeManager.is_upgrade_unlocked(item_id)
	var can_afford = EconomyManager.can_afford(upgrade.get("cost", 0.0))

	# Purchase/Place button
	var button = Button.new()
	button.custom_minimum_size.x = 120

	if is_purchased:
		button.text = "Place"
		button.pressed.connect(_on_place_item.bind(item_id))
	elif not is_unlocked:
		button.text = "Locked"
		button.disabled = true
		var unlock_revenue = upgrade.get("unlock_revenue", 0)
		button.tooltip_text = "Requires $%.2f total revenue" % unlock_revenue
	elif not can_afford:
		button.text = "Can't Afford"
		button.disabled = true
	else:
		button.text = "Purchase"
		button.pressed.connect(_on_purchase_item.bind(item_id))

	right_vbox.add_child(button)

	# Owned count (if purchased)
	if is_purchased:
		var owned_count = BuildingManager.get_placed_objects_by_id(item_id).size()
		if owned_count > 0:
			var count_label = Label.new()
			count_label.text = "Placed: %d" % owned_count
			count_label.add_theme_font_size_override("font_size", 10)
			right_vbox.add_child(count_label)

func _on_purchase_item(item_id: String) -> void:
	"""Purchase an item"""
	if UpgradeManager.purchase_upgrade(item_id):
		print("Purchased: %s" % item_id)
		item_purchased.emit(item_id)
		_refresh_items()  # Refresh to update button states

		# Show success message
		_show_message("Item purchased! You can now place it in your bakery.")
	else:
		_show_message("Failed to purchase item.")

func _on_place_item(item_id: String) -> void:
	"""Enter placement mode for an item"""
	# Close the planning menu
	var planning_menu = get_tree().get_first_node_in_group("planning_menu")
	if planning_menu:
		planning_menu.close_menu()

	# Start placement mode
	if BuildingManager.start_placement(item_id):
		print("Entering placement mode: %s" % item_id)
	else:
		_show_message("Failed to enter placement mode.")

func _show_message(text: String) -> void:
	"""Show a temporary message to the player"""
	# TODO: Implement proper notification system
	print("MESSAGE: %s" % text)
