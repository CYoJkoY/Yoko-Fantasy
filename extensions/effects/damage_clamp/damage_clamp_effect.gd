extends DoubleValueEffect

# =========================== Extension =========================== #
static func get_id() -> String:
    return "fantasy_damage_clamp"

func get_args(_player_index: int) -> Array:
    var tracking_value: int = RunData.ncl_get_effect_tracking_value(key_hash, _player_index)
    var tracking: String = Utils.ncl_create_tracking("TRACKING_DAMAGE_REDUCED", tracking_value)

    return [str(value), tr(key.to_upper()), str(value2), tracking]
