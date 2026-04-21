extends DoubleValueEffect

# =========================== Extension =========================== #
static func get_id() -> String:
    return "fantasy_limited_item_bonuses"

func get_args(player_index: int) -> Array:
    var limited_item_count: int = RunData.get_player_effect(Utils.fantasy_limited_item_hash, player_index)
    var bonus: int = value * int(limited_item_count / float(value2))

    return [str(value), tr(key.to_upper()), str(value2), str(bonus)]
