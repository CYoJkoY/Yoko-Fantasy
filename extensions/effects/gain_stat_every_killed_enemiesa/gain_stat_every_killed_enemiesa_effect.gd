extends GainStatEveryKilledEnemiesEffect

export(bool) var is_temp = true

# =========================== Extension =========================== #
static func get_id() -> String:
    return "fantasy_gain_stat_every_killed_enemies"

func get_args(_player_index: int) -> Array:
    var temp_text: String = tr("SUFFIX_UNTIL_END") if is_temp else tr("EMPTY")

    return [str(stat_nb), tr(stat.to_upper()), str(value), temp_text]

func apply(player_index: int) -> void:
    if key_hash == Keys.empty_hash: return
    
    var effects: Dictionary = RunData.get_player_effects(player_index)
    effects[key_hash].append([value, stat_hash, stat_nb, is_temp])

func unapply(player_index: int) -> void:
    if key_hash == Keys.empty_hash: return
    
    var effects: Dictionary = RunData.get_player_effects(player_index)
    effects[key_hash].erase([value, stat_hash, stat_nb, is_temp])

func serialize() -> Dictionary:
    var serialized =.serialize()
    serialized.is_temp = is_temp

    return serialized


func deserialize_and_merge(serialized: Dictionary) -> void:
    .deserialize_and_merge(serialized)
    is_temp = serialized.is_temp as bool
