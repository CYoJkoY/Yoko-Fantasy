extends NullEffect

export (int) var petal_count: int = 3
export (int) var petal_damage_percent: int = 45
export (int) var slow_percent: int = 35


static func get_id() -> String:
	return "weapon_myriad_flourish"


func get_args(_player_index: int) -> Array:
	return [str(petal_count), "%s%%" % petal_damage_percent, "%s%%" % slow_percent]


func serialize() -> Dictionary:
	var serialized := .serialize()
	serialized.petal_count = petal_count
	serialized.petal_damage_percent = petal_damage_percent
	serialized.slow_percent = slow_percent
	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)
	petal_count = serialized.petal_count
	petal_damage_percent = serialized.petal_damage_percent
	slow_percent = serialized.slow_percent
