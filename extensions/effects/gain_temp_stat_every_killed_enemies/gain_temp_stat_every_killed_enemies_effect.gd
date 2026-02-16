extends GainStatEveryKilledEnemiesEffect

# =========================== Extension =========================== #
static func get_id() -> String:
    return "fantasy_gain_temp_stat_every_killed_enemies"

func apply(player_index: int) -> void:
    if key_hash == Keys.empty_hash: return
    
    var effects: Dictionary = RunData.get_player_effects(player_index)
    effects[key_hash].append([value, stat_hash, stat_nb])
    Utils.reset_stat_cache(player_index)

func unapply(player_index: int) -> void:
    if key_hash == Keys.empty_hash: return
    
    var effects: Dictionary = RunData.get_player_effects(player_index)
    effects[key_hash].erase([value, stat_hash, stat_nb])
    Utils.reset_stat_cache(player_index)
