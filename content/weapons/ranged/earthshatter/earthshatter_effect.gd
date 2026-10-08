extends NullEffect

export (int) var shard_count: int = 4
export (int) var shard_damage_percent: int = 40
export (int) var fissure_damage_percent: int = 100
export (int) var slow_percent: int = 25


static func get_id() -> String:
	return "weapon_earthshatter"


func get_args(_player_index: int) -> Array:
	return ["%s%%" % fissure_damage_percent, str(shard_count), "%s%%" % shard_damage_percent, "%s%%" % slow_percent]


func serialize() -> Dictionary:
	var serialized := .serialize()
	serialized.shard_count = shard_count
	serialized.shard_damage_percent = shard_damage_percent
	serialized.fissure_damage_percent = fissure_damage_percent
	serialized.slow_percent = slow_percent
	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)
	shard_count = serialized.shard_count
	shard_damage_percent = serialized.shard_damage_percent
	fissure_damage_percent = serialized.fissure_damage_percent
	slow_percent = serialized.slow_percent
