extends Node2D

onready var hour_clock = $"HourClock"
onready var minute_clock = $"MinuteClock"

var minutes: int = 0

# =========================== Custom =========================== #
func _fantasy_get_bullets() -> Array:
    var bullets: Array = []
    bullets.append_array(hour_clock.get_children())
    bullets.append_array(minute_clock.get_children())

    return bullets

func _fantasy_get_all_top_positions(is_hour: bool) -> Array:
    if is_hour: return hour_clock._fantasy_get_all_top_positions()
    else: return minute_clock._fantasy_get_all_top_positions()

# =========================== Method =========================== #
func fa_remove_prediction_line() -> void:
    minute_clock.prediction_line.queue_free()
