extends Line2D

signal duration_timeout()

var already_recycle: bool = false
var _default_width_curve: Curve = null

onready var duration_timer: Timer = $"Timer"

# ══════════════════════════════════════════ Extension ══════════════════════════════════════════ #
func _ready() -> void:
    if material != null:
        material = material.duplicate()
    _default_width_curve = width_curve
    reset()

func reset() -> void:
    if duration_timer != null:
        duration_timer.stop()
    width_curve = _default_width_curve
    hide()
    clear_points()

func draw_prediction(duration: float = 0.0) -> void:
    if duration <= 0:
        material.set_shader_param("line_color", default_color)
        show()
        return

    duration_timer.wait_time = duration
    duration_timer.start()
    material.set_shader_param("line_color", default_color)
    show()

# ══════════════════════════════════════════ Method ══════════════════════════════════════════ #
func fa_on_DurationTimerTimeout() -> void:
    emit_signal("duration_timeout")
    reset()
