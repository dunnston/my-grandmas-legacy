extends Control

# Event Notification - Displays special events (weather, critics, holidays, etc.)
# Non-blocking notification that appears briefly then fades

# Node references
@onready var panel: Panel = $Panel
@onready var event_title: Label = $Panel/MarginContainer/VBox/EventTitle
@onready var event_icon: Label = $Panel/MarginContainer/VBox/EventIcon
@onready var event_description: RichTextLabel = $Panel/MarginContainer/VBox/EventDescription
@onready var event_effects: Label = $Panel/MarginContainer/VBox/EventEffects
@onready var dismiss_button: Button = $Panel/MarginContainer/VBox/DismissButton

# Animation
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var auto_dismiss_timer: Timer = $AutoDismissTimer

# Queue for multiple events
var event_queue: Array = []
var is_showing: bool = false

func _ready() -> void:
	print("EventNotification ready")

	# Start hidden
	hide()

	# Connect dismiss button
	if dismiss_button:
		dismiss_button.pressed.connect(_on_dismiss_pressed)

	# Connect auto-dismiss timer
	if auto_dismiss_timer:
		auto_dismiss_timer.timeout.connect(_on_auto_dismiss_timeout)

	# Connect to EventManager signal
	if EventManager:
		EventManager.event_triggered.connect(_on_event_triggered)

func show_event(event_data: Dictionary) -> void:
	"""Display an event notification"""
	if is_showing:
		# Queue this event
		event_queue.append(event_data)
		return

	is_showing = true
	print("EventNotification: Showing event '%s'" % event_data.get("name", "Unknown"))

	# Set event content
	if event_icon:
		event_icon.text = event_data.get("icon", "📰")

	if event_title:
		event_title.text = event_data.get("name", "Special Event")

	if event_description:
		event_description.text = event_data.get("description", "")

	if event_effects:
		var effects_text: String = _format_effects(event_data)
		event_effects.text = effects_text

	# Show with animation
	show()
	if animation_player and animation_player.has_animation("slide_in"):
		animation_player.play("slide_in")

	# Auto-dismiss after 8 seconds
	if auto_dismiss_timer:
		auto_dismiss_timer.start(8.0)

func _format_effects(event_data: Dictionary) -> String:
	"""Format event effects for display"""
	var effects: Array = []

	# Traffic modifier
	if event_data.has("traffic_modifier"):
		var mod: float = event_data["traffic_modifier"]
		if mod > 1.0:
			effects.append("📈 +%.0f%% Customer Traffic" % ((mod - 1.0) * 100))
		elif mod < 1.0:
			effects.append("📉 %.0f%% Customer Traffic" % ((mod - 1.0) * 100))

	# Reputation impact
	if event_data.has("reputation_impact"):
		var impact: int = event_data["reputation_impact"]
		if impact > 0:
			effects.append("⭐ +%d Reputation" % impact)
		elif impact < 0:
			effects.append("⭐ %d Reputation" % impact)

	# Price modifiers
	if event_data.has("sell_price_modifier"):
		var mod: float = event_data["sell_price_modifier"]
		if mod > 1.0:
			effects.append("💰 +%.0f%% Sale Prices" % ((mod - 1.0) * 100))
		elif mod < 1.0:
			effects.append("💰 %.0f%% Sale Prices" % ((mod - 1.0) * 100))

	if event_data.has("ingredient_cost_modifier"):
		var mod: float = event_data["ingredient_cost_modifier"]
		if mod > 1.0:
			effects.append("🛒 +%.0f%% Ingredient Costs" % ((mod - 1.0) * 100))
		elif mod < 1.0:
			effects.append("🛒 %.0f%% Ingredient Costs" % ((mod - 1.0) * 100))

	# Duration
	if event_data.has("duration_days"):
		var days: int = event_data["duration_days"]
		if days == 1:
			effects.append("⏱ Lasts today only")
		else:
			effects.append("⏱ Lasts %d days" % days)

	# Reward
	if event_data.has("reward_cash"):
		var cash: float = event_data["reward_cash"]
		if cash > 0:
			effects.append("🎁 Reward: $%.2f" % cash)

	if event_data.has("reward_reputation"):
		var rep: int = event_data["reward_reputation"]
		if rep > 0:
			effects.append("🎁 Reward: +%d Reputation" % rep)

	if effects.is_empty():
		return ""

	return "\n".join(effects)

func _on_dismiss_pressed() -> void:
	"""Dismiss button pressed"""
	_dismiss_event()

func _on_auto_dismiss_timeout() -> void:
	"""Auto-dismiss timer expired"""
	_dismiss_event()

func _dismiss_event() -> void:
	"""Dismiss the current event"""
	if auto_dismiss_timer:
		auto_dismiss_timer.stop()

	# Hide with animation
	if animation_player and animation_player.has_animation("slide_out"):
		animation_player.play("slide_out")
		await animation_player.animation_finished

	hide()
	is_showing = false

	# Show next event in queue
	if not event_queue.is_empty():
		var next_event: Dictionary = event_queue.pop_front()
		show_event(next_event)

func _on_event_triggered(_event_id: String, event_data: Dictionary) -> void:
	"""Called when EventManager triggers an event"""
	show_event(event_data)

# Allow ESC key to dismiss
func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		_on_dismiss_pressed()
		get_viewport().set_input_as_handled()
		return
