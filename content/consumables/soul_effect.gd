extends NullEffect

const DAMAGE_MULTIPLIER = 0.20
const ATTACK_SPEED_MULTIPLIER = 0.20

var _added_damage_values = {}
var _added_speed_values = {}
var _bonus_applied = {}

func apply(player_index: int) -> void:
    TempStats.add_stat("fantasy_stat_soul", value, player_index)
    
    if not _bonus_applied.has(player_index) or not _bonus_applied[player_index]:
        var base_damage = Utils.get_stat("stat_percent_damage", player_index)
        var base_speed = Utils.get_stat("stat_attack_speed", player_index)
        
        var damage_to_add = int(base_damage * DAMAGE_MULTIPLIER)
        var speed_to_add = int(base_speed * ATTACK_SPEED_MULTIPLIER)
        
        TempStats.add_stat("stat_percent_damage", damage_to_add, player_index)
        TempStats.add_stat("stat_attack_speed", speed_to_add, player_index)
        
        _added_damage_values[player_index] = damage_to_add
        _added_speed_values[player_index] = speed_to_add
        _bonus_applied[player_index] = true
    
    _reset_decay_timer(player_index)

func _reset_decay_timer(player_index: int) -> void:
    var player = RunData.get_player(player_index)
    if player:
        if player.has_meta("fantasy_stat_soul_decay_timer"):
            var old_timer = player.get_meta("fantasy_stat_soul_decay_timer")
            if is_instance_valid(old_timer):
                old_timer.stop()
                old_timer.queue_free()
            player.remove_meta("fantasy_stat_soul_decay_timer")
        
        var timer = Timer.new()
        timer.wait_time = 2.0
        timer.one_shot = true
        player.add_child(timer)
        timer.connect("timeout", self, "_on_decay_timeout", [player_index])
        timer.start()
        player.set_meta("fantasy_stat_soul_decay_timer", timer)

func _on_decay_timeout(player_index: int) -> void:
    var current_soul = TempStats.get_stat("fantasy_stat_soul", player_index)
    if current_soul > 0:
        TempStats.remove_stat("fantasy_stat_soul", value, player_index)
        
        if TempStats.get_stat("fantasy_stat_soul", player_index) <= 0:
            _remove_bonus_effects(player_index)
        else:
            _reset_decay_timer(player_index)
    else:
        _remove_bonus_effects(player_index)

func _remove_bonus_effects(player_index: int) -> void:
    if _added_damage_values.has(player_index):
        var damage_to_remove = _added_damage_values[player_index]
        TempStats.remove_stat("stat_percent_damage", damage_to_remove, player_index)
        _added_damage_values.erase(player_index)
    
    if _added_speed_values.has(player_index):
        var speed_to_remove = _added_speed_values[player_index]
        TempStats.remove_stat("stat_attack_speed", speed_to_remove, player_index)
        _added_speed_values.erase(player_index)
    
    var player = RunData.get_player(player_index)
    if player and player.has_meta("fantasy_stat_soul_decay_timer"):
        var timer = player.get_meta("fantasy_stat_soul_decay_timer")
        if is_instance_valid(timer):
            timer.stop()
            timer.queue_free()
        player.remove_meta("fantasy_stat_soul_decay_timer")
    
    _bonus_applied.erase(player_index)
