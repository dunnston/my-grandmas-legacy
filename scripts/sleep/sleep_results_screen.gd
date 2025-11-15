extends CanvasLayer

# SleepResultsScreen - Shows sleep quality results and bonuses earned

# Signals
signal continue_pressed()

# Node references
@onready var quality_label: Label = $ScreenContainer/Panel/VBox/QualityLabel
@onready var message_label: Label = $ScreenContainer/Panel/VBox/MessageLabel
@onready var calm_percentage_label: Label = $ScreenContainer/Panel/VBox/CalmPercentageLabel
@onready var bonuses_container: VBoxContainer = $ScreenContainer/Panel/VBox/BonusesContainer
@onready var continue_button: Button = $ScreenContainer/Panel/VBox/ContinueButton

func _ready() -> void:
	hide()

	if continue_button:
		continue_button.pressed.connect(_on_continue_pressed)

func show_results(calm_percentage: float, quality_name: String, bonuses: Dictionary) -> void:
	"""Display sleep results"""
	print("[SleepResults] Showing results...")

	# Update quality display
	if quality_label:
		quality_label.text = quality_name

	# Update calm percentage
	if calm_percentage_label:
		calm_percentage_label.text = "Calm Level: %.0f%%" % calm_percentage

	# Update message
	if message_label:
		message_label.text = _get_quality_message(quality_name)

	# Display bonuses
	if bonuses_container:
		# Clear existing
		for child in bonuses_container.get_children():
			child.queue_free()

		# Add buff name if present
		if bonuses.has("buff_name") and bonuses.buff_name != "":
			var buff_label = Label.new()
			buff_label.text = "%s %s" % [bonuses.buff_icon, bonuses.buff_name]
			buff_label.add_theme_font_size_override("font_size", 24)
			buff_label.add_theme_color_override("font_color", Color.GOLD)
			buff_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			bonuses_container.add_child(buff_label)

		# Add energy bonus
		if bonuses.has("energy_bonus") and bonuses.energy_bonus > 0:
			var energy_label = Label.new()
			energy_label.text = "⚡ Energy Bonus: +%.0f%%" % (bonuses.energy_bonus * 100)
			energy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			bonuses_container.add_child(energy_label)

		# Add skill bonus
		if bonuses.has("skill_effectiveness") and bonuses.skill_effectiveness > 0:
			var skill_label = Label.new()
			skill_label.text = "🔧 Skill Effectiveness: +%.0f%%" % (bonuses.skill_effectiveness * 100)
			skill_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			bonuses_container.add_child(skill_label)

		# Add reputation bonus
		if bonuses.has("reputation") and bonuses.reputation > 0:
			var rep_label = Label.new()
			rep_label.text = "⭐ Reputation: +%.0f" % bonuses.reputation
			rep_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			bonuses_container.add_child(rep_label)

	show()

func _get_quality_message(quality_name: String) -> String:
	"""Get message based on sleep quality"""
	match quality_name:
		"Perfect Sleep":
			return "You sleep blissfully! You wake up completely refreshed and inspired!"
		"Good Sleep":
			return "You sleep soundly. You wake up feeling great!"
		"Restful Sleep":
			return "You sleep peacefully. You wake up ready for the day."
		"Light Sleep":
			return "You toss and turn a bit, but get some rest. A new day begins."
		"Restless Sleep":
			return "You had trouble sleeping, but morning has arrived."
		_:
			return "You slept."

func _on_continue_pressed() -> void:
	"""Continue button pressed"""
	continue_pressed.emit()
	hide()
