extends DoubleValueEffect

static func get_id() -> String:
	return "fantasy_time_bonus_current_health_damage"

func get_args(_player_index: int) -> Array:
    return [str(value), str(value2), str(value2 / 10.0)]
