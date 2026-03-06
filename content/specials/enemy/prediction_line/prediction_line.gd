extends Line2D

signal duration_timeout()

onready var duration_timer: Timer = $"Timer"

var idle_time_after_pushed_back: float = 10.0
var already_recycle: bool = false

# =========================== Extension =========================== #
func _ready() -> void:
    reset()

func reset() -> void:
    hide()
    clear_points()

func draw_prediction(duration: float) -> void:
    duration_timer.wait_time = duration
    duration_timer.start()
    show()

# =========================== Method =========================== #
func fa_on_DurationTimerTimeout() -> void:
    emit_signal("duration_timeout")
    reset()
