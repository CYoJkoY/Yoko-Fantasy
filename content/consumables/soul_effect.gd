extends NullEffect

var _added_damage_values: Dictionary = {}
var _added_speed_values: Dictionary = {}
var _bonus_applied: Dictionary = {}

# =========================== Extension =========================== #
func apply(player_index: int) -> void:
    Utils.ncl_quiet_add_stat(Utils.stat_fantasy_soul_hash, value, player_index)
    
    if _bonus_applied.get(player_index, false): return
    
    _apply_bonus_effects(player_index)
    _reset_decay_timer(player_index)

# =========================== Custom =========================== #
func _apply_bonus_effects(player_index: int) -> void:
    var base_damage: float = Utils.get_stat(Keys.stat_percent_damage_hash, player_index)
    var base_speed: float = Utils.get_stat(Keys.stat_attack_speed_hash, player_index)
    
    var bonus: float = (20 + RunData.get_player_effect(Utils.fantasy_soul_bonus_hash, player_index)) / 100.0
    var damage_to_add: int = 0
    var speed_to_add: int = 0

    if base_damage > 0:
        damage_to_add = int(base_damage * bonus)
        Utils.ncl_quiet_add_stat(Keys.stat_percent_damage_hash, damage_to_add, player_index)
    
    if base_speed > 0:
        speed_to_add = int(base_speed * bonus)
        Utils.ncl_quiet_add_stat(Keys.stat_attack_speed_hash, speed_to_add, player_index)
    
    _added_damage_values.set(player_index, damage_to_add)
    _added_speed_values.set(player_index, speed_to_add)
    _bonus_applied.set(player_index, true)

func _reset_decay_timer(player_index: int) -> void:
    var player: Player = Utils.get_scene_node()._players[player_index]
    if player.has_meta("stat_fantasy_soul_decay_timer"): return

    var timer: Timer = Timer.new()
    timer.wait_time = 2.0
    player.add_child(timer)
    timer.connect("timeout", self , "fa_on_decay_timeout", [player_index])
    timer.start()
    player.set_meta("stat_fantasy_soul_decay_timer", timer)

func _remove_bonus_effects(player_index: int) -> void:
    var damage_to_remove: int = _added_damage_values[player_index]
    var speed_to_remove: int = _added_speed_values[player_index]
    
    if damage_to_remove > 0:
        Utils.ncl_quiet_add_stat(Keys.stat_percent_damage_hash, -damage_to_remove, player_index)
    if speed_to_remove > 0:
        Utils.ncl_quiet_add_stat(Keys.stat_attack_speed_hash, -speed_to_remove, player_index)

    _added_damage_values.erase(player_index)
    _added_speed_values.erase(player_index)
    
    var player: Player = Utils.get_scene_node()._players[player_index]
    var timer: Timer = player.get_meta("stat_fantasy_soul_decay_timer")
    timer.stop()
    timer.queue_free()
    player.remove_meta("stat_fantasy_soul_decay_timer")
    
    _bonus_applied.erase(player_index)

# =========================== Method =========================== #
func fa_on_decay_timeout(player_index: int) -> void:
    var current_soul: float = RunData.get_stat(Utils.stat_fantasy_soul_hash, player_index)
    Utils.ncl_quiet_add_stat(Utils.stat_fantasy_soul_hash, -value, player_index)
    current_soul = max(current_soul - value, 0)
    
    if current_soul < 1:
        _remove_bonus_effects(player_index)
