extends NullEffect

# =========================== Extension =========================== #
static func get_id() -> String:
	return "fantasy_change_weapon_every_killed_enemies"

func get_args(_player_index: int) -> Array:
	var str_value: String = "[color=#%s]%s[/color]" % [ProgressData.settings.color_positive, str(value)]
	var weapon_name = Utils.ncl_get_gear_name_from_id(key_hash)

	return [str_value, weapon_name]
