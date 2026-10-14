extends NullEffect

export (int) var shard_count: int = 3
export (int) var shard_damage_percent: int = 45


static func get_id() -> String:
	return "weapon_frostspray"


func get_args(_player_index: int) -> Array:
	return [str(shard_count), "%s%%" % shard_damage_percent]


func serialize() -> Dictionary:
	var serialized := .serialize()
	serialized.shard_count = shard_count
	serialized.shard_damage_percent = shard_damage_percent
	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)
	shard_count = serialized.shard_count
	shard_damage_percent = serialized.shard_damage_percent
