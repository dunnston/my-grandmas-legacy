## BakeryTask Resource
## Defines a single task/quest in the bakery progression system
class_name BakeryTask
extends Resource

## Task identification
@export var task_id: String = ""
@export var task_name: String = ""
@export_multiline var task_description: String = ""
@export_multiline var task_tips: String = ""

## Progression
@export var star_reward: float = 0.5  # Always 0.5 per task
@export var required_star_level: float = 0.0  # Unlocks at this star level
@export var is_main_task: bool = true  # Main progression task vs optional

## Category for organization
@export_enum(
	"customer_service",
	"baking_mastery",
	"business_growth",
	"upgrades",
	"recipe_mastery",
	"story",
	"efficiency",
	"special_challenge"
) var task_category: String = "baking_mastery"

## Completion tracking
@export var is_completed: bool = false
@export var progress_current: int = 0
@export var progress_required: int = 1

## Completion criteria type
@export_enum(
	"counter",  # Track a number (serve X customers, bake X items)
	"threshold",  # Reach a value (reputation, money)
	"boolean",  # Simple yes/no (hire employee, buy equipment)
	"collection",  # Multiple different items (bake X different recipes)
	"compound"  # Multiple requirements (reputation AND money)
) var completion_type: String = "counter"

## What stat/value to track
## Examples: "happy_customers", "perfect_items", "reputation", "daily_profit", "total_revenue"
@export var tracked_stat: String = ""

## For compound tasks: secondary requirement
@export var secondary_stat: String = ""
@export var secondary_required: int = 0

## Rewards beyond stars
@export var money_reward: int = 0
@export var reputation_reward: int = 0

## Content unlocks (recipe IDs, equipment IDs, story flags, etc.)
@export var unlocks: Array[String] = []

## Hidden tasks don't show until discovered
@export var is_hidden: bool = false

## Quest chain - task that unlocks after this one
@export var unlocks_task: String = ""


## Check if task can be started (star requirement met)
func can_start(current_stars: float) -> bool:
	return current_stars >= required_star_level


## Check if task is complete based on current progress
func check_completion() -> bool:
	if is_completed:
		return true

	match completion_type:
		"counter", "threshold":
			return progress_current >= progress_required
		"boolean":
			return progress_current > 0
		"collection":
			return progress_current >= progress_required
		"compound":
			# Check both primary and secondary requirements
			return progress_current >= progress_required and secondary_stat != ""
		_:
			return false


## Get progress percentage (0.0 to 1.0)
func get_progress_percentage() -> float:
	if progress_required == 0:
		return 1.0
	return clampf(float(progress_current) / float(progress_required), 0.0, 1.0)


## Get progress text for display
func get_progress_text() -> String:
	match completion_type:
		"counter", "collection":
			return "%d/%d" % [progress_current, progress_required]
		"threshold":
			return "%d/%d" % [progress_current, progress_required]
		"boolean":
			return "Complete" if is_completed else "Incomplete"
		"compound":
			var primary_text = "%d/%d" % [progress_current, progress_required]
			if secondary_stat != "":
				primary_text += " (" + secondary_stat + ")"
			return primary_text
		_:
			return ""


## Get status for display
func get_status_display() -> String:
	if is_completed:
		return "✓ COMPLETED"
	elif can_start(0):  # If already unlocked
		return "✓ IN PROGRESS"
	else:
		return "🔒 LOCKED"


## Create a save-friendly dictionary
func to_dict() -> Dictionary:
	return {
		"task_id": task_id,
		"is_completed": is_completed,
		"progress_current": progress_current,
		"progress_required": progress_required
	}


## Load from a dictionary
func from_dict(data: Dictionary) -> void:
	if data.has("is_completed"):
		is_completed = data.is_completed
	if data.has("progress_current"):
		progress_current = data.progress_current
	if data.has("progress_required"):
		progress_required = data.progress_required
