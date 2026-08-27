extends PlayerEffectBehavior

var _fixed_effects: Array = []
var _percent_effects: Array = []
var _fixed_elapsed: Array = []
var _percent_elapsed: Array = []
var _effects_initialized: bool = false
var _was_stationary: bool = false


func should_add_on_spawn() -> bool:
    if RunData.get_player_effect(Utils.fantasy_stationary_temp_stats_per_interval_hash, _player_index).size() > 0:
        return true

    return RunData.get_player_effect(Utils.fantasy_stationary_percent_stat_per_interval_hash, _player_index).size() > 0


func _process(delta: float) -> void:
    if _parent == null or _parent.dead or _parent.cleaning_up:
        return
    if !_effects_initialized:
        _fantasy_initialize_effects()

    if _parent._current_movement != Vector2.ZERO:
        if _was_stationary:
            _fantasy_reset_elapsed()
            _was_stationary = false
        return

    _was_stationary = true
    _fantasy_process_fixed_effects(delta)
    _fantasy_process_percent_effects(delta)


func _fantasy_initialize_effects() -> void:
    _fixed_effects = RunData.get_player_effect(Utils.fantasy_stationary_temp_stats_per_interval_hash, _player_index)
    _percent_effects = RunData.get_player_effect(Utils.fantasy_stationary_percent_stat_per_interval_hash, _player_index)
    _fixed_elapsed.resize(_fixed_effects.size())
    _percent_elapsed.resize(_percent_effects.size())
    _fantasy_reset_elapsed()
    _effects_initialized = true


func _fantasy_reset_elapsed() -> void:
    for i in range(_fixed_elapsed.size()):
        _fixed_elapsed[i] = 0.0
    for i in range(_percent_elapsed.size()):
        _percent_elapsed[i] = 0.0


func _fantasy_process_fixed_effects(delta: float) -> void:
    for i in range(_fixed_effects.size()):
        var effect: Array = _fixed_effects[i]
        if effect.size() < 3:
            continue
        var interval: float = max(0.01, float(effect[2]))
        _fixed_elapsed[i] += delta
        while _fixed_elapsed[i] >= interval:
            _fixed_elapsed[i] -= interval
            TempStats.add_stat(effect[0], effect[1], _player_index)
            if effect.size() >= 4 and effect[3]:
                var floating_text_db_mod: float = float(effect[4]) if effect.size() >= 5 else -15.0
                if effect[1] >= 0:
                    RunData.emit_signal("stat_added", effect[0], effect[1], floating_text_db_mod, _player_index)
                else:
                    RunData.emit_signal("stat_removed", effect[0], abs(effect[1]), floating_text_db_mod, _player_index)


func _fantasy_process_percent_effects(delta: float) -> void:
    for i in range(_percent_effects.size()):
        var effect: Array = _percent_effects[i]
        if effect.size() < 4:
            continue
        var interval: float = max(0.01, float(effect[2]))
        _percent_elapsed[i] += delta
        while _percent_elapsed[i] >= interval:
            _percent_elapsed[i] -= interval

            var current_stat: float = Utils.get_stat(effect[0], _player_index)
            var stat_gain: int = int(max(1.0, abs(current_stat * effect[1] / 100.0)))
            if effect[3] > 0:
                stat_gain = int(min(stat_gain, int(effect[3])))
            if effect[1] < 0:
                stat_gain *= -1
            TempStats.add_stat(effect[0], stat_gain, _player_index)
            if effect.size() >= 5 and effect[4]:
                var floating_text_db_mod: float = float(effect[5]) if effect.size() >= 6 else -15.0
                if stat_gain >= 0:
                    RunData.emit_signal("stat_added", effect[0], stat_gain, floating_text_db_mod, _player_index)
                else:
                    RunData.emit_signal("stat_removed", effect[0], abs(stat_gain), floating_text_db_mod, _player_index)
