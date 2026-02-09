extends Effect

# =========================== Extension =========================== #
static func get_id() -> String:
    return "fantasy_random_reload_when_pickup_gold"

func get_args(_player_index: int) -> Array:
    var tracking_value: int = RunData.ncl_get_effect_tracking_value(key_hash, _player_index)
    var tracking: String = Utils.ncl_create_tracking("TRACKING_RELOAD", tracking_value)

    return [str(value), tracking]
