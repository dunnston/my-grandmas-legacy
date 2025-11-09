extends EquipmentUIBase

# MixingBowlUI - For mixing bowl interaction
# Shows ingredient slots on left, player inventory on right
# Shows mixing timer and finished product slot

var mixing_bowl_script: Node = null

# Additional UI components
var timer_label: Label
var status_label: Label
var finished_product_button: Button

var status_container: VBoxContainer
var status_display_created: bool = false

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

func _create_status_display() -> void:
	"""Create timer and status labels (called lazily on first open)"""
	if status_display_created or not equipment_container:
		return

	status_container = VBoxContainer.new()
	status_container.custom_minimum_size = Vector2(0, 60)

	status_label = Label.new()
	status_label.text = "Idle"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_container.add_child(status_label)

	timer_label = Label.new()
	timer_label.text = ""
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_container.add_child(timer_label)

	# Add to equipment side, after label
	var parent = equipment_container.get_parent()
	if parent:
		parent.add_child(status_container)
		parent.move_child(status_container, 1)
		status_display_created = true

func open_ui_with_equipment(equipment_inv_id: String, player_inv_id: String, equipment_node: Node) -> void:
	"""Open UI with reference to mixing bowl equipment"""
	mixing_bowl_script = equipment_node
	_create_status_display()  # Create status display on first open
	open_ui(equipment_inv_id, player_inv_id)

func _process(delta: float) -> void:
	if not visible or not mixing_bowl_script:
		return

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
	"""Override to show available recipes instead of ingredients"""
	# Clear existing buttons
	for child in equipment_container.get_children():
		equipment_container.remove_child(child)
		child.queue_free()
	equipment_buttons.clear()

	# If currently mixing or has finished product, show that state
	if mixing_bowl_script and (mixing_bowl_script.is_mixing or mixing_bowl_script.has_finished_item):
		_show_mixing_state()
		return

	# Show unlocked recipes
	var recipes_label = Label.new()
	recipes_label.text = "Available Recipes (hover for ingredients):"
	recipes_label.modulate = Color(0.9, 0.9, 0.9)
	equipment_container.add_child(recipes_label)
	equipment_buttons.append(recipes_label)

	var separator = HSeparator.new()
	equipment_container.add_child(separator)
	equipment_buttons.append(separator)

	# Get player inventory
	var player_inv = InventoryManager.get_inventory(player_inventory_id)

	# Get all unlocked recipes
	var unlocked_recipes = RecipeManager.get_all_unlocked_recipes()

	if unlocked_recipes.is_empty():
		var no_recipes_label = Label.new()
		no_recipes_label.text = "No recipes unlocked yet!"
		no_recipes_label.modulate = Color(0.6, 0.6, 0.6)
		equipment_container.add_child(no_recipes_label)
		equipment_buttons.append(no_recipes_label)
		return

	# Show each recipe as a button
	for recipe in unlocked_recipes:
		var recipe_button = _create_recipe_button(recipe, player_inv)
		equipment_container.add_child(recipe_button)
		equipment_buttons.append(recipe_button)

func _show_mixing_state() -> void:
	"""Show mixing progress or finished product"""
	if mixing_bowl_script.has_finished_item:
		var finished_label = Label.new()
		finished_label.text = "Finished Product:"
		finished_label.modulate = Color(0.2, 0.8, 0.2)
		equipment_container.add_child(finished_label)
		equipment_buttons.append(finished_label)

		finished_product_button = Button.new()
		finished_product_button.text = "✓ %s (Click to collect)" % _get_item_display_name(mixing_bowl_script.current_item)
		finished_product_button.custom_minimum_size = Vector2(200, 50)
		finished_product_button.modulate = Color(0.2, 1.0, 0.2)
		finished_product_button.pressed.connect(_on_collect_finished_product)
		equipment_container.add_child(finished_product_button)
		equipment_buttons.append(finished_product_button)
	else:
		var mixing_label = Label.new()
		mixing_label.text = "Mixing in progress..."
		mixing_label.modulate = Color(1.0, 0.8, 0.2)
		equipment_container.add_child(mixing_label)
		equipment_buttons.append(mixing_label)

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
	var ingredients = recipe.get("ingredients", {})
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
	var ingredients = recipe.get("ingredients", {})
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

	var ingredients = recipe.get("ingredients", {})
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
