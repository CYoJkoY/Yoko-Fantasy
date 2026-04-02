extends Line2D

signal duration_timeout()

onready var duration_timer: Timer = $"Timer"

var already_recycle: bool = false

# =========================== Extension =========================== #
func _ready() -> void:
    reset()

func reset() -> void:
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

# =========================== Method =========================== #
func fa_on_DurationTimerTimeout() -> void:
    emit_signal("duration_timeout")
    reset()
