extends VBoxContainer

# StaffHiringPanel - UI component for the Staff tab in Planning Menu
# Basic staff hiring functionality

# Node references
var current_staff_container: VBoxContainer
var applicants_container: VBoxContainer
var wages_label: Label
var capacity_label: Label

func _ready() -> void:
	_build_ui()
	refresh_display()

	# Connect to StaffManager signals
	if StaffManager:
		StaffManager.staff_hired.connect(_on_staff_changed)
		StaffManager.staff_fired.connect(_on_staff_changed)
		StaffManager.staff_skill_improved.connect(_on_staff_changed)
		StaffManager.applicants_refreshed.connect(_on_applicants_refreshed)

func _build_ui() -> void:
	"""Build the staff hiring UI"""
	# Title
	var title: Label = Label.new()
	title.text = "Employee Management"
	title.add_theme_font_size_override("font_size", 20)
	add_child(title)

	# Info section
	var info_hbox: HBoxContainer = HBoxContainer.new()
	add_child(info_hbox)

	capacity_label = Label.new()
	capacity_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_hbox.add_child(capacity_label)

	wages_label = Label.new()
	wages_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	info_hbox.add_child(wages_label)

	add_child(HSeparator.new())

	# Current Staff section
	var staff_title: Label = Label.new()
	staff_title.text = "Current Employees"
	staff_title.add_theme_font_size_override("font_size", 16)
	add_child(staff_title)

	var staff_scroll: ScrollContainer = ScrollContainer.new()
	staff_scroll.custom_minimum_size = Vector2(0, 200)
	add_child(staff_scroll)

	current_staff_container = VBoxContainer.new()
	current_staff_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	staff_scroll.add_child(current_staff_container)

	add_child(HSeparator.new())

	# Applicants section
	var applicants_title: Label = Label.new()
	applicants_title.text = "Available Applicants"
	applicants_title.add_theme_font_size_override("font_size", 16)
	add_child(applicants_title)

	var applicants_scroll: ScrollContainer = ScrollContainer.new()
	applicants_scroll.custom_minimum_size = Vector2(0, 200)
	add_child(applicants_scroll)

	applicants_container = VBoxContainer.new()
	applicants_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	applicants_scroll.add_child(applicants_container)

func refresh_display() -> void:
	"""Refresh the entire display"""
	_update_info_labels()
	_display_current_staff()
	_display_applicants()

func _update_info_labels() -> void:
	"""Update capacity and wages labels"""
	if capacity_label and StaffManager:
		var hired: int = StaffManager.get_hired_staff_count()
		var max: int = StaffManager.max_staff_slots
		capacity_label.text = "Employees: %d / %d" % [hired, max]

	if wages_label and StaffManager:
		var daily_wages: float = StaffManager.get_total_daily_wages()
		wages_label.text = "Daily Wages: $%.2f" % daily_wages

func _display_current_staff() -> void:
	"""Display all currently hired employees"""
	# Clear existing
	for child in current_staff_container.get_children():
		child.queue_free()

	if not StaffManager:
		return

	var hired_staff: Dictionary = StaffManager.hired_staff

	if hired_staff.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "No employees hired yet. Hire from applicants below!"
		empty_label.modulate = Color(0.7, 0.7, 0.7)
		current_staff_container.add_child(empty_label)
		return

	# Add each employee
	for employee_id in hired_staff.keys():
		var employee_data: Dictionary = hired_staff[employee_id]
		_add_employee_card(employee_data, true)

func _display_applicants() -> void:
	"""Display available applicants"""
	# Clear existing
	for child in applicants_container.get_children():
		child.queue_free()

	if not StaffManager:
		return

	var applicants: Array = StaffManager.get_applicant_pool()

	if applicants.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "No applicants available. Check back next week!"
		empty_label.modulate = Color(0.7, 0.7, 0.7)
		applicants_container.add_child(empty_label)
		return

	# Add each applicant
	for applicant_data in applicants:
		_add_employee_card(applicant_data, false)

func _add_employee_card(data: Dictionary, is_hired: bool) -> void:
	"""Add an employee card (for hired employees or applicants)"""
	var panel: PanelContainer = PanelContainer.new()
	if is_hired:
		current_staff_container.add_child(panel)
	else:
		applicants_container.add_child(panel)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	panel.add_child(vbox)

	# Header row: Name + Wage
	var header_hbox: HBoxContainer = HBoxContainer.new()
	vbox.add_child(header_hbox)

	var name_label: Label = Label.new()
	name_label.text = data.get("employee_name", "Unknown")
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(name_label)

	var wage_label: Label = Label.new()
	wage_label.text = "$%.2f/day" % data.get("base_wage", 0.0)
	wage_label.add_theme_font_size_override("font_size", 14)
	header_hbox.add_child(wage_label)

	# Archetype label (if applicant)
	if not is_hired and data.has("archetype"):
		var archetype_label: Label = Label.new()
		archetype_label.text = "Archetype: " + data["archetype"]
		archetype_label.add_theme_font_size_override("font_size", 11)
		archetype_label.modulate = Color(0.7, 0.9, 1.0)
		vbox.add_child(archetype_label)

	# Skills section
	var skills_title: Label = Label.new()
	skills_title.text = "SKILLS"
	skills_title.add_theme_font_size_override("font_size", 12)
	skills_title.modulate = Color(0.8, 0.8, 0.8)
	vbox.add_child(skills_title)

	_add_skill_bar(vbox, "Culinary", data.get("culinary_skill", 0))
	_add_skill_bar(vbox, "Customer Service", data.get("customer_service_skill", 0))
	_add_skill_bar(vbox, "Cleaning", data.get("cleaning_skill", 0))
	_add_skill_bar(vbox, "Organization", data.get("organization_skill", 0))

	# Attributes section (for hired employees only)
	if is_hired:
		var attr_title: Label = Label.new()
		attr_title.text = "ATTRIBUTES"
		attr_title.add_theme_font_size_override("font_size", 12)
		attr_title.modulate = Color(0.8, 0.8, 0.8)
		vbox.add_child(attr_title)

		_add_progress_bar(vbox, "Energy", data.get("energy", 100), 100, Color(1.0, 0.8, 0.2))
		_add_progress_bar(vbox, "Morale", data.get("morale", 80), 100, Color(0.2, 0.8, 1.0))
		_add_progress_bar(vbox, "XP", data.get("experience_points", 0), 100, Color(0.5, 1.0, 0.5))

		var days_label: Label = Label.new()
		days_label.text = "Days Employed: %d" % data.get("days_employed", 0)
		days_label.add_theme_font_size_override("font_size", 10)
		vbox.add_child(days_label)

	# Traits section
	if data.has("traits") and data["traits"].size() > 0:
		var traits_hbox: HBoxContainer = HBoxContainer.new()
		vbox.add_child(traits_hbox)

		var traits_label: Label = Label.new()
		traits_label.text = "Traits: "
		traits_label.add_theme_font_size_override("font_size", 10)
		traits_hbox.add_child(traits_label)

		for trait_name in data["traits"]:
			var trait_badge: Label = Label.new()
			trait_badge.text = trait_name
			trait_badge.add_theme_font_size_override("font_size", 10)
			trait_badge.modulate = Color(1.0, 0.9, 0.5)
			traits_hbox.add_child(trait_badge)

	# Assignment dropdown (for hired employees only)
	if is_hired:
		var assign_hbox: HBoxContainer = HBoxContainer.new()
		vbox.add_child(assign_hbox)

		var assign_label: Label = Label.new()
		assign_label.text = "Assigned: "
		assign_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		assign_hbox.add_child(assign_label)

		var phase_dropdown: OptionButton = OptionButton.new()
		phase_dropdown.add_item("Off Duty", 0)
		phase_dropdown.add_item("Baking", 1)
		phase_dropdown.add_item("Checkout", 2)
		phase_dropdown.add_item("Cleanup", 3)
		phase_dropdown.add_item("Restocking", 4)

		# Set current selection
		var current_phase: String = data.get("assigned_phase", "none")
		match current_phase:
			"none":
				phase_dropdown.selected = 0
			"baking":
				phase_dropdown.selected = 1
			"checkout":
				phase_dropdown.selected = 2
			"cleanup":
				phase_dropdown.selected = 3
			"restocking":
				phase_dropdown.selected = 4

		phase_dropdown.item_selected.connect(_on_phase_selected.bind(data["employee_id"]))
		assign_hbox.add_child(phase_dropdown)

	# Action buttons
	var button_hbox: HBoxContainer = HBoxContainer.new()
	vbox.add_child(button_hbox)

	if is_hired:
		# Raise button
		var raise_button: Button = Button.new()
		raise_button.text = "Give Raise ($5)"
		raise_button.custom_minimum_size.x = 120
		raise_button.pressed.connect(_on_raise_pressed.bind(data["employee_id"]))
		button_hbox.add_child(raise_button)

		# Bonus button
		var bonus_button: Button = Button.new()
		bonus_button.text = "Give Bonus ($20)"
		bonus_button.custom_minimum_size.x = 120
		bonus_button.pressed.connect(_on_bonus_pressed.bind(data["employee_id"]))
		button_hbox.add_child(bonus_button)

		# Fire button
		var fire_button: Button = Button.new()
		fire_button.text = "Fire"
		fire_button.custom_minimum_size.x = 80
		fire_button.pressed.connect(_on_fire_pressed.bind(data["employee_id"]))
		button_hbox.add_child(fire_button)
	else:
		# Hire button
		var can_hire: bool = StaffManager.get_hired_staff_count() < StaffManager.max_staff_slots
		var can_afford: bool = StaffManager.can_afford_staff(data)

		var hire_button: Button = Button.new()
		if not can_hire:
			hire_button.text = "Staff Full"
			hire_button.disabled = true
		elif not can_afford:
			hire_button.text = "Can't Afford"
			hire_button.disabled = true
		else:
			hire_button.text = "Hire"
			hire_button.pressed.connect(_on_hire_pressed.bind(data))

		hire_button.custom_minimum_size.x = 100
		button_hbox.add_child(hire_button)

func _add_skill_bar(parent: VBoxContainer, skill_name: String, skill_value: int) -> void:
	"""Add a skill bar with name and visual representation"""
	var skill_hbox: HBoxContainer = HBoxContainer.new()
	parent.add_child(skill_hbox)

	var name_label: Label = Label.new()
	name_label.text = skill_name + ":"
	name_label.custom_minimum_size.x = 120
	name_label.add_theme_font_size_override("font_size", 11)
	skill_hbox.add_child(name_label)

	var value_label: Label = Label.new()
	value_label.text = "%d" % skill_value
	value_label.custom_minimum_size.x = 30
	value_label.add_theme_font_size_override("font_size", 11)
	skill_hbox.add_child(value_label)

	# Simple bar visualization
	var bar_container: PanelContainer = PanelContainer.new()
	bar_container.custom_minimum_size = Vector2(100, 12)
	bar_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skill_hbox.add_child(bar_container)

	var bar: ColorRect = ColorRect.new()
	var bar_width: float = (skill_value / 100.0) * 100.0
	bar.custom_minimum_size = Vector2(bar_width, 12)
	bar.color = _get_skill_color(skill_value)
	bar_container.add_child(bar)

func _add_progress_bar(parent: VBoxContainer, label_text: String, current: int, maximum: int, bar_color: Color = Color.GREEN) -> void:
	"""Add a progress bar for attributes like Energy, Morale, XP"""
	var hbox: HBoxContainer = HBoxContainer.new()
	parent.add_child(hbox)

	var label: Label = Label.new()
	label.text = label_text + ":"
	label.custom_minimum_size.x = 60
	label.add_theme_font_size_override("font_size", 10)
	hbox.add_child(label)

	var value_label: Label = Label.new()
	value_label.text = "%d/%d" % [current, maximum]
	value_label.custom_minimum_size.x = 50
	value_label.add_theme_font_size_override("font_size", 10)
	hbox.add_child(value_label)

	var bar_container: PanelContainer = PanelContainer.new()
	bar_container.custom_minimum_size = Vector2(100, 10)
	bar_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(bar_container)

	var bar: ColorRect = ColorRect.new()
	var bar_width: float = (float(current) / float(maximum)) * 100.0
	bar.custom_minimum_size = Vector2(bar_width, 10)
	bar.color = bar_color
	bar_container.add_child(bar)

func _get_skill_color(skill_value: int) -> Color:
	"""Get color based on skill value"""
	if skill_value >= 75:
		return Color(0.2, 1.0, 0.2)  # Green
	elif skill_value >= 50:
		return Color(0.5, 0.8, 1.0)  # Blue
	elif skill_value >= 25:
		return Color(1.0, 0.8, 0.2)  # Yellow
	else:
		return Color(1.0, 0.4, 0.4)  # Red

# ============================================================================
# EVENT HANDLERS
# ============================================================================

func _on_hire_pressed(applicant_data: Dictionary) -> void:
	"""Hire an applicant"""
	if StaffManager and StaffManager.hire_staff(applicant_data):
		print("[UI] Hired: ", applicant_data["employee_name"])
		refresh_display()
	else:
		print("[UI] Failed to hire: ", applicant_data.get("employee_name", "Unknown"))

func _on_fire_pressed(employee_id: String) -> void:
	"""Fire an employee"""
	if StaffManager:
		StaffManager.fire_staff(employee_id)
		refresh_display()

func _on_phase_selected(index: int, employee_id: String) -> void:
	"""Called when phase assignment dropdown changes"""
	if not StaffManager:
		return

	var phase: String = "none"
	match index:
		0: phase = "none"
		1: phase = "baking"
		2: phase = "checkout"
		3: phase = "cleanup"
		4: phase = "restocking"

	StaffManager.assign_staff_to_phase(employee_id, phase)
	refresh_display()

func _on_raise_pressed(employee_id: String) -> void:
	"""Give employee a raise"""
	if StaffManager:
		StaffManager.give_raise(employee_id, 5.0)
		refresh_display()

func _on_bonus_pressed(employee_id: String) -> void:
	"""Give employee a bonus"""
	if StaffManager:
		StaffManager.give_bonus(employee_id, 20.0)
		refresh_display()

func _on_staff_changed(_data = null) -> void:
	"""Called when staff hired, fired, or changed"""
	refresh_display()

func _on_applicants_refreshed(_applicants: Array) -> void:
	"""Called when applicant pool refreshes"""
	refresh_display()
