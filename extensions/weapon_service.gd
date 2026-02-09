extends "res://singletons/weapon_service.gd"

# =========================== Extension =========================== #
func init_base_stats(from_stats: WeaponStats, player_index: int, args: WeaponServiceInitStatsArgs = _init_stats_args_service, is_structure := false, is_special_spawn := false, is_pet := false) -> WeaponStats:
    var base_stats: WeaponStats =.init_base_stats(from_stats, player_index, args, is_structure, is_special_spawn, is_pet)
    base_stats.crit_damage = _fantasy_crit_overflow(base_stats.crit_chance, base_stats.crit_damage, player_index)

    return base_stats

# =========================== Custom =========================== #
func _fantasy_crit_overflow(crit_chance: float, crit_damage: float, player_index: int) -> float:
    var add_crit_dmg: bool = crit_chance > 1.0
    if !add_crit_dmg: return crit_damage

    var crit_overflows: Array = RunData.get_player_effect(Utils.fantasy_crit_overflow_hash, player_index)
    for crit_overflow in crit_overflows:
        var over: float = crit_chance - 1.0
        var scaling: float = crit_overflow[1] / 100.0
        var plus: float = crit_overflow[0] / 100.0

        crit_damage += over / scaling * plus

    return crit_damage
