extends EquipmentUIBase

# MixingBowlUI - For mixing bowl interaction
# Shows ingredient slots on left, player inventory on right
# Shows mixing timer and finished product slot

var mixing_bowl_script: Node = null

# Additional UI components
var timer_label: Label
var status_label: Label
var finished_product_button: Button

# Dedicated containers to prevent overlap
var status_container: VBoxContainer  # For status/timer labels
var items_container: VBoxContainer   # For finished products/mixing state
var containers_created: bool = false

# Track previous state to detect changes
var previous_is_mixing: bool = false
var previous_has_finished: bool = false

# Tooltip for showing ingredients on hover
var ingredient_tooltip: PanelContainer
var tooltip_label: RichTextLabel

func _ready() -> void:
	super._ready()
	if equipment_label:
		equipment_label.text = "Mixing Bowl"
	_create_ingredient_tooltip()

func _create_ingredient_tooltip() -> void:
	"""Create the tooltip that shows ingredients on hover"""
	ingredient_tooltip = PanelContainer.new()
	ingredient_tooltip.visible = false
	ingredient_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't block mouse events

	# Style the tooltip
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.95)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.3, 0.3)
	ingredient_tooltip.add_theme_stylebox_override("panel", style)

	tooltip_label = RichTextLabel.new()
	tooltip_label.bbcode_enabled = true
	tooltip_label.fit_content = true
	tooltip_label.custom_minimum_size = Vector2(250, 0)
	ingredient_tooltip.add_child(tooltip_label)

	# Add to main UI
	add_child(ingredient_tooltip)

func _create_containers() -> void:
	"""Create dedicated containers for status and items (called lazily on first open)"""
	if containers_created or not equipment_container:
		return

	# Get the EquipmentSide VBoxContainer (parent of ScrollContainer)
	var scroll_container = equipment_container.get_parent()
	if not scroll_container:
		push_error("MixingBowlUI: Could not find ScrollContainer")
		return

	var equipment_side = scroll_container.get_parent()
	if not equipment_side:
		push_error("MixingBowlUI: Could not find EquipmentSide VBoxContainer")
		return

	# === STATUS CONTAINER ===
	# Shows "Mixing..." / "Ready!" / "Idle" + timer
	status_container = VBoxContainer.new()
	status_container.custom_minimum_size = Vector2(0, 70)
	status_container.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	status_container.add_theme_constant_override("separation", 8)

	# Add visual background to status area
	var status_bg = StyleBoxFlat.new()
	status_bg.bg_color = Color(0.15, 0.15, 0.2, 0.9)
	status_bg.corner_radius_top_left = 4
	status_bg.corner_radius_top_right = 4
	status_bg.corner_radius_bottom_left = 4
	status_bg.corner_radius_bottom_right = 4
	status_bg.content_margin_top = 8
	status_bg.content_margin_bottom = 8
	status_bg.content_margin_left = 10
	status_bg.content_margin_right = 10
	var status_panel = PanelContainer.new()
	status_panel.add_theme_stylebox_override("panel", status_bg)
	status_container.add_child(status_panel)

	# Create inner VBox for labels
	var status_labels_container = VBoxContainer.new()
	status_labels_container.add_theme_constant_override("separation", 5)
	status_panel.add_child(status_labels_container)

	status_label = Label.new()
	status_label.text = "Idle"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	status_labels_container.add_child(status_label)

	timer_label = Label.new()
	timer_label.text = ""
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	timer_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	status_labels_container.add_child(timer_label)

	# === ITEMS CONTAINER ===
	# Shows finished products, "Mixing in progress", or "Select a recipe"
	var items_outer_container = VBoxContainer.new()
	items_outer_container.custom_minimum_size = Vector2(0, 100)
	items_outer_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	items_outer_container.add_theme_constant_override("separation", 8)

	# Add visual background to items area
	var items_bg = StyleBoxFlat.new()
	items_bg.bg_color = Color(0.1, 0.1, 0.12, 0.9)
	items_bg.corner_radius_top_left = 4
	items_bg.corner_radius_top_right = 4
	items_bg.corner_radius_bottom_left = 4
	items_bg.corner_radius_bottom_right = 4
	items_bg.content_margin_top = 10
	items_bg.content_margin_bottom = 10
	items_bg.content_margin_left = 10
	items_bg.content_margin_right = 10
	var items_panel = PanelContainer.new()
	items_panel.add_theme_stylebox_override("panel", items_bg)
	items_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	items_outer_container.add_child(items_panel)

	# Create inner container for items
	items_container = VBoxContainer.new()
	items_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	items_container.add_theme_constant_override("separation", 8)
	items_panel.add_child(items_container)

	# Add both containers to EquipmentSide, after the label
	equipment_side.add_child(status_container)
	equipment_side.add_child(items_outer_container)

	# Move them to be after the label (position 1 and 2)
	equipment_side.move_child(status_container, 1)
	equipment_side.move_child(items_outer_container, 2)

	containers_created = true
	print("MixingBowlUI: Created dedicated status and items containers")

func open_ui_with_equipment(equipment_inv_id: String, player_inv_id: String, equipment_node: Node) -> void:
	"""Open UI with reference to mixing bowl equipment"""
	mixing_bowl_script = equipment_node
	_create_containers()  # Create dedicated containers on first open

	# Update right side label to "Your Recipes"
	if player_label:
		player_label.text = "Your Recipes"

	open_ui(equipment_inv_id, player_inv_id)

func _process(delta: float) -> void:
	if not visible or not mixing_bowl_script:
		return

	# Detect state changes
	var current_is_mixing = mixing_bowl_script.is_mixing
	var current_has_finished = mixing_bowl_script.has_finished_item

	var state_changed = (current_is_mixing != previous_is_mixing or
						 current_has_finished != previous_has_finished)

	# Update previous state
	previous_is_mixing = current_is_mixing
	previous_has_finished = current_has_finished

	# If state changed, refresh both sides of the UI
	if state_changed:
		_refresh_equipment_inventory()
		_refresh_player_inventory()

	# Update timer display
	if mixing_bowl_script.is_mixing:
		var progress = mixing_bowl_script.mixing_timer
		var total = mixing_bowl_script.target_mix_time
		var remaining = total - progress

		status_label.text = "Mixing..."
		timer_label.text = "Time remaining: %.1fs / %.1fs" % [remaining, total]

		# Show progress bar
		var percent = (progress / total) * 100
		timer_label.text += " (%.0f%%)" % percent
	elif mixing_bowl_script.has_finished_item:
		status_label.text = "Ready!"
		timer_label.text = "Click finished product to collect"
	else:
		status_label.text = "Idle"
		timer_label.text = "Add ingredients to start"

func _refresh_equipment_inventory() -> void:
	"""Override to show mixing state in items container"""
	if not items_container:
		return

	# Clear existing items
	for child in items_container.get_children():
		items_container.remove_child(child)
		child.queue_free()
	equipment_buttons.clear()

	# Show mixing state or idle message
	if mixing_bowl_script and (mixing_bowl_script.is_mixing or mixing_bowl_script.has_finished_item):
		_show_mixing_state()
	else:
		# Show idle message
		var idle_label = Label.new()
		idle_label.text = "Select a recipe to begin"
		idle_label.modulate = Color(0.7, 0.7, 0.7)
		idle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		idle_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		idle_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		items_container.add_child(idle_label)
		# Don't append labels to equipment_buttons (typed as Array[Button])

func _refresh_player_inventory() -> void:
	"""Override to show available recipes instead of player inventory"""
	# Clear existing buttons
	for child in player_container.get_children():
		player_container.remove_child(child)
		child.queue_free()
	player_buttons.clear()

	# Don't show recipes while mixing or when finished product is ready
	if mixing_bowl_script and (mixing_bowl_script.is_mixing or mixing_bowl_script.has_finished_item):
		var waiting_label = Label.new()
		if mixing_bowl_script.has_finished_item:
			waiting_label.text = "Collect finished product\nfrom left side →"
		else:
			waiting_label.text = "Mixing in progress...\nPlease wait"
		waiting_label.modulate = Color(0.7, 0.7, 0.7)
		waiting_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		waiting_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		waiting_label.custom_minimum_size = Vector2(200, 50)
		player_container.add_child(waiting_label)
		# Don't append labels to player_buttons (typed as Array[Button])
		return

	# Show hint text
	var hint_label = Label.new()
	hint_label.text = "Hover for ingredients"
	hint_label.modulate = Color(0.6, 0.6, 0.6)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.custom_minimum_size = Vector2(200, 20)
	player_container.add_child(hint_label)
	# Don't append labels to player_buttons

	var separator = HSeparator.new()
	player_container.add_child(separator)
	# Don't append separators to player_buttons

	# Get player inventory
	var player_inv = InventoryManager.get_inventory(player_inventory_id)

	# Get all unlocked recipes
	var unlocked_recipes = RecipeManager.get_all_unlocked_recipes()

	if unlocked_recipes.is_empty():
		var no_recipes_label = Label.new()
		no_recipes_label.text = "No recipes unlocked yet!"
		no_recipes_label.modulate = Color(0.6, 0.6, 0.6)
		no_recipes_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_recipes_label.custom_minimum_size = Vector2(200, 25)
		player_container.add_child(no_recipes_label)
		# Don't append labels to player_buttons (typed as Array[Button])
		return

	# Show each recipe as a button
	for recipe in unlocked_recipes:
		var recipe_button = _create_recipe_button(recipe, player_inv)
		player_container.add_child(recipe_button)
		player_buttons.append(recipe_button)

func _show_mixing_state() -> void:
	"""Show mixing progress or finished product in items container"""
	if not items_container:
		return

	if mixing_bowl_script.has_finished_item:
		var finished_label = Label.new()
		finished_label.text = "Finished Product:"
		finished_label.modulate = Color(0.2, 0.8, 0.2)
		finished_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		finished_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		finished_label.custom_minimum_size = Vector2(200, 30)
		items_container.add_child(finished_label)
		# Don't append label to equipment_buttons (typed as Array[Button])

		finished_product_button = Button.new()
		finished_product_button.text = "✓ %s\n(Click to collect)" % _get_item_display_name(mixing_bowl_script.current_item)
		finished_product_button.custom_minimum_size = Vector2(200, 60)
		finished_product_button.modulate = Color(0.2, 1.0, 0.2)
		finished_product_button.pressed.connect(_on_collect_finished_product)
		items_container.add_child(finished_product_button)
		equipment_buttons.append(finished_product_button)
	else:
		var mixing_label = Label.new()
		mixing_label.text = "Mixing in progress..."
		mixing_label.modulate = Color(1.0, 0.8, 0.2)
		mixing_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		mixing_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		mixing_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		items_container.add_child(mixing_label)
		# Don't append label to equipment_buttons (typed as Array[Button])

func _create_recipe_button(recipe: Dictionary, player_inv: Dictionary) -> Button:
	"""Create a recipe button with color coding based on availability"""
	var button = Button.new()
	button.text = recipe.get("name", "Unknown Recipe")
	button.custom_minimum_size = Vector2(200, 40)

	# Check if player has all ingredients
	var has_all_ingredients = _check_has_ingredients(recipe, player_inv)

	# Set background color based on availability
	var style = StyleBoxFlat.new()
	if has_all_ingredients:
		style.bg_color = Color(0.2, 0.5, 0.2, 0.8)  # Green
		button.modulate = Color(1.0, 1.0, 1.0)
	else:
		style.bg_color = Color(0.5, 0.2, 0.2, 0.8)  # Red
		button.modulate = Color(0.8, 0.8, 0.8)

	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)

	# Connect signals
	button.pressed.connect(_on_recipe_selected.bind(recipe))
	button.mouse_entered.connect(_on_recipe_hover.bind(recipe, player_inv))
	button.mouse_exited.connect(_on_recipe_hover_exit)

	return button

func _check_has_ingredients(recipe: Dictionary, player_inv: Dictionary) -> bool:
	"""Check if player has all required ingredients"""
	var ingredients = recipe["ingredients"] if recipe.has("ingredients") else {}
	for ingredient_id in ingredients.keys():
		var required = ingredients[ingredient_id]
		var have = player_inv.get(ingredient_id, 0)
		if have < required:
			return false
	return true

func _on_recipe_selected(recipe: Dictionary) -> void:
	"""Player clicked a recipe - start crafting it"""
	if not mixing_bowl_script:
		return

	# Check if player has ingredients
	var player_inv = InventoryManager.get_inventory(player_inventory_id)
	if not _check_has_ingredients(recipe, player_inv):
		print("You don't have all the ingredients for %s!" % recipe.get("name", "this recipe"))
		return

	# Transfer ingredients from player to mixing bowl
	var ingredients = recipe["ingredients"] if recipe.has("ingredients") else {}
	for ingredient_id in ingredients.keys():
		var amount = ingredients[ingredient_id]
		if not InventoryManager.transfer_item(player_inventory_id, equipment_inventory_id, ingredient_id, amount):
			print("Error transferring ingredient: %s" % ingredient_id)
			# TODO: Rollback previous transfers
			return

	# Start mixing
	print("Starting to mix: %s" % recipe.get("name", ""))
	mixing_bowl_script.start_crafting(recipe, recipe["id"])
	_refresh_inventories()

func _on_recipe_hover(recipe: Dictionary, player_inv: Dictionary) -> void:
	"""Show ingredient tooltip when hovering over recipe"""
	if not ingredient_tooltip or not tooltip_label:
		return

	# Build ingredient list with color coding
	var tooltip_text = "[b]%s[/b]\n\n[u]Ingredients:[/u]\n" % recipe.get("name", "Recipe")

	var ingredients = recipe["ingredients"] if recipe.has("ingredients") else {}
	for ingredient_id in ingredients.keys():
		var required = ingredients[ingredient_id]
		var have = player_inv.get(ingredient_id, 0)
		var ingredient_name = _get_item_display_name(ingredient_id)

		if have >= required:
			# Has enough - show in green with checkmark
			tooltip_text += "[color=#00FF00]✓ %s: %d/%d[/color]\n" % [ingredient_name, have, required]
		else:
			# Missing some - show in red with X and amount needed
			var missing = required - have
			tooltip_text += "[color=#FF0000]✗ %s: %d/%d (need %d more)[/color]\n" % [ingredient_name, have, required, missing]

	tooltip_label.text = tooltip_text

	# Position tooltip near mouse
	ingredient_tooltip.visible = true
	ingredient_tooltip.position = get_local_mouse_position() + Vector2(10, 10)

func _on_recipe_hover_exit() -> void:
	"""Hide tooltip when mouse leaves recipe button"""
	if ingredient_tooltip:
		ingredient_tooltip.visible = false

func _on_collect_finished_product() -> void:
	"""Collect finished product from mixing bowl"""
	if not mixing_bowl_script or not mixing_bowl_script.has_finished_item:
		return

	var item_id = mixing_bowl_script.current_item

	# Remove from mixing bowl
	InventoryManager.remove_item(equipment_inventory_id, item_id, 1)

	# Add to player
	InventoryManager.add_item(player_inventory_id, item_id, 1)

	# Clear mixing bowl state
	mixing_bowl_script.has_finished_item = false
	mixing_bowl_script.current_item = ""

	print("Collected %s from mixing bowl" % item_id)

	# Refresh display
	_refresh_inventories()
