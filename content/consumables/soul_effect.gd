extends NullEffect

var _added_damage_values: Array = [0, 0, 0, 0]
var _added_speed_values: Array = [0, 0, 0, 0]
var _bonus_applied: Array = [false, false, false, false]
var timers: Array = [null, null, null, null]

# =========================== Extension =========================== #
func apply(player_index: int) -> void:
    Utils.ncl_quiet_add_stat(Utils.stat_fantasy_soul_hash, value, player_index)
    
    if _bonus_applied[player_index]: return
    
    _apply_bonus_effects(player_index)

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
        _added_damage_values[player_index] += damage_to_add
    
    if base_speed > 0:
        speed_to_add = int(base_speed * bonus)
        Utils.ncl_quiet_add_stat(Keys.stat_attack_speed_hash, speed_to_add, player_index)
        _added_speed_values[player_index] += speed_to_add
    
    if timers[player_index]: return

    var timer = Timer.new()
    timer.wait_time = 2.0
    timer.connect("timeout", self , "fa_on_decay_timeout", [player_index])
    Utils.get_scene_node()._players[player_index].add_child(timer)
    timers[player_index] = timer
    timer.start()

    _bonus_applied[player_index] = true

func _remove_bonus_effects(player_index: int) -> void:
    var damage_to_remove: int = _added_damage_values[player_index]
    var speed_to_remove: int = _added_speed_values[player_index]
    
    if damage_to_remove > 0:
        Utils.ncl_quiet_add_stat(Keys.stat_percent_damage_hash, -damage_to_remove, player_index)
        _added_damage_values[player_index] -= damage_to_remove
    if speed_to_remove > 0:
        Utils.ncl_quiet_add_stat(Keys.stat_attack_speed_hash, -speed_to_remove, player_index)
        _added_speed_values[player_index] -= speed_to_remove
    
    var timer: Timer = timers[player_index]
    timer.stop()
    timer.queue_free()
    
    _bonus_applied[player_index] = false

# =========================== Method =========================== #
func fa_on_decay_timeout(player_index: int) -> void:
    var current_soul: float = RunData.get_stat(Utils.stat_fantasy_soul_hash, player_index)
    Utils.ncl_quiet_add_stat(Utils.stat_fantasy_soul_hash, -value, player_index)
    current_soul = max(current_soul - value, 0)
    
    if current_soul < 1: _remove_bonus_effects(player_index)
