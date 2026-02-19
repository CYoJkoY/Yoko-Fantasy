extends DoubleValueEffect

export(int) var stat_nb = 0
export(int) var trigger_times = 1

# =========================== Extension =========================== #
static func get_id() -> String:
	return "fantasy_decaying_slow_enemy_when_below_hp"

func apply(player_index: int) -> void:
    if key == "": return

    var effects = RunData.get_player_effects(player_index)
    effects[key_hash].append([value, value2, stat_nb, trigger_times])

func unapply(player_index: int) -> void:
    if key == "": return

    var effects = RunData.get_player_effects(player_index)
    effects[key_hash].erase([value, value2, stat_nb, trigger_times])

func get_args(_player_index: int) -> Array:
    return [str(value), str(value2), str(stat_nb), str(trigger_times)]

func serialize() -> Dictionary:
    var serialized =.serialize()
    serialized.stat_nb = stat_nb
    serialized.trigger_times = trigger_times

    return serialized

func deserialize_and_merge(serialized: Dictionary) -> void:
    .deserialize_and_merge(serialized)
    stat_nb = serialized.stat_nb as int
    trigger_times = serialized.trigger_times as int
