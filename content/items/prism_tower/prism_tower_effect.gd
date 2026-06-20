extends "res://effects/items/turret_effect.gd"

func get_args(player_index: int) -> Array:
	_init_stats_args_turret.effects = effects
	var init_stats = WeaponService.init_structure_stats(stats, player_index, _init_stats_args_turret)
	return [Utils.ncl_get_dmg_text_with_scaling_stats(
		stats.damage,
		init_stats.scaling_stats,
		{
			"player_index": player_index
		}
	)]
