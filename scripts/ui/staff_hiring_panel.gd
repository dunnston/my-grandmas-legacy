extends VBoxContainer

# StaffHiringPanel - UI component for the Staff tab in Planning Menu
# Shows current staff, applicant pool, and hiring/firing options

# Node references (created dynamically)
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
		StaffManager.applicants_refreshed.connect(_on_applicants_refreshed)

func _build_ui() -> void:
	"""Build the staff hiring UI"""
	# Title
	var title: Label = Label.new()
	title.text = "Staff Management"
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
	staff_title.text = "Current Staff"
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
	applicants_title.text = "Available Applicants (Refresh Weekly)"
	applicants_title.add_theme_font_size_override("font_size", 16)
	add_child(applicants_title)

	var applicants_scroll: ScrollContainer = ScrollContainer.new()
	applicants_scroll.custom_minimum_size = Vector2(0, 250)
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
	if capacity_label:
		var hired: int = StaffManager.get_hired_staff_count()
		var max: int = StaffManager.max_staff_slots
		capacity_label.text = "Staff: %d / %d" % [hired, max]

	if wages_label:
		var daily_wages: float = StaffManager.get_total_daily_wages()
		wages_label.text = "Daily Wages: $%.2f" % daily_wages

func _display_current_staff() -> void:
	"""Display all currently hired staff"""
	# Clear existing
	for child in current_staff_container.get_children():
		child.queue_free()

	var hired_staff: Dictionary = StaffManager.hired_staff

	if hired_staff.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "No staff hired yet. Hire from applicants below!"
		empty_label.modulate = Color(0.7, 0.7, 0.7)
		current_staff_container.add_child(empty_label)
		return

	# Add each staff member
	for staff_id in hired_staff.keys():
		var staff_data: Dictionary = hired_staff[staff_id]
		_add_staff_card(staff_data, true)

func _display_applicants() -> void:
	"""Display available applicants"""
	# Clear existing
	for child in applicants_container.get_children():
		child.queue_free()

	var applicants: Array = StaffManager.get_applicant_pool()

	if applicants.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "No applicants available. Check back next week!"
		empty_label.modulate = Color(0.7, 0.7, 0.7)
		applicants_container.add_child(empty_label)
		return

	# Add each applicant
	for applicant_data in applicants:
		_add_staff_card(applicant_data, false)

func _add_staff_card(data: Dictionary, is_hired: bool) -> void:
	"""Add a staff card (for hired staff or applicant)"""
	var panel: PanelContainer = PanelContainer.new()
	if is_hired:
		current_staff_container.add_child(panel)
	else:
		applicants_container.add_child(panel)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	panel.add_child(vbox)

	# Header row: Name, Role, Stars
	var header_hbox: HBoxContainer = HBoxContainer.new()
	vbox.add_child(header_hbox)

	# Name
	var name_label: Label = Label.new()
	name_label.text = data.name
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(name_label)

	# Stars
	var stars_label: Label = Label.new()
	stars_label.text = _get_star_display(data.skill)
	stars_label.add_theme_font_size_override("font_size", 14)
	header_hbox.add_child(stars_label)

	# Role and description row
	var role_label: Label = Label.new()
	var role_name: String = _get_role_name(data.role)
	var role_desc: String = StaffManager.get_role_description(data.role)
	role_label.text = "%s - %s" % [role_name, role_desc]
	role_label.add_theme_font_size_override("font_size", 12)
	role_label.modulate = Color(0.8, 0.8, 0.8)
	vbox.add_child(role_label)

	# Stats row
	var stats_hbox: HBoxContainer = HBoxContainer.new()
	vbox.add_child(stats_hbox)

	# Wage
	var wage: float = StaffManager.wage_rates[data.skill]
	var wage_label: Label = Label.new()
	wage_label.text = "Wage: $%.2f/day" % wage
	wage_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_hbox.add_child(wage_label)

	# Performance stats
	var speed_mult: float = StaffManager.skill_speed_multipliers[data.skill]
	var quality_mult: float = StaffManager.skill_quality_multipliers[data.skill]
	var perf_label: Label = Label.new()
	perf_label.text = "Speed: %.0f%% | Quality: %.0f%%" % [speed_mult * 100, quality_mult * 100]
	perf_label.add_theme_font_size_override("font_size", 11)
	stats_hbox.add_child(perf_label)

	# Action button
	var button: Button = Button.new()

	if is_hired:
		# Fire button
		button.text = "Fire"
		button.pressed.connect(_on_fire_pressed.bind(data.id))
		var days_worked: int = data.get("days_worked", 0)
		if days_worked > 0:
			var exp_label: Label = Label.new()
			exp_label.text = "Experience: %d days | Level progress: %d/%d" % [
				days_worked,
				data.get("experience", 0),
				data.skill * 30
			]
			exp_label.add_theme_font_size_override("font_size", 10)
			exp_label.modulate = Color(0.7, 0.9, 0.7)
			vbox.add_child(exp_label)
	else:
		# Hire button
		var can_hire: bool = StaffManager.get_hired_staff_count() < StaffManager.max_staff_slots
		var can_afford: bool = StaffManager.can_afford_staff(data)

		if not can_hire:
			button.text = "Staff Full"
			button.disabled = true
		elif not can_afford:
			button.text = "Can't Afford"
			button.disabled = true
		else:
			button.text = "Hire"
			button.pressed.connect(_on_hire_pressed.bind(data))

	button.custom_minimum_size.x = 100
	vbox.add_child(button)

func _on_hire_pressed(applicant_data: Dictionary) -> void:
	"""Hire an applicant"""
	if StaffManager.hire_staff(applicant_data):
		print("Hired: ", applicant_data.name)
		refresh_display()
	else:
		print("Failed to hire: ", applicant_data.name)

func _on_fire_pressed(staff_id: String) -> void:
	"""Fire a staff member"""
	StaffManager.fire_staff(staff_id)
	refresh_display()

func _on_staff_changed(_data = null) -> void:
	"""Called when staff hired or fired"""
	refresh_display()

func _on_applicants_refreshed(_applicants: Array) -> void:
	"""Called when applicant pool refreshes"""
	refresh_display()

func _get_star_display(skill: int) -> String:
	"""Get star display for skill level"""
	var stars: String = ""
	for i in range(5):
		if i < skill:
			stars += "★"
		else:
			stars += "☆"
	return stars

func _get_role_name(role: int) -> String:
	"""Get display name for role"""
	match role:
		StaffManager.StaffRole.BAKER:
			return "Baker"
		StaffManager.StaffRole.CASHIER:
			return "Cashier"
		StaffManager.StaffRole.CLEANER:
			return "Cleaner"
		_:
			return "Unknown"
