extends NullEffect

static func get_id() -> String:
	return "weapon_cross_staff"


func get_args(_player_index: int) -> Array:
	return [str(value)]
