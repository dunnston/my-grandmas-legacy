extends Control

# BulkOrderTracker - UI widget that shows active bulk orders
# Displays in top-right corner during gameplay

# Node references
@onready var panel: PanelContainer = $Panel
@onready var orders_container: VBoxContainer = $Panel/MarginContainer/VBox/OrdersContainer
@onready var no_orders_label: Label = $Panel/MarginContainer/VBox/OrdersContainer/NoOrdersLabel

func _ready() -> void:
	# Connect to EventManager signals
	if EventManager:
		EventManager.bulk_order_created.connect(_on_bulk_order_created)
		EventManager.bulk_order_progress.connect(_on_bulk_order_progress)
		EventManager.bulk_order_completed.connect(_on_bulk_order_completed)

	# Start hidden
	hide()

	print("BulkOrderTracker initialized")

func _on_bulk_order_created(order_data: Dictionary) -> void:
	"""A new bulk order was created"""
	show()
	_refresh_orders()

func _on_bulk_order_progress(order_id: String, delivered: int, total: int) -> void:
	"""Progress was made on a bulk order"""
	_refresh_orders()

func _on_bulk_order_completed(order_id: String, success: bool, reward: Dictionary) -> void:
	"""A bulk order was completed"""
	_refresh_orders()

	# Hide if no more orders
	if not EventManager.has_active_bulk_order():
		hide()

func _refresh_orders() -> void:
	"""Refresh the display of active orders"""
	# Clear existing order displays (except no orders label)
	for child in orders_container.get_children():
		if child != no_orders_label:
			child.queue_free()

	var orders: Array = EventManager.get_active_bulk_orders()

	if orders.is_empty():
		no_orders_label.show()
		return

	no_orders_label.hide()

	# Create UI for each order
	for order in orders:
		_add_order_display(order)

func _add_order_display(order: Dictionary) -> void:
	"""Add a display widget for a bulk order"""
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	orders_container.add_child(vbox)

	# Item name and quantity
	var item_id: String = order.get("item_id", "unknown")
	var item_name: String = RecipeManager.get_recipe(item_id).get("name", item_id.capitalize())
	var quantity_requested: int = order.get("quantity_requested", 0)
	var quantity_delivered: int = order.get("quantity_delivered", 0)

	var header: Label = Label.new()
	header.text = "%s x%d" % [item_name, quantity_requested]
	header.add_theme_font_size_override("font_size", 14)
	vbox.add_child(header)

	# Progress bar
	var progress_bar: ProgressBar = ProgressBar.new()
	progress_bar.min_value = 0
	progress_bar.max_value = quantity_requested
	progress_bar.value = quantity_delivered
	progress_bar.show_percentage = false
	progress_bar.custom_minimum_size.y = 20
	vbox.add_child(progress_bar)

	# Progress text
	var progress_label: Label = Label.new()
	progress_label.text = "%d / %d delivered" % [quantity_delivered, quantity_requested]
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(progress_label)

	# Deadline warning
	var deadline_label: Label = Label.new()
	deadline_label.text = "⏰ Due: End of day"
	deadline_label.add_theme_font_size_override("font_size", 11)
	deadline_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))  # Yellow warning
	vbox.add_child(deadline_label)

	# Reward preview
	var base_recipe: Dictionary = RecipeManager.get_recipe(item_id)
	var base_price: float = base_recipe.get("sell_price", 5.0)
	var reward_multiplier: float = order.get("reward_multiplier", 1.5)
	var reward_cash: float = base_price * quantity_requested * reward_multiplier

	var reward_label: Label = Label.new()
	reward_label.text = "💰 Reward: $%.2f + reputation" % reward_cash
	reward_label.add_theme_font_size_override("font_size", 11)
	reward_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))  # Green
	vbox.add_child(reward_label)

	# Separator
	var separator: HSeparator = HSeparator.new()
	vbox.add_child(separator)
