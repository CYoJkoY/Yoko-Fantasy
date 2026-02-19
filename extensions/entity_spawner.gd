extends "res://global/entity_spawner.gd"

# EFFECT : gain_temp_stat_every_killed_enemies
var gain_temp_stat_ever_killed_enemies_killed_count: Array = [0, 0, 0, 0]

# =========================== Extension =========================== #
func _on_enemy_died(enemy: Node2D, _args: Entity.DieArgs) -> void:
    ._on_enemy_died(enemy, _args)
    if !_cleaning_up:
        _fantasy_gain_temp_stat_every_killed_enemies()

# =========================== Custom =========================== #
func _fantasy_gain_temp_stat_every_killed_enemies() -> void:
    for player_index in RunData.get_player_count():
        var effect_items: Array = RunData.get_player_effect(Utils.fantasy_gain_temp_stat_every_killed_enemies_hash, player_index)
        gain_temp_stat_ever_killed_enemies_killed_count[player_index] += 1
        for effect in effect_items:
            var value: int = effect[0]
            var stat: int = effect[1]
            var stat_nb: int = effect[2]

            if gain_temp_stat_ever_killed_enemies_killed_count[player_index] % value != 0: continue

            TempStats.add_stat(stat, stat_nb, player_index)

            # Update when add hit_protection
            if stat == Keys.hit_protection_hash:
                _main._players[player_index]._hit_protection += stat_nb
