extends NullDoubleValueEffect


static func get_id() -> String:
	return "weapon_crusader_hammer"


func get_explosion_stats() -> MeleeWeaponStats:
	var explosion_stats = MeleeWeaponStats.new()
	explosion_stats.damage = int(value2)
	explosion_stats.scaling_stats = [[Utils.stat_fantasy_holy_hash, 1.0]]
	return explosion_stats


func get_args(player_index: int) -> Array:
	var explosion_stats = get_explosion_stats()
	var damage: int = WeaponService.get_explosion_damage(explosion_stats, player_index)
	var damage_text: String = "[color=%s]%s[/color]" % [Utils.ncl_get_signed_col(damage, int(value2)), str(damage)]
	if damage != int(value2):
		damage_text += " [color=%s]|%s[/color]" % [Utils.GRAY_COLOR_STR, str(int(value2))]
	damage_text += " (" + WeaponService.get_scaling_stats_icon_text(explosion_stats.scaling_stats) + ")"
	return [str(value), damage_text]
