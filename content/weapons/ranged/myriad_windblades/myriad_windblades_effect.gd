extends NullEffect

export (int) var wind_force_ticks: int = 2
export (int) var base_damage: int = 2
export (Array, Array) var scaling_stats: Array = [["stat_elemental_damage", 0.25]]
export (float) var wind_force_tick_interval: float = 0.13


func duplicate(subresources: bool = false) -> Resource:
	var duplication = .duplicate(subresources)
	duplication.scaling_stats = Utils.convert_to_hash_array(scaling_stats)
	return duplication


static func get_id() -> String:
	return "weapon_myriad_windblades"


func _generate_hashes() -> void:
	._generate_hashes()
	scaling_stats = Utils.convert_to_hash_array(scaling_stats)


func get_args(player_index: int) -> Array:
	var dmg_text: String = Utils.ncl_get_dmg_text_with_scaling_stats(
		base_damage,
		scaling_stats,
		{
			"player_index": player_index
		}
	)
	return [str(wind_force_ticks), dmg_text]


func serialize() -> Dictionary:
	var serialized: Dictionary = .serialize()
	serialized.wind_force_ticks = wind_force_ticks
	serialized.base_damage = base_damage
	serialized.scaling_stats = scaling_stats
	serialized.wind_force_tick_interval = wind_force_tick_interval
	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)
	wind_force_ticks = serialized.wind_force_ticks
	base_damage = serialized.base_damage
	scaling_stats = Utils.convert_to_hash_array(serialized.get("scaling_stats", []))
	wind_force_tick_interval = serialized.wind_force_tick_interval
