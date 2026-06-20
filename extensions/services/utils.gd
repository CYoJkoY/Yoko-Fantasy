extends "res://singletons/utils.gd"

# Enemy Stats
const FANTASY_ENEMY_HP: int = 0
const FANTASY_ENEMY_SPEED: int = 1
const FANTASY_ENEMY_DAMAGE: int = 2
const FANTASY_ENEMY_ARMOR: int = 3

# Jobs
var job_fantasy_elemental_hash: int = Keys.generate_hash("job_fantasy_elemental")
var job_fantasy_engineering_hash: int = Keys.generate_hash("job_fantasy_engineering")
var job_fantasy_luck_hash: int = Keys.generate_hash("job_fantasy_luck")
var job_fantasy_melee_hash: int = Keys.generate_hash("job_fantasy_melee")
var job_fantasy_ranged_hash: int = Keys.generate_hash("job_fantasy_ranged")
var job_fantasy_universal_hash: int = Keys.generate_hash("job_fantasy_universal")

func fa_is_damage_job_way(way_hash: int) -> bool:
	return [
		job_fantasy_elemental_hash,
		job_fantasy_engineering_hash,
		job_fantasy_melee_hash,
		job_fantasy_ranged_hash,
	].has(way_hash)

# Stats
var stat_fantasy_holy_hash: int = Keys.generate_hash("stat_fantasy_holy")
var stat_fantasy_soul_hash: int = Keys.generate_hash("stat_fantasy_soul")
var stat_fantasy_decaying_slow_enemy_hash: int = Keys.generate_hash("stat_fantasy_decaying_slow_enemy")
var stat_fantasy_crit_damage_hash: int = Keys.generate_hash("stat_fantasy_crit_damage")
var gain_stat_fantasy_crit_damage_hash: int = Keys.generate_hash("gain_stat_fantasy_crit_damage")
var stat_fantasy_pet_attack_speed_hash: int = Keys.generate_hash("stat_fantasy_pet_attack_speed")

# Effects
var fantasy_soul_bonus_hash: int = Keys.generate_hash("fantasy_soul_bonus")
var fantasy_time_bonus_current_health_damage_hash: int = Keys.generate_hash("fantasy_time_bonus_current_health_damage")
var fantasy_shop_enter_stat_curse_hash: int = Keys.generate_hash("fantasy_shop_enter_stat_curse")
var fantasy_damage_clamp_hash: int = Keys.generate_hash("fantasy_damage_clamp")
var fantasy_damage_reflect_hash: int = Keys.generate_hash("fantasy_damage_reflect")
var fantasy_curse_all_on_reroll_hash: int = Keys.generate_hash("fantasy_curse_all_on_reroll")
var fantasy_extra_curse_enemy_hash: int = Keys.generate_hash("fantasy_extra_curse_enemy")
var fantasy_crit_overflow_hash: int = Keys.generate_hash("fantasy_crit_overflow")
var fantasy_random_reload_when_pickup_gold_hash: int = Keys.generate_hash("fantasy_random_reload_when_pickup_gold")
var fantasy_erosion_hash: int = Keys.generate_hash("fantasy_erosion")
var fantasy_erosion_can_crit_hash: int = Keys.generate_hash("fantasy_erosion_can_crit")
var fantasy_erosion_speed_hash: int = Keys.generate_hash("fantasy_erosion_speed")
var fantasy_extra_elites_next_wave_hash: int = Keys.generate_hash("fantasy_extra_elites_next_wave")
var fantasy_extra_curse_item_hash: int = Keys.generate_hash("fantasy_extra_curse_item")
var fantasy_gain_stat_every_killed_enemies_hash: int = Keys.generate_hash("fantasy_gain_stat_every_killed_enemies")
var fantasy_decaying_slow_enemy_when_below_hp_hash: int = Keys.generate_hash("fantasy_decaying_slow_enemy_when_below_hp")
var fantasy_reload_when_shoot_hash: int = Keys.generate_hash("fantasy_reload_when_shoot")
var fantasy_old_specific_set_weapon_bonuses_hash: int = Keys.generate_hash("fantasy_old_specific_set_weapon_bonuses")
var fantasy_specific_set_weapon_bonuses_hash: int = Keys.generate_hash("fantasy_specific_set_weapon_bonuses")
var fantasy_living_cursed_enemy_hash: int = Keys.generate_hash("fantasy_living_cursed_enemy")
var fantasy_structure_scaling_stats_hash: int = Keys.generate_hash("fantasy_structure_scaling_stats")
var fantasy_turret_can_pursue_target_hash: int = Keys.generate_hash("fantasy_turret_can_pursue_target")
var fantasy_upgrade_specific_tier_weapons_hash: int = Keys.generate_hash("fantasy_upgrade_specific_tier_weapons")
var fantasy_slow_cursed_enemy_hash: int = Keys.generate_hash("fantasy_slow_cursed_enemy")
var fantasy_extra_enemies_next_waves_hash: int = Keys.generate_hash("fantasy_extra_enemies_next_waves")
var fantasy_material_loss_on_hit_hash: int = Keys.generate_hash("fantasy_material_loss_on_hit")
var fantasy_crit_overflow_stat_hash: int = Keys.generate_hash("fantasy_crit_overflow_stat")
var fantasy_limited_item_hash: int = Keys.generate_hash("fantasy_limited_item")
var fantasy_old_limited_item_bonuses_hash: int = Keys.generate_hash("fantasy_old_limited_item_bonuses")
var fantasy_limited_item_bonuses_hash: int = Keys.generate_hash("fantasy_limited_item_bonuses")
var fantasy_dmg_when_pickup_consumable_hash: int = Keys.generate_hash("fantasy_dmg_when_pickup_consumable")
var fantasy_periodic_radius_damage_hash: int = Keys.generate_hash("fantasy_periodic_radius_damage")
var fantasy_base_chance_drop_soul_hash: int = Keys.generate_hash("fantasy_base_chance_drop_soul")
var fantasy_tree_radius_tempstats_hash: int = Keys.generate_hash("fantasy_tree_radius_tempstats")
var fantasy_cannot_damage_tree_hash: int = Keys.generate_hash("fantasy_cannot_damage_tree")
var fantasy_bonus_drop_from_target_hash: int = Keys.generate_hash("fantasy_bonus_drop_from_target")
var fantasy_extra_enemies_each_wave_by_stat_hash: int = Keys.generate_hash("fantasy_extra_enemies_each_wave_by_stat")
var fantasy_on_target_enemy_killed_buff_future_target_enemy_hash: int = Keys.generate_hash("fantasy_on_target_enemy_killed_buff_future_target_enemy")
var fantasy_target_enemy_killed_hash: int = Keys.generate_hash("fantasy_target_enemy_killed")
var fantasy_buff_future_target_enemy_hash: int = Keys.generate_hash("fantasy_buff_future_target_enemy")
var fantasy_scrap_specific_tier_weapons_for_items_hash: int = Keys.generate_hash("fantasy_scrap_specific_tier_weapons_for_items")
var fantasy_cursed_kill_healing_hash: int = Keys.generate_hash("fantasy_cursed_kill_healing")
var fantasy_lose_hp_per_second_min_hp_hash: int = Keys.generate_hash("fantasy_lose_hp_per_second_min_hp")
var fantasy_lose_hp_per_second_stop_threshold_hash: int = Keys.generate_hash("fantasy_lose_hp_per_second_stop_threshold")
var fantasy_sacrificial_circle_hash: int = Keys.generate_hash("fantasy_sacrificial_circle")
var fantasy_clock_tower_area_hash: int = Keys.generate_hash("fantasy_clock_tower_area")
var fantasy_dance_hash: int = Keys.generate_hash("fantasy_dance")
var fantasy_shop_enter_synthesis_hash: int = Keys.generate_hash("fantasy_shop_enter_synthesis")
var fantasy_projectiles_every_x_melee_shoot_hash: int = Keys.generate_hash("fantasy_projectiles_every_x_melee_shoot")
var fantasy_reload_when_critically_hit_hash: int = Keys.generate_hash("reload_when_critically_hit")
var fantasy_synthesis_pity_data_hash: int = Keys.generate_hash("fantasy_synthesis_pity_data")
var fantasy_lightning_chain_on_hit_hash: int = Keys.generate_hash("fantasy_lightning_chain_on_hit")
var fantasy_lightning_chain_on_death_hash: int = Keys.generate_hash("fantasy_lightning_chain_on_death")
var fantasy_add_stat_when_pickup_consumable_hash: int = Keys.generate_hash("fantasy_add_stat_when_pickup_consumable")
var fantasy_lightning_chain_can_crit_hash: int = Keys.generate_hash("fantasy_lightning_chain_can_crit")
var fantasy_stationary_temp_stats_per_interval_hash: int = Keys.generate_hash("fantasy_stationary_temp_stats_per_interval")
var fantasy_stationary_percent_stat_per_interval_hash: int = Keys.generate_hash("fantasy_stationary_percent_stat_per_interval")
var fantasy_cannot_attack_while_stationary_hash: int = Keys.generate_hash("fantasy_cannot_attack_while_stationary")
var fantasy_add_weapon_set_hash: int = Keys.generate_hash("fantasy_add_weapon_set")
var fantasy_gain_item_on_reroll_hash: int = Keys.generate_hash("fantasy_gain_item_on_reroll")
var fantasy_guaranteed_set_weapons_in_shop_hash: int = Keys.generate_hash("fantasy_guaranteed_set_weapons_in_shop")
var fantasy_weapon_hit_proc_hash: int = Keys.generate_hash("fantasy_weapon_hit_proc")

# Clock Tower Guardian runtime state. Kept outside RunData so the area can act
# like a temporary battlefield object instead of changing permanent stats.
var fantasy_clock_tower_players_in_area: Dictionary = {}

func fa_set_clock_tower_player_in_area(player_index: int, in_area: bool) -> void:
	if in_area:
		fantasy_clock_tower_players_in_area[player_index] = true
	else:
		fantasy_clock_tower_players_in_area.erase(player_index)

func fa_is_clock_tower_player_in_area(player_index: int) -> bool:
	return fantasy_clock_tower_players_in_area.has(player_index)

func fa_has_clock_tower_area(player_index: int) -> bool:
	return !RunData.get_player_effect(fantasy_clock_tower_area_hash, player_index).empty()

func fa_get_permanent_stat(stat_hash: int, player_index: int) -> float:
	if player_index < 0 or player_index == RunData.DUMMY_PLAYER_INDEX:
		return 0.0

	return RunData.get_stat(stat_hash, player_index)

func fa_get_clock_tower_area_radius(base_range: int, range_rate: float, player_index: int) -> float:
	var radius: float = base_range
	if range_rate != 0.0 and player_index != -1:
		radius += fa_get_permanent_stat(Keys.stat_range_hash, player_index) * range_rate
	var zone_rect: Rect2 = ZoneService.get_current_zone_rect()
	var map_limit: float = min(zone_rect.size.x, zone_rect.size.y) * 0.75 * 0.5
	if map_limit <= 0.0:
		return radius

	return min(radius, map_limit)

func fa_get_clock_tower_structure_attack_speed_bonus(player_index: int) -> int:
	return 20 + int(fa_get_permanent_stat(stat_fantasy_holy_hash, player_index) * 4)

func fa_get_clock_tower_enemy_speed_percent(player_index: int) -> int:
	return int(max(-70, -20 - int(fa_get_permanent_stat(Keys.stat_engineering_hash, player_index) * 0.5)))

# Consumables
var consumable_fantasy_soul_hash: int = Keys.generate_hash("consumable_fantasy_soul")

# Enemies
var fantasy_great_demon_lord_hash: int = Keys.generate_hash("fantasy_great_demon_lord")
var fantasy_tree_spirit_hash: int = Keys.generate_hash("fantasy_tree_spirit")
var fantasy_vine_stranger_hash: int = Keys.generate_hash("fantasy_vine_stranger")
var fantasy_flower_spirit_hash: int = Keys.generate_hash("fantasy_flower_spirit")
var plant_enemies_ids: Array = [
	fantasy_tree_spirit_hash,
	fantasy_vine_stranger_hash,
	fantasy_flower_spirit_hash,
]

# Characters
var character_fantasy_princess_hash = Keys.generate_hash("character_fantasy_princess")
var character_fantasy_clock_tower_guardian_hash = Keys.generate_hash("character_fantasy_clock_tower_guardian")

func fa_get_job_category_text(job_data: UpgradeData) -> String:
	var category_text: String = "JOB"
	match job_data.upgrade_id_hash:
		job_fantasy_elemental_hash: category_text = "JOB_ELEMENTAL"
		job_fantasy_engineering_hash: category_text = "JOB_ENGINEERING"
		job_fantasy_luck_hash: category_text = "JOB_LUCK"
		job_fantasy_melee_hash: category_text = "JOB_MELEE"
		job_fantasy_ranged_hash: category_text = "JOB_RANGED"
		job_fantasy_universal_hash: category_text = "JOB_UNIVERSAL"

	var stage_text: String = ""
	match job_data.stage:
		0: stage_text = "I"
		1: stage_text = "II"

	return tr(category_text).format([stage_text])

func fa_get_pause_menu_focus_emulator(_player_index: int, root: Node = get_scene_node()) -> FocusEmulator:
	var pause_menu: Node = root.find_node("PauseMenu", true, false)
	if pause_menu == null or !pause_menu.is_visible_in_tree():
		return null

	var focus_emulator: FocusEmulator = pause_menu.get_node_or_null("FocusEmulator") as FocusEmulator
	if focus_emulator == null:
		return null

	return focus_emulator

func fa_get_menu_focus_emulator(player_index: int, root: Node = get_scene_node()) -> FocusEmulator:
	if RunData.is_coop_run:
		var pause_focus_emulator: FocusEmulator = fa_get_pause_menu_focus_emulator(player_index, root)
		if pause_focus_emulator != null:
			return pause_focus_emulator

	return get_focus_emulator(player_index, root)

func fa_focus_menu_control(control: Control, player_index: int, root: Node = get_scene_node()) -> void:
	Utils.focus_player_control(control, player_index, fa_get_menu_focus_emulator(player_index, root))

func fa_get_menu_focused_control(some_control: Control, player_index: int, root: Node = get_scene_node()) -> Control:
	return Utils.get_player_focused_control(some_control, player_index, fa_get_menu_focus_emulator(player_index, root))

# Icons
var icon_fantasy_job_to_process_hash: int = Keys.generate_hash("icon_fantasy_job_to_process")
var icon_fantasy_princess_limited_hash = Keys.generate_hash("icon_fantasy_princess_limited")

# =========================== Synthesis Pity =========================== #
func fa_get_synthesis_pity_id(materials: Array, result_id_hash: int) -> String:
	var material_keys: Array = []
	for material in materials:
		material_keys.append(str(material[0]) + ":" + str(material[1]))
	material_keys.sort()
	var content_key: String = str(material_keys) + "_" + str(result_id_hash)
	return content_key.md5_text()

func fa_get_synthesis_pity_data(player_index: int) -> Dictionary:
	return RunData.players_data[player_index].fantasy_synthesis_pity_data

func fa_get_synthesis_effective_chance(base_chance: float, pity_id: String, pity_chance_step: float, player_index: int) -> float:
	var pity_data: Dictionary = fa_get_synthesis_pity_data(player_index)
	var fail_count: int = pity_data.get(pity_id, 0)
	return min(base_chance / 100.0 + fail_count * pity_chance_step / 100.0, 1.0)

func fa_record_synthesis_fail(pity_id: String, player_index: int) -> void:
	var pity_data: Dictionary = fa_get_synthesis_pity_data(player_index)
	pity_data[pity_id] = pity_data.get(pity_id, 0) + 1

func fa_record_synthesis_success(pity_id: String, player_index: int) -> void:
	var pity_data: Dictionary = fa_get_synthesis_pity_data(player_index)
	pity_data.erase(pity_id)

func fa_get_synthesis_fail_count(pity_id: String, player_index: int) -> int:
	var pity_data: Dictionary = fa_get_synthesis_pity_data(player_index)
	return pity_data.get(pity_id, 0)

func fa_get_synthesis_pity_bonus_chance(pity_id: String, pity_chance_step: float, player_index: int) -> float:
	var pity_data: Dictionary = fa_get_synthesis_pity_data(player_index)
	var fail_count: int = pity_data.get(pity_id, 0)
	return fail_count * pity_chance_step

# =========================== Soul =========================== #
func fa_spawn_soul(num: int, pos: Vector2, spread: int) -> void:
	var main: Main = get_scene_node()
	for _i in range(num):
		var consumable_to_spawn: ConsumableData = ProgressData.get_dlc_data("Yoko-Fantasy").soul_data
		var consumable: Consumable = main.get_node_from_pool(main._consumable_pool_id, main._consumables_container)
		if consumable == null:
			consumable = main.consumable_scene.instance()
			main._consumables_container.call_deferred("add_child", consumable)
			var _error = consumable.connect("picked_up", main, "on_consumable_picked_up")
			yield (consumable, "ready")

		consumable.already_picked_up = false
		consumable.consumable_data = consumable_to_spawn
		consumable.set_texture(consumable_to_spawn.icon)
		var dist = rand_range(50, 100 + spread)
		var push_back_destination = ZoneService.get_rand_pos_in_area(pos, dist, 0)
		consumable.drop(pos, 0, push_back_destination)
		main._consumables.push_back(consumable)
