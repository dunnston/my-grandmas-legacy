extends CanvasLayer

# SleepTransition - Handles visual transitions for sleeping (fade in/out)

# Signals
signal fade_complete()
signal wake_complete()

# Node references
@onready var fade_overlay: ColorRect = $FadeOverlay

# Transition state
var is_fading: bool = false
var fade_duration: float = 2.0
var current_fade_time: float = 0.0
var fade_target_alpha: float = 0.0
var fade_start_alpha: float = 0.0

func _ready() -> void:
	# Start with transparent overlay
	if fade_overlay:
		fade_overlay.color.a = 0.0

func _process(delta: float) -> void:
	if not is_fading:
		return

	current_fade_time += delta

	if current_fade_time >= fade_duration:
		# Complete fade
		_complete_fade()
		return

	# Interpolate alpha
	var progress = current_fade_time / fade_duration
	var new_alpha = lerp(fade_start_alpha, fade_target_alpha, progress)

	if fade_overlay:
		fade_overlay.color.a = new_alpha

func fade_to_black(duration: float = 2.0) -> void:
	"""Fade from transparent to black"""
	print("[SleepTransition] Fading to black...")

	fade_duration = duration
	fade_start_alpha = 0.0
	fade_target_alpha = 1.0
	current_fade_time = 0.0
	is_fading = true

	if fade_overlay:
		fade_overlay.show()
		fade_overlay.color.a = fade_start_alpha

func fade_from_black(duration: float = 2.0) -> void:
	"""Fade from black to transparent"""
	print("[SleepTransition] Fading from black...")

	fade_duration = duration
	fade_start_alpha = 1.0
	fade_target_alpha = 0.0
	current_fade_time = 0.0
	is_fading = true

	if fade_overlay:
		fade_overlay.show()
		fade_overlay.color.a = fade_start_alpha

func _complete_fade() -> void:
	"""Complete the current fade"""
	is_fading = false

	if fade_overlay:
		fade_overlay.color.a = fade_target_alpha

	# Hide overlay if fully transparent
	if fade_target_alpha <= 0.0:
		if fade_overlay:
			fade_overlay.hide()
		wake_complete.emit()
	else:
		fade_complete.emit()

	print("[SleepTransition] Fade complete (alpha: %.2f)" % fade_target_alpha)
