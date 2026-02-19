extends Enemy

var _cache_current_speed: int

# =========================== Method =========================== #
func nullify_speed() -> void:
    _cache_current_speed = current_stats.speed
    current_stats.speed = 0

func recovery_speed() -> void:
    current_stats.speed = _cache_current_speed
