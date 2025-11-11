extends Node

# MarketingManager - Singleton for managing advertising campaigns and marketing
# Allows players to invest in marketing to boost traffic and reputation

# Signals
signal campaign_started(campaign_id: String, campaign_data: Dictionary)
signal campaign_ended(campaign_id: String)
signal traffic_boost_applied(multiplier: float)

# Campaign state
var active_campaigns: Array[Dictionary] = []
var campaign_history: Array[String] = []
var total_marketing_spent: float = 0.0

# Marketing campaign definitions
var available_campaigns: Dictionary = {
	"newspaper_ad": {
		"name": "Newspaper Advertisement",
		"description": "Place an ad in the local newspaper. Reaches older demographics.",
		"icon": "📰",
		"cost": 50.0,
		"duration_days": 3,
		"traffic_boost": 1.2,  # +20% traffic
		"reputation_cost": 0,  # No reputation required
		"effects": {
			"traffic_multiplier": 1.2,
			"elder_customer_bonus": 1.3  # 30% more likely to attract older customers
		},
		"unlocked": true  # Available from start
	},

	"flyers": {
		"name": "Distribute Flyers",
		"description": "Hand out flyers around town. Cheap but short-lived boost.",
		"icon": "📄",
		"cost": 25.0,
		"duration_days": 1,
		"traffic_boost": 1.15,  # +15% traffic
		"reputation_cost": 0,
		"effects": {
			"traffic_multiplier": 1.15
		},
		"unlocked": true
	},

	"social_media": {
		"name": "Social Media Campaign",
		"description": "Run targeted ads on social platforms. Attracts younger customers.",
		"icon": "📱",
		"cost": 100.0,
		"duration_days": 5,
		"traffic_boost": 1.35,  # +35% traffic
		"reputation_cost": 25,  # Need decent reputation
		"effects": {
			"traffic_multiplier": 1.35,
			"young_customer_bonus": 1.4,  # 40% more young customers
			"review_chance": 1.5  # 50% more likely to get online reviews
		},
		"unlocked": false,  # Unlocks at $2,000 milestone
		"unlock_revenue": 2000.0
	},

	"radio_spot": {
		"name": "Radio Advertisement",
		"description": "30-second spot on local radio. Great reach during commute hours.",
		"icon": "📻",
		"cost": 150.0,
		"duration_days": 7,
		"traffic_boost": 1.4,  # +40% traffic
		"reputation_cost": 40,
		"effects": {
			"traffic_multiplier": 1.4,
			"morning_traffic": 1.6,  # Extra boost during morning hours
			"brand_awareness": 5  # +5 reputation over campaign
		},
		"unlocked": false,
		"unlock_revenue": 5000.0
	},

	"tv_commercial": {
		"name": "Television Commercial",
		"description": "Prime-time local TV spot. Expensive but very effective.",
		"icon": "📺",
		"cost": 500.0,
		"duration_days": 14,
		"traffic_boost": 1.7,  # +70% traffic
		"reputation_cost": 60,
		"effects": {
			"traffic_multiplier": 1.7,
			"all_demographics": 1.3,
			"special_orders": 1.5,  # 50% more special/bulk orders
			"brand_awareness": 15  # +15 reputation
		},
		"unlocked": false,
		"unlock_revenue": 10000.0
	},

	"billboard": {
		"name": "Billboard Advertisement",
		"description": "Permanent billboard on main road. One-time investment for lasting effect.",
		"icon": "🪧",
		"cost": 1000.0,
		"duration_days": -1,  # Permanent (until manually removed)
		"traffic_boost": 1.25,  # +25% traffic permanently
		"reputation_cost": 50,
		"effects": {
			"traffic_multiplier": 1.25,
			"permanent": true,
			"brand_recognition": 10  # +10 reputation on purchase
		},
		"unlocked": false,
		"unlock_revenue": 15000.0,
		"one_time": true  # Can only purchase once
	},

	"grand_opening": {
		"name": "Grand Re-Opening Event",
		"description": "Host a special event with samples and deals. Big one-day boost!",
		"icon": "🎉",
		"cost": 200.0,
		"duration_days": 1,
		"traffic_boost": 2.5,  # +150% traffic (massive!)
		"reputation_cost": 30,
		"effects": {
			"traffic_multiplier": 2.5,
			"price_tolerance": 0.9,  # Customers expect 10% discount
			"reputation_gain": 10,  # +10 reputation if successful
			"word_of_mouth": 1.5  # Lingering effect next few days
		},
		"unlocked": false,
		"unlock_revenue": 3000.0,
		"cooldown_days": 30  # Can only do once per month
	},

	"loyalty_program": {
		"name": "Customer Loyalty Program",
		"description": "Launch a points card system. Ongoing boost to repeat customers.",
		"icon": "💳",
		"cost": 300.0,
		"duration_days": -1,  # Permanent system
		"traffic_boost": 1.15,  # +15% from repeat customers
		"reputation_cost": 35,
		"effects": {
			"traffic_multiplier": 1.15,
			"customer_retention": 1.4,  # 40% more repeat customers
			"permanent": true,
			"reputation_slow_gain": 1  # +1 reputation per week
		},
		"unlocked": false,
		"unlock_revenue": 8000.0,
		"one_time": true
	}
}

func _ready() -> void:
	print("MarketingManager initialized")

	# Connect to ProgressionManager for unlocks
	if ProgressionManager:
		ProgressionManager.connect("milestone_reached", _on_milestone_reached)

	# Connect to GameManager for day progression
	if GameManager:
		GameManager.connect("day_changed", _on_day_changed)

func _on_milestone_reached(milestone_id: String, revenue_threshold: float) -> void:
	"""Check for marketing campaign unlocks when milestones are reached"""
	check_campaign_unlocks()

func _on_day_changed(day: int) -> void:
	"""Update active campaigns when a new day starts"""
	update_campaigns(day)

func check_campaign_unlocks() -> void:
	"""Check which campaigns should be unlocked based on revenue"""
	if not ProgressionManager:
		return

	var revenue: float = ProgressionManager.get_total_revenue()

	for campaign_id in available_campaigns:
		var campaign: Dictionary = available_campaigns[campaign_id]

		if not campaign.get("unlocked", false) and campaign.has("unlock_revenue"):
			if revenue >= campaign["unlock_revenue"]:
				campaign["unlocked"] = true
				print("🎯 Marketing unlocked: %s" % campaign["name"])

func start_campaign(campaign_id: String) -> bool:
	"""Start a marketing campaign"""
	if not available_campaigns.has(campaign_id):
		push_warning("Unknown campaign: %s" % campaign_id)
		return false

	var campaign: Dictionary = available_campaigns[campaign_id]

	# Check if unlocked
	if not campaign.get("unlocked", false):
		print("Campaign not yet unlocked: %s" % campaign["name"])
		return false

	# Check reputation requirement
	if ProgressionManager and campaign.has("reputation_cost"):
		if ProgressionManager.get_reputation() < campaign["reputation_cost"]:
			print("Insufficient reputation for %s (need %d)" % [campaign["name"], campaign["reputation_cost"]])
			return false

	# Check if one-time campaign already active
	if campaign.get("one_time", false):
		for active in active_campaigns:
			if active["id"] == campaign_id:
				print("One-time campaign already active: %s" % campaign["name"])
				return false
		if campaign_id in campaign_history:
			print("One-time campaign already used: %s" % campaign["name"])
			return false

	# Check cost
	if EconomyManager:
		if EconomyManager.get_current_cash() < campaign["cost"]:
			print("Insufficient funds for %s ($%.2f needed)" % [campaign["name"], campaign["cost"]])
			return false

		# Deduct cost
		EconomyManager.remove_money(campaign["cost"], "Marketing: " + campaign["name"])

	total_marketing_spent += campaign["cost"]

	# Create active campaign
	var active_campaign: Dictionary = {
		"id": campaign_id,
		"name": campaign["name"],
		"start_day": GameManager.get_current_day() if GameManager else 1,
		"duration": campaign["duration_days"],
		"effects": campaign.get("effects", {}).duplicate(true),
		"data": campaign.duplicate(true)
	}

	active_campaigns.append(active_campaign)
	campaign_history.append(campaign_id)

	# Apply immediate effects
	apply_campaign_effects(active_campaign)

	print("\n📢 Campaign Started: %s" % campaign["name"])
	print("Cost: $%.2f" % campaign["cost"])
	print("Duration: %s" % ("Permanent" if campaign["duration_days"] == -1 else "%d days" % campaign["duration_days"]))
	print("Traffic boost: +%.0f%%" % ((campaign["traffic_boost"] - 1.0) * 100))

	campaign_started.emit(campaign_id, campaign)
	return true

func apply_campaign_effects(campaign: Dictionary) -> void:
	"""Apply the effects of a campaign"""
	var effects: Dictionary = campaign.get("effects", {})

	# Traffic multiplier
	if effects.has("traffic_multiplier") and CustomerManager:
		var multiplier: float = effects["traffic_multiplier"]
		CustomerManager.add_traffic_modifier("marketing_" + campaign["id"], multiplier)
		traffic_boost_applied.emit(multiplier)

	# One-time reputation gain
	if effects.has("brand_recognition") and ProgressionManager:
		ProgressionManager.modify_reputation(effects["brand_recognition"])
		print("  +%d reputation (brand recognition)" % effects["brand_recognition"])

	if effects.has("reputation_gain") and ProgressionManager:
		ProgressionManager.modify_reputation(effects["reputation_gain"])
		print("  +%d reputation" % effects["reputation_gain"])

func update_campaigns(current_day: int) -> void:
	"""Update campaign durations and remove expired ones"""
	var expired: Array[Dictionary] = []

	for i in range(active_campaigns.size() - 1, -1, -1):
		var campaign: Dictionary = active_campaigns[i]

		# Skip permanent campaigns
		if campaign["duration"] == -1:
			continue

		# Calculate days elapsed
		var days_elapsed: int = current_day - campaign["start_day"]

		if days_elapsed >= campaign["duration"]:
			expired.append(campaign)
			active_campaigns.remove_at(i)

	# Remove effects of expired campaigns
	for campaign in expired:
		remove_campaign_effects(campaign)
		print("📢 Campaign Ended: %s" % campaign["name"])
		campaign_ended.emit(campaign["id"])

func remove_campaign_effects(campaign: Dictionary) -> void:
	"""Remove the effects of an expired campaign"""
	var effects: Dictionary = campaign.get("effects", {})

	# Remove traffic multiplier
	if effects.has("traffic_multiplier") and CustomerManager:
		CustomerManager.remove_traffic_modifier("marketing_" + campaign["id"])

func end_campaign(campaign_id: String) -> bool:
	"""Manually end a campaign (for permanent ones)"""
	for i in range(active_campaigns.size() - 1, -1, -1):
		if active_campaigns[i]["id"] == campaign_id:
			var campaign: Dictionary = active_campaigns[i]
			remove_campaign_effects(campaign)
			active_campaigns.remove_at(i)
			print("Campaign manually ended: %s" % campaign["name"])
			campaign_ended.emit(campaign_id)
			return true

	return false

func get_active_campaigns() -> Array[Dictionary]:
	"""Get list of currently active campaigns"""
	return active_campaigns.duplicate()

func get_available_campaigns() -> Array[Dictionary]:
	"""Get list of campaigns player can purchase"""
	var available: Array[Dictionary] = []

	for campaign_id in available_campaigns:
		var campaign: Dictionary = available_campaigns[campaign_id]

		if campaign.get("unlocked", false):
			var campaign_info: Dictionary = campaign.duplicate(true)
			campaign_info["id"] = campaign_id

			# Check if already active (for one-time campaigns)
			campaign_info["already_active"] = false
			if campaign.get("one_time", false):
				for active in active_campaigns:
					if active["id"] == campaign_id:
						campaign_info["already_active"] = true
						break

			available.append(campaign_info)

	return available

func get_total_traffic_boost() -> float:
	"""Calculate total traffic boost from all active campaigns"""
	var total_boost: float = 1.0

	for campaign in active_campaigns:
		if campaign["effects"].has("traffic_multiplier"):
			total_boost *= campaign["effects"]["traffic_multiplier"]

	return total_boost

func is_campaign_active(campaign_id: String) -> bool:
	"""Check if a specific campaign is currently active"""
	for campaign in active_campaigns:
		if campaign["id"] == campaign_id:
			return true
	return false

func get_campaign_info(campaign_id: String) -> Dictionary:
	"""Get detailed info about a campaign"""
	if available_campaigns.has(campaign_id):
		var info: Dictionary = available_campaigns[campaign_id].duplicate(true)
		info["id"] = campaign_id
		info["is_active"] = is_campaign_active(campaign_id)
		return info
	return {}

func get_marketing_stats() -> Dictionary:
	"""Get marketing statistics"""
	return {
		"total_spent": total_marketing_spent,
		"active_campaigns": active_campaigns.size(),
		"campaigns_run": campaign_history.size(),
		"current_traffic_boost": get_total_traffic_boost()
	}

# Save/Load support
func get_save_data() -> Dictionary:
	return {
		"active_campaigns": active_campaigns.duplicate(true),
		"campaign_history": campaign_history.duplicate(),
		"total_marketing_spent": total_marketing_spent,
		"available_campaigns": available_campaigns.duplicate(true)  # Save unlock status
	}

func load_save_data(data: Dictionary) -> void:
	if data.has("active_campaigns"):
		active_campaigns = data["active_campaigns"]
		# Reapply campaign effects
		for campaign in active_campaigns:
			apply_campaign_effects(campaign)

	if data.has("campaign_history"):
		campaign_history = data["campaign_history"]

	if data.has("total_marketing_spent"):
		total_marketing_spent = data["total_marketing_spent"]

	if data.has("available_campaigns"):
		# Restore unlock status
		var saved_campaigns: Dictionary = data["available_campaigns"]
		for campaign_id in saved_campaigns:
			if available_campaigns.has(campaign_id):
				available_campaigns[campaign_id]["unlocked"] = saved_campaigns[campaign_id].get("unlocked", false)

	print("Marketing data loaded: $%.2f spent, %d campaigns active" % [total_marketing_spent, active_campaigns.size()])
