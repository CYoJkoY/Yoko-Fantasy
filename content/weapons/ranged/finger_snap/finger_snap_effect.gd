extends NullEffect

export (int) var bullet_count: int = 3
export (int) var base_damage: int = 5
export (Array, Array) var scaling_stats: Array = [["stat_luck", 0.05]]


func duplicate(subresources: bool = false) -> Resource:
	var duplication = .duplicate(subresources)
	duplication.scaling_stats = Utils.convert_to_hash_array(scaling_stats)
	return duplication


static func get_id() -> String:
	return "weapon_finger_snap"


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
	return [str(bullet_count), dmg_text]


func serialize() -> Dictionary:
	var serialized: Dictionary = .serialize()
	serialized.bullet_count = bullet_count
	serialized.base_damage = base_damage
	serialized.scaling_stats = scaling_stats
	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)
	bullet_count = serialized.bullet_count
	base_damage = serialized.base_damage
	scaling_stats = Utils.convert_to_hash_array(serialized.get("scaling_stats", []))
