extends DoubleValueEffect

# =========================== Extension =========================== #
static func get_id() -> String:
    return "fantasy_crit_overflow_stat"

func get_args(player_index: int) -> Array:
    var crit_chance: float = RunData.get_stat(Keys.stat_crit_chance_hash, player_index) + TempStats.get_stat(Keys.stat_crit_chance_hash, player_index)
    var crit_overflow: float = max(0.0, crit_chance - 100.0)
    var bonus: int = value * int(crit_overflow / float(value2))

    return [str(value), tr(key.to_upper()), str(value2), str(bonus)]
