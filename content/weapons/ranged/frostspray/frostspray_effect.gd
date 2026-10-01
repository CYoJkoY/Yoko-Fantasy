extends NullEffect

export (int) var shard_count: int = 4
export (int) var shard_damage_percent: int = 25
export (int) var slow_percent: int = 35


static func get_id() -> String:
	return "weapon_frostspray"


func get_args(_player_index: int) -> Array:
	return [str(shard_count), "%s%%" % shard_damage_percent, "%s%%" % slow_percent]


func serialize() -> Dictionary:
	var serialized := .serialize()
	serialized.shard_count = shard_count
	serialized.shard_damage_percent = shard_damage_percent
	serialized.slow_percent = slow_percent
	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)
	shard_count = serialized.shard_count
	shard_damage_percent = serialized.shard_damage_percent
	if serialized.has("slow_percent"):
		slow_percent = serialized.slow_percent
