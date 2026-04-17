extends NullEffect

var damage_to_add: int = 0
var speed_to_add: int = 0
var main: Main = Utils.get_scene_node()

# =========================== Extension =========================== #
func apply(player_index: int) -> void:
    Utils.ncl_quiet_add_stat(Utils.stat_fantasy_soul_hash, value, player_index)
    
    var base_damage: float = Utils.get_stat(Keys.stat_percent_damage_hash, player_index)
    var base_speed: float = Utils.get_stat(Keys.stat_attack_speed_hash, player_index)
    
    var bonus: float = (10 + RunData.get_player_effect(Utils.fantasy_soul_bonus_hash, player_index)) / 100.0

    damage_to_add = 10 + int(base_damage * bonus) if base_damage > 0 else 10
    speed_to_add = 10 + int(base_speed * bonus) if base_speed > 0 else 10

    TempStats.add_stat(Keys.stat_percent_damage_hash, damage_to_add, player_index)
    TempStats.add_stat(Keys.stat_attack_speed_hash, speed_to_add, player_index)
    RunData.emit_signal("on_soul_effect", damage_to_add, speed_to_add, player_index)
