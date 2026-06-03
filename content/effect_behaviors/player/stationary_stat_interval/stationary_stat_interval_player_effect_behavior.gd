extends PlayerEffectBehavior

var _fixed_elapsed: Dictionary = {}
var _percent_elapsed: Dictionary = {}


func should_add_on_spawn() -> bool:
	if RunData.get_player_effect(Utils.fantasy_stationary_temp_stats_per_interval_hash, _player_index).size() > 0:
		return true

	return RunData.get_player_effect(Utils.fantasy_stationary_percent_stat_per_interval_hash, _player_index).size() > 0


func _process(delta: float) -> void:
	if _parent == null or _parent.dead or _parent.cleaning_up:
		return

	if _parent._current_movement != Vector2.ZERO:
		_fixed_elapsed.clear()
		_percent_elapsed.clear()
		return

	_fantasy_process_fixed_effects(delta)
	_fantasy_process_percent_effects(delta)


func _fantasy_process_fixed_effects(delta: float) -> void:
	var effect_items: Array = RunData.get_player_effect(Utils.fantasy_stationary_temp_stats_per_interval_hash, _player_index)
	for effect in effect_items:
		if effect.size() < 3:
			continue

		var stat_hash: int = effect[0]
		var stat_value: int = effect[1]
		var interval: float = max(0.01, float(effect[2]))
		var show_floating_text: bool = effect[3] if effect.size() >= 4 else false
		var floating_text_db_mod: float = float(effect[4]) if effect.size() >= 5 else -15.0
		var effect_key: String = "%s:%s:%s" % [stat_hash, stat_value, interval]

		_fixed_elapsed[effect_key] = _fixed_elapsed.get(effect_key, 0.0) + delta
		while _fixed_elapsed[effect_key] >= interval:
			_fixed_elapsed[effect_key] -= interval
			TempStats.add_stat(stat_hash, stat_value, _player_index)
			if show_floating_text:
				if stat_value >= 0:
					RunData.emit_signal("stat_added", stat_hash, stat_value, floating_text_db_mod, _player_index)
				else:
					RunData.emit_signal("stat_removed", stat_hash, abs(stat_value), floating_text_db_mod, _player_index)


func _fantasy_process_percent_effects(delta: float) -> void:
	var effect_items: Array = RunData.get_player_effect(Utils.fantasy_stationary_percent_stat_per_interval_hash, _player_index)
	for effect in effect_items:
		if effect.size() < 4:
			continue

		var stat_hash: int = effect[0]
		var percent_value: int = effect[1]
		var interval: float = max(0.01, float(effect[2]))
		var max_gain: int = effect[3]
		var show_floating_text: bool = effect[4] if effect.size() >= 5 else false
		var floating_text_db_mod: float = float(effect[5]) if effect.size() >= 6 else -15.0
		var effect_key: String = "%s:%s:%s:%s" % [stat_hash, percent_value, interval, max_gain]

		_percent_elapsed[effect_key] = _percent_elapsed.get(effect_key, 0.0) + delta
		while _percent_elapsed[effect_key] >= interval:
			_percent_elapsed[effect_key] -= interval
			var current_stat: float = Utils.get_stat(stat_hash, _player_index)
			var stat_gain: int = int(max(1.0, abs(current_stat * percent_value / 100.0)))
			if max_gain > 0:
				stat_gain = min(stat_gain, max_gain)
			if percent_value < 0:
				stat_gain *= -1
			TempStats.add_stat(stat_hash, stat_gain, _player_index)
			if show_floating_text:
				if stat_gain >= 0:
					RunData.emit_signal("stat_added", stat_hash, stat_gain, floating_text_db_mod, _player_index)
				else:
					RunData.emit_signal("stat_removed", stat_hash, abs(stat_gain), floating_text_db_mod, _player_index)
