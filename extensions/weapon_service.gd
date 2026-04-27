extends "res://singletons/weapon_service.gd"

# =========================== Extension =========================== #
func init_base_stats(from_stats: WeaponStats, player_index: int, args: WeaponServiceInitStatsArgs = _init_stats_args_service, is_structure := false, is_special_spawn := false, is_pet := false) -> WeaponStats:
    var base_stats: WeaponStats =.init_base_stats(from_stats, player_index, args, is_structure, is_special_spawn, is_pet)
    base_stats.crit_damage = _fantasy_add_crit_damage(base_stats.crit_damage, player_index)
    base_stats.crit_damage = _fantasy_crit_overflow(base_stats.crit_chance, base_stats.crit_damage, player_index)
    return base_stats

func init_structure_stats(from_stats: RangedWeaponStats, player_index: int, args: WeaponServiceInitStatsArgs = _init_stats_args_service) -> RangedWeaponStats:
    var structure_stats: RangedWeaponStats =.init_structure_stats(from_stats, player_index, args)
    structure_stats.scaling_stats = _fantasy_apply_structure_scaling_stat_effects(structure_stats.scaling_stats, player_index)
    return structure_stats

func init_melee_pet_stats(from_stats: MeleeWeaponStats, player_index: int, args := WeaponServiceInitStatsArgs.new()) -> MeleeWeaponStats:
    var melee_pet_stats: MeleeWeaponStats =.init_melee_pet_stats(from_stats, player_index, args)
    melee_pet_stats.cooldown = apply_attack_speed_mod_to_cooldown(melee_pet_stats.cooldown, Utils.get_stat(Utils.stat_fantasy_pet_attack_speed_hash, player_index) / 100.0)
    return melee_pet_stats

func init_ranged_pet_stats(from_stats: RangedWeaponStats, player_index: int, is_special_spawn := false, args := WeaponServiceInitStatsArgs.new()) -> RangedWeaponStats:
    var ranged_pet_stats: RangedWeaponStats =.init_ranged_pet_stats(from_stats, player_index, is_special_spawn, args)
    ranged_pet_stats.cooldown = apply_attack_speed_mod_to_cooldown(ranged_pet_stats.cooldown, Utils.get_stat(Utils.stat_fantasy_pet_attack_speed_hash, player_index) / 100.0)
    return ranged_pet_stats

func init_structure_pet_stats(from_stats: RangedWeaponStats, player_index: int, args := WeaponServiceInitStatsArgs.new()) -> RangedWeaponStats:
    var structure_pet_stats: RangedWeaponStats =.init_structure_pet_stats(from_stats, player_index, args)
    structure_pet_stats.scaling_stats = _fantasy_apply_structure_scaling_stat_effects(structure_pet_stats.scaling_stats, player_index)
    structure_pet_stats.cooldown = apply_attack_speed_mod_to_cooldown(structure_pet_stats.cooldown, Utils.get_stat(Utils.stat_fantasy_pet_attack_speed_hash, player_index) / 100.0)
    return structure_pet_stats

# =========================== Custom =========================== #
func _fantasy_add_crit_damage(crit_damage: float, player_index: int) -> float:
    crit_damage += Utils.get_stat(Utils.stat_fantasy_crit_damage_hash, player_index) / 100.0
    return crit_damage

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

func _fantasy_apply_structure_scaling_stat_effects(scaling_stats: Array, player_index: int) -> Array:
    var structure_scaling_stat_effects: Array = RunData.get_player_effect(Utils.fantasy_structure_scaling_stats_hash, player_index)
    if structure_scaling_stat_effects.empty(): return scaling_stats

    var new_scaling_stats = scaling_stats.duplicate(true)
    for scaling_stat_effect in structure_scaling_stat_effects:
        assert(scaling_stat_effect[0] is int)
        var scaling_stat_hash = scaling_stat_effect[0]
        var scaling_stat_value = scaling_stat_effect[1] / 100.0
        var existing_scaling_stat = find_scaling_stat(scaling_stat_hash, new_scaling_stats)
        if existing_scaling_stat != null:
            existing_scaling_stat[1] += scaling_stat_value
        else:
            new_scaling_stats.append([scaling_stat_hash, scaling_stat_value])
    return new_scaling_stats
