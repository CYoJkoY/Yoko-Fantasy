extends "res://singletons/weapon_service.gd"

# =========================== Extension =========================== #
func init_base_stats(from_stats: WeaponStats, player_index: int, args: WeaponServiceInitStatsArgs = _init_stats_args_service, is_structure := false, is_special_spawn := false, is_pet := false) -> WeaponStats:
	var base_stats: WeaponStats =.init_base_stats(from_stats, player_index, args, is_structure, is_special_spawn, is_pet)
	_fantasy_apply_fire_mage_burning_fallback(base_stats, player_index, is_structure, is_pet)
	base_stats.crit_damage = _fantasy_crit_overflow(base_stats.crit_chance, base_stats.crit_damage, player_index)
	if is_structure:
		base_stats.damage = _fantasy_apply_structure_elemental_damage_bonus(base_stats.damage, player_index)

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


func _fantasy_apply_structure_elemental_damage_bonus(base_damage: int, player_index: int) -> int:
	var player_effects: Dictionary = RunData.get_player_effects(player_index)
	var scale_percent: int = int(player_effects.get(Utils.fantasy_structure_elemental_damage_scale_hash, 0))
	if scale_percent == 0:
		return base_damage

	var elemental_damage: int = Utils.get_stat(Keys.stat_elemental_damage_hash, player_index)
	if elemental_damage == 0:
		return base_damage

	var bonus_base_damage: int = int(round(elemental_damage * scale_percent / 100.0))
	if bonus_base_damage == 0:
		return base_damage

	var structure_percent_multiplier: float = 1.0 + Utils.get_stat(Keys.structure_percent_damage_hash, player_index) / 100.0
	var final_damage: int = base_damage + int(round(bonus_base_damage * structure_percent_multiplier))
	if final_damage < 1:
		final_damage = 1
	return final_damage


func _fantasy_apply_fire_mage_burning_fallback(base_stats: WeaponStats, player_index: int, is_structure: bool, is_pet: bool) -> void:
	var player_effects: Dictionary = RunData.get_player_effects(player_index)
	Utils.fantasy_normalize_effect_keys(player_effects)
	var fire_mage_selected: bool = int(Utils.fantasy_get_effect_value(player_effects, Utils.fantasy_job_fire_mage_active_hash, 0)) > 0 \
		or Utils.fantasy_hash_equals(int(Utils.fantasy_get_effect_value(player_effects, Utils.fantasy_job_tier2_id_hash, 0)), Keys.generate_hash("fire_mage_t2"))
	if !fire_mage_selected:
		return
	if base_stats == null or base_stats.burning_data == null:
		return
	if base_stats.burning_data.chance > 0.0:
		return

	var burning_data_resource: Resource = load("res://items/all/scared_sausage/scared_sausage_burning_data.tres")
	if burning_data_resource == null:
		return

	var burning_data = burning_data_resource.duplicate(true)
	if !(burning_data is BurningData):
		return
	burning_data._late_init()
	burning_data.duration = 5
	burning_data.is_global_burn = true

	var initialized_burning_data: BurningData = init_burning_data(burning_data, player_index, is_structure, is_pet)
	initialized_burning_data.duration = 5
	base_stats.burning_data = initialized_burning_data
