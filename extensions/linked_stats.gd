extends "res://singletons/linked_stats.gd"

# =========================== Extension =========================== #
func reset_player(player_index: int) -> void:
    .reset_player(player_index)
    _fantasy_apply_cirt_overflow_stat(player_index)


# =========================== Custom =========================== #
func _fantasy_apply_cirt_overflow_stat(player_index: int) -> void:
    var effect_items: Array = RunData.get_player_effect(Utils.fantasy_crit_overflow_stat_hash, player_index)
    if effect_items.empty(): return
    for effect_item in effect_items:
        var stat_hash: int = effect_item[0]
        var stat_add: int = effect_item[1]
        var crit_scaled: float = effect_item[2]

        var crit_chance: float = RunData.get_stat(Keys.stat_crit_chance_hash, player_index) + TempStats.get_stat(Keys.stat_crit_chance_hash, player_index)
        var crit_overflow: float = crit_chance - 100.0
        if crit_overflow <= 0: return

        var stat_add_times: int = int(crit_overflow / crit_scaled)
        if stat_add_times == 0: return

        add_stat(stat_hash, stat_add * stat_add_times, player_index)
        update_for_player_every_half_sec[player_index] = true
