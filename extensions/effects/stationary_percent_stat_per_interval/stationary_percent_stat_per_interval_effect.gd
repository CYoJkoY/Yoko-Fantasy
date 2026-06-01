extends Effect

export(int) var value2: int = 0
export(int) var interval: int = 1
export(bool) var show_floating_text: bool = true
export(float) var floating_text_db_mod: float = -15.0


static func get_id() -> String:
	return "fantasy_stationary_percent_stat_per_interval"


func apply(player_index: int) -> void:
	if custom_key_hash == Keys.empty_hash:
		return

	var effects: Dictionary = RunData.get_player_effects(player_index)
	effects[custom_key_hash].append([key_hash, value, interval, value2, show_floating_text, floating_text_db_mod])


func unapply(player_index: int) -> void:
	if custom_key_hash == Keys.empty_hash:
		return

	var effects: Dictionary = RunData.get_player_effects(player_index)
	effects[custom_key_hash].erase([key_hash, value, interval, value2, show_floating_text, floating_text_db_mod])


func get_args(_player_index: int) -> Array:
	return [str(value), tr(key.to_upper()), str(interval), str(value2)]


func serialize() -> Dictionary:
	var serialized: Dictionary = .serialize()
	serialized.value2 = value2
	serialized.interval = interval
	serialized.show_floating_text = show_floating_text
	serialized.floating_text_db_mod = floating_text_db_mod

	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)
	value2 = serialized.get("value2", value2) as int
	interval = serialized.get("interval", interval) as int
	show_floating_text = serialized.get("show_floating_text", show_floating_text) as bool
	floating_text_db_mod = serialized.get("floating_text_db_mod", floating_text_db_mod) as float
