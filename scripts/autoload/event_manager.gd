extends Node

# EventManager - Singleton for managing special events and random occurrences
# Handles weather events, food critics, festivals, holidays, and more

# Signals
signal event_triggered(event_id: String, event_data: Dictionary)
signal event_completed(event_id: String, success: bool)
signal random_event_occurred(event_type: String)
signal scheduled_event_started(event_name: String)

# Event state
var active_events: Array[Dictionary] = []
var completed_events: Array[String] = []
var current_day: int = 1

# Event definitions
var random_events: Dictionary = {
	"food_critic": {
		"name": "Food Critic Visit",
		"description": "A renowned food critic is visiting today! Impress them with quality.",
		"icon": "🍽️",
		"chance": 0.05,  # 5% chance per day
		"min_day": 7,  # Only after day 7
		"effects": {
			"reputation_multiplier": 3.0,  # Triple reputation impact
			"requires_quality": 0.80  # Need 80%+ quality to impress
		},
		"rewards": {
			"success_reputation": 15,
			"failure_reputation": -10
		}
	},

	"weather_rain": {
		"name": "Rainy Day",
		"description": "It's pouring outside. Fewer customers, but they'll stay longer.",
		"icon": "🌧️",
		"chance": 0.15,  # 15% chance
		"effects": {
			"traffic_modifier": 0.7,  # 30% less traffic
			"patience_bonus": 1.3  # Customers 30% more patient
		}
	},

	"weather_sunshine": {
		"name": "Beautiful Weather",
		"description": "Perfect weather brings people out! Expect extra customers.",
		"icon": "☀️",
		"chance": 0.15,  # 15% chance
		"effects": {
			"traffic_modifier": 1.3  # 30% more traffic
		}
	},

	"weather_snow": {
		"name": "Snow Day",
		"description": "Light snow! Customers crave warm comfort foods.",
		"icon": "❄️",
		"chance": 0.08,  # 8% chance (seasonal)
		"min_day": 30,
		"effects": {
			"traffic_modifier": 0.9,  # 10% less traffic
			"bread_demand": 1.5,  # 50% more bread sales
			"price_boost": 1.1  # Customers willing to pay 10% more
		}
	},

	"celebrity_visit": {
		"name": "Celebrity Customer",
		"description": "A local celebrity just walked in! Word will spread if they're happy.",
		"icon": "⭐",
		"chance": 0.03,  # 3% chance
		"min_day": 14,
		"effects": {
			"single_customer": true,  # One special customer
			"reputation_multiplier": 2.5
		},
		"rewards": {
			"success_reputation": 10,
			"success_cash_bonus": 50.0
		}
	},

	"school_field_trip": {
		"name": "School Field Trip",
		"description": "A class of students is visiting! Many customers, lower prices expected.",
		"icon": "🎒",
		"chance": 0.06,  # 6% chance
		"min_day": 10,
		"effects": {
			"traffic_modifier": 2.0,  # Double traffic
			"price_tolerance": 0.7,  # Want 30% lower prices
			"cookie_demand": 2.0  # Love cookies!
		}
	},

	"competitor_opens": {
		"name": "New Competitor",
		"description": "A competing bakery opened nearby. You'll need to work harder!",
		"icon": "🏪",
		"chance": 0.04,  # 4% chance
		"min_day": 20,
		"duration_days": 5,  # Lasts 5 days
		"effects": {
			"traffic_modifier": 0.8,  # 20% less traffic
			"quality_expectations": 1.2  # Need better quality
		}
	},

	"equipment_breakdown": {
		"name": "Equipment Malfunction",
		"description": "Oh no! One of your ovens is acting up. Slower baking today.",
		"icon": "🔧",
		"chance": 0.05,  # 5% chance
		"min_day": 5,
		"effects": {
			"baking_speed": 0.7,  # 30% slower baking
			"repair_cost": 50.0
		}
	},

	"ingredient_sale": {
		"name": "Farmer's Market Deal",
		"description": "Fresh ingredients at the market today! 25% off all purchases.",
		"icon": "🌽",
		"chance": 0.10,  # 10% chance
		"effects": {
			"ingredient_discount": 0.25  # 25% off
		}
	},

	"bulk_order": {
		"name": "Bulk Order Request",
		"description": "Someone ordered 20 items for a party! Can you deliver by end of day?",
		"icon": "📦",
		"chance": 0.08,  # 8% chance
		"min_day": 10,
		"effects": {
			"order_quantity": 20,
			"order_deadline": "end_of_business_phase",
			"reward_multiplier": 1.5  # 50% bonus if completed
		},
		"rewards": {
			"success_cash": 200.0,
			"success_reputation": 5,
			"failure_reputation": -3
		}
	}
}

# Scheduled events (holidays, festivals)
var scheduled_events: Dictionary = {
	"valentines_day": {
		"name": "Valentine's Day",
		"description": "Love is in the air! Cakes and special treats are in high demand.",
		"icon": "💝",
		"occurs_on_day": [14, 45, 76],  # Repeats every ~30 days
		"effects": {
			"cake_demand": 2.0,
			"traffic_modifier": 1.4,
			"price_boost": 1.15
		}
	},

	"town_festival": {
		"name": "Town Festival",
		"description": "The annual town festival! Huge crowds and a baking competition!",
		"icon": "🎪",
		"occurs_on_day": [30, 90],  # Major events
		"duration_days": 3,
		"effects": {
			"traffic_modifier": 2.5,  # Massive traffic
			"competition": true,  # Special competition mechanic
			"all_demand": 1.5
		},
		"rewards": {
			"competition_winner": {
				"reputation": 25,
				"cash": 500.0,
				"special_unlock": "festival_ribbon"
			}
		}
	},

	"thanksgiving": {
		"name": "Thanksgiving Week",
		"description": "Families need pies and bread for the holiday feast!",
		"icon": "🦃",
		"occurs_on_day": [60],
		"duration_days": 2,
		"effects": {
			"pie_demand": 3.0,
			"bread_demand": 2.0,
			"traffic_modifier": 1.6
		}
	},

	"christmas": {
		"name": "Christmas Season",
		"description": "The most wonderful time of the year! Everyone wants baked goods.",
		"icon": "🎄",
		"occurs_on_day": [80, 85, 90],  # Multi-day celebration
		"effects": {
			"traffic_modifier": 2.0,
			"special_demand": 2.5,  # Holiday recipes
			"price_boost": 1.2,
			"reputation_bonus": 2  # Extra reputation per happy customer
		}
	},

	"health_inspection": {
		"name": "Health Inspection",
		"description": "Surprise inspection! Cleanliness and quality matter today.",
		"icon": "📋",
		"occurs_on_day": [15, 40, 70],
		"effects": {
			"quality_requirements": 0.85,  # Need 85%+ quality
			"cleanliness_check": true
		},
		"rewards": {
			"success_reputation": 10,
			"perfect_score_bonus": 100.0
		}
	},

	"weekly_farmers_market": {
		"name": "Weekly Market",
		"description": "The farmer's market is today! Special ingredient deals.",
		"icon": "🥕",
		"occurs_every": 7,  # Every 7 days
		"effects": {
			"ingredient_discount": 0.15,  # 15% off
			"rare_ingredients_available": true
		}
	}
}

func _ready() -> void:
	print("EventManager initialized")

	# Connect to GameManager for day progression
	if GameManager:
		GameManager.connect("day_started", _on_day_started)
		GameManager.connect("phase_changed", _on_phase_changed)

func _on_day_started(day: int) -> void:
	"""Called when a new day starts - check for events"""
	current_day = day
	print("\n=== Day %d: Checking for Events ===" % day)

	# Check for scheduled events first
	check_scheduled_events(day)

	# Then roll for random events
	if active_events.size() == 0:  # Only one event per day
		roll_random_event(day)

	print("===================================\n")

func _on_phase_changed(old_phase: String, new_phase: String) -> void:
	"""Handle phase transitions"""
	# Update event states based on phase
	pass

func check_scheduled_events(day: int) -> void:
	"""Check if any scheduled events occur today"""
	for event_id in scheduled_events:
		var event: Dictionary = scheduled_events[event_id]

		# Check if it occurs on this specific day
		if event.has("occurs_on_day") and day in event["occurs_on_day"]:
			trigger_event(event_id, event, "scheduled")
			return  # Only one event per day

		# Check if it occurs every N days
		if event.has("occurs_every") and day % event["occurs_every"] == 0:
			trigger_event(event_id, event, "scheduled")
			return

func roll_random_event(day: int) -> void:
	"""Roll for a random event to occur today"""
	# Don't trigger random events on very early days
	if day < 3:
		return

	# Collect eligible events
	var eligible_events: Array = []
	for event_id in random_events:
		var event: Dictionary = random_events[event_id]

		# Check minimum day requirement
		if event.has("min_day") and day < event["min_day"]:
			continue

		# Add to eligible pool with weight based on chance
		eligible_events.append({"id": event_id, "data": event})

	if eligible_events.is_empty():
		print("No random events today")
		return

	# Roll for each event
	for event_entry in eligible_events:
		var event_id: String = event_entry["id"]
		var event: Dictionary = event_entry["data"]
		var chance: float = event.get("chance", 0.05)

		if randf() < chance:
			trigger_event(event_id, event, "random")
			return  # Only trigger one event

func trigger_event(event_id: String, event_data: Dictionary, event_type: String) -> void:
	"""Trigger a specific event"""
	print("\n🎲 EVENT TRIGGERED: %s %s" % [event_data.get("icon", ""), event_data["name"]])
	print("Description: %s" % event_data["description"])

	# Create active event record
	var active_event: Dictionary = {
		"id": event_id,
		"name": event_data["name"],
		"type": event_type,
		"data": event_data.duplicate(true),
		"start_day": current_day,
		"duration": event_data.get("duration_days", 1)
	}

	active_events.append(active_event)

	# Apply event effects
	apply_event_effects(event_id, event_data)

	# Emit signals
	event_triggered.emit(event_id, event_data)
	if event_type == "random":
		random_event_occurred.emit(event_data["name"])
	elif event_type == "scheduled":
		scheduled_event_started.emit(event_data["name"])

func apply_event_effects(event_id: String, event_data: Dictionary) -> void:
	"""Apply the effects of an event to game systems"""
	if not event_data.has("effects"):
		return

	var effects: Dictionary = event_data["effects"]

	print("\nApplying event effects:")

	# Traffic modifier
	if effects.has("traffic_modifier"):
		var modifier: float = effects["traffic_modifier"]
		if CustomerManager:
			CustomerManager.set_traffic_modifier(modifier)
			print("  • Traffic: %.0f%%" % (modifier * 100))

	# Ingredient discount
	if effects.has("ingredient_discount"):
		var discount: float = effects["ingredient_discount"]
		if EconomyManager:
			EconomyManager.set_ingredient_discount(discount)
			print("  • Ingredient discount: %.0f%%" % (discount * 100))

	# Price boost (customers willing to pay more)
	if effects.has("price_boost"):
		print("  • Price tolerance: +%.0f%%" % ((effects["price_boost"] - 1.0) * 100))

	# Special demand modifiers
	if effects.has("bread_demand"):
		print("  • Bread demand: %.0fx" % effects["bread_demand"])
	if effects.has("cake_demand"):
		print("  • Cake demand: %.0fx" % effects["cake_demand"])
	if effects.has("cookie_demand"):
		print("  • Cookie demand: %.0fx" % effects["cookie_demand"])

	# Quality requirements
	if effects.has("quality_requirements"):
		print("  • Quality threshold: %.0f%%" % (effects["quality_requirements"] * 100))

	# Reputation multiplier
	if effects.has("reputation_multiplier"):
		print("  • Reputation impact: %.1fx" % effects["reputation_multiplier"])

func complete_event(event_id: String, success: bool = true) -> void:
	"""Mark an event as completed"""
	# Find and remove from active events
	for i in range(active_events.size() - 1, -1, -1):
		if active_events[i]["id"] == event_id:
			var event: Dictionary = active_events[i]
			active_events.remove_at(i)
			completed_events.append(event_id)

			# Apply rewards if successful
			if success and event["data"].has("rewards"):
				apply_event_rewards(event_id, event["data"]["rewards"])

			event_completed.emit(event_id, success)
			print("Event completed: %s (%s)" % [event["name"], "SUCCESS" if success else "FAILED"])
			return

func apply_event_rewards(event_id: String, rewards: Dictionary) -> void:
	"""Apply rewards from completing an event successfully"""
	print("\n✨ Event rewards:")

	if rewards.has("success_reputation") and ProgressionManager:
		var rep: int = rewards["success_reputation"]
		ProgressionManager.modify_reputation(rep)
		print("  • Reputation: %+d" % rep)

	if rewards.has("success_cash") and EconomyManager:
		var cash: float = rewards["success_cash"]
		EconomyManager.add_transaction(cash, "Event reward: " + event_id, true)
		print("  • Cash bonus: $%.2f" % cash)

	if rewards.has("success_cash_bonus") and EconomyManager:
		var bonus: float = rewards["success_cash_bonus"]
		EconomyManager.add_transaction(bonus, "Event bonus", true)
		print("  • Bonus: $%.2f" % bonus)

func get_active_events() -> Array[Dictionary]:
	"""Get list of currently active events"""
	return active_events.duplicate()

func is_event_active(event_id: String) -> bool:
	"""Check if a specific event is currently active"""
	for event in active_events:
		if event["id"] == event_id:
			return true
	return false

func get_event_effect(event_id: String, effect_key: String) -> Variant:
	"""Get a specific effect value from an active event"""
	for event in active_events:
		if event["id"] == event_id:
			if event["data"].has("effects") and event["data"]["effects"].has(effect_key):
				return event["data"]["effects"][effect_key]
	return null

func get_traffic_modifier() -> float:
	"""Get combined traffic modifier from all active events"""
	var modifier: float = 1.0
	for event in active_events:
		if event["data"].has("effects") and event["data"]["effects"].has("traffic_modifier"):
			modifier *= event["data"]["effects"]["traffic_modifier"]
	return modifier

func get_price_modifier() -> float:
	"""Get combined price tolerance modifier from all active events"""
	var modifier: float = 1.0
	for event in active_events:
		if event["data"].has("effects") and event["data"]["effects"].has("price_boost"):
			modifier *= event["data"]["effects"]["price_boost"]
	return modifier

# Save/Load support
func get_save_data() -> Dictionary:
	return {
		"active_events": active_events.duplicate(true),
		"completed_events": completed_events.duplicate(),
		"current_day": current_day
	}

func load_save_data(data: Dictionary) -> void:
	if data.has("active_events"):
		active_events = data["active_events"]
	if data.has("completed_events"):
		completed_events = data["completed_events"]
	if data.has("current_day"):
		current_day = data["current_day"]

	print("Event data loaded: %d active, %d completed" % [active_events.size(), completed_events.size()])
