extends NullEffect

# =========================== Extension =========================== #
static func get_id() -> String:
	return "fantasy_change_weapon_every_killed_enemies"

func get_args(_player_index: int) -> Array:
	var str_value: String = "[color=#%s]%s[/color]" % [ProgressData.settings.color_positive, str(value)]
	var displayed_key: String = key.substr(0, key.length() - 2)
	var tier: int = key.substr(key.length() - 1, 1).to_int() - 1
	var tier_number: String = ItemService.get_tier_number(tier)
	var weapon_name: String = "[color=#%s]%s %s[/color]" % [ItemService.get_color_from_tier(tier).to_html(),
														   tr(displayed_key.to_upper()),
														   tier_number]

	return [str_value, weapon_name]
