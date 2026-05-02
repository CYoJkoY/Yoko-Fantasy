extends Effect

# =========================== Extension =========================== #
static func get_id() -> String:
	return "fantasy_cursed_kill_healing"

func apply(player_index: int) -> void:
	if custom_key_hash == Keys.empty_hash: return

	var effects = RunData.get_player_effects(player_index)
	effects[custom_key_hash].append([value, key_hash])

func unapply(player_index: int) -> void:
	if custom_key_hash == Keys.empty_hash: return

	var effects = RunData.get_player_effects(player_index)
	effects[custom_key_hash].erase([value, key_hash])

func get_args(_player_index: int) -> Array:
	var tracking_value: int = int(RunData.ncl_get_effect_tracking_value(key_hash, _player_index))
	var tracking: String = Utils.ncl_create_tracking("HEALTH_RECOVERED", tracking_value)

	return [str(value), tracking]
