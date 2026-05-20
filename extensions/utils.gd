extends "res://singletons/utils.gd"

# Enemy Stats
const FANTASY_ENEMY_HP: int = 0
const FANTASY_ENEMY_SPEED: int = 1
const FANTASY_ENEMY_DAMAGE: int = 2
const FANTASY_ENEMY_ARMOR: int = 3

# Synthesis Pity Config
const FANTASY_SYNTHESIS_BASE_GROWTH: float = 0.01
const FANTASY_SYNTHESIS_CAP: float = 0.318 # 68.2% ** 6 ≈ 10%
const FANTASY_SYNTHESIS_MATERIAL_WEIGHT: float = 0.07
const FANTASY_SYNTHESIS_RESULT_TIER_WEIGHT: float = 0.05

# Jobs
var job_fantasy_elemental_hash: int = Keys.generate_hash("job_fantasy_elemental")
var job_fantasy_engineering_hash: int = Keys.generate_hash("job_fantasy_engineering")
var job_fantasy_melee_hash: int = Keys.generate_hash("job_fantasy_melee")
var job_fantasy_ranged_hash: int = Keys.generate_hash("job_fantasy_ranged")
var job_fantasy_universal_hash: int = Keys.generate_hash("job_fantasy_universal")

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
var fantasy_sacrificial_circle_hash: int = Keys.generate_hash("fantasy_sacrificial_circle")
var fantasy_dance_hash: int = Keys.generate_hash("fantasy_dance")
var fantasy_shop_enter_synthesis_hash: int = Keys.generate_hash("fantasy_shop_enter_synthesis")
var fantasy_projectiles_every_x_melee_shoot_hash: int = Keys.generate_hash("fantasy_projectiles_every_x_melee_shoot")
var fantasy_reload_when_critically_hit_hash: int = Keys.generate_hash("fantasy_reload_when_critically_hit")
var fantasy_synthesis_pity_data_hash: int = Keys.generate_hash("fantasy_synthesis_pity_data")
var fantasy_lightning_chain_on_hit_hash: int = Keys.generate_hash("fantasy_lightning_chain_on_hit")
var fantasy_add_stat_when_pickup_consumable_hash: int = Keys.generate_hash("fantasy_add_stat_when_pickup_consumable")

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

# Icons
var icon_fantasy_job_to_process_hash: int = Keys.generate_hash("icon_fantasy_job_to_process")
var icon_fantasy_princess_limited_hash = Keys.generate_hash("icon_fantasy_princess_limited")

# =========================== Synthesis Pity =========================== #
func fa_get_synthesis_pity_id(materials: Array, result_id_hash: int) -> String:
    var material_ids: Array = []
    for m in materials: material_ids.append(m[0])
    material_ids.sort()
    var content_key: String = str(material_ids) + "_" + str(result_id_hash)
    return content_key.md5_text()

func fa_get_synthesis_pity_data(player_index: int) -> Dictionary:
    return RunData.players_data[player_index].fantasy_synthesis_pity_data

func fa_calc_synthesis_pity(base_chance: float, materials: Array, result_id_hash: int) -> Dictionary:
    var norm_chance: float = max(base_chance / 100.0, 0.01)
    
    var total_tier: int = 0
    var material_count: int = 0
    for material in materials:
        var material_id: int = material[0]
        var tier: int = 0
        if ItemService.is_item_id(material_id): tier = ItemService.get_item_from_id(material_id).tier
        else: tier = ItemService.ncl_get_weapon_from_id(material_id).tier
        total_tier += tier
        material_count += 1
    var avg_tier: float = float(total_tier) / max(material_count, 1)
    var material_bonus: float = (avg_tier / 4.0) * FANTASY_SYNTHESIS_MATERIAL_WEIGHT

    var result_tier: int = 0
    if ItemService.is_item_id(result_id_hash): result_tier = ItemService.get_item_from_id(result_id_hash).tier
    else: result_tier = ItemService.ncl_get_weapon_from_id(result_id_hash).tier
    var result_bonus: float = (float(result_tier) / 4.0) * FANTASY_SYNTHESIS_RESULT_TIER_WEIGHT
    
    var growth_rate: float = FANTASY_SYNTHESIS_BASE_GROWTH / norm_chance + material_bonus + result_bonus
    var max_multiplier: float = FANTASY_SYNTHESIS_CAP / norm_chance

    return {"growth_rate": growth_rate, "max_multiplier": max_multiplier}

func fa_get_synthesis_effective_chance(base_chance: float, pity_id: String, materials: Array, result_id_hash: int, player_index: int) -> float:
    var pity_data: Dictionary = fa_get_synthesis_pity_data(player_index)
    var fail_count: int = pity_data.get(pity_id, 0)
    if fail_count == 0: return base_chance / 100.0

    var calc: Dictionary = fa_calc_synthesis_pity(base_chance, materials, result_id_hash)
    var multiplier: float = min(1.0 + fail_count * calc.growth_rate, calc.max_multiplier)
    var effective: float = min((base_chance / 100.0) * multiplier, FANTASY_SYNTHESIS_CAP)
    return effective

func fa_record_synthesis_fail(pity_id: String, player_index: int) -> void:
    var pity_data: Dictionary = fa_get_synthesis_pity_data(player_index)
    pity_data[pity_id] = pity_data.get(pity_id, 0) + 1

func fa_record_synthesis_success(pity_id: String, player_index: int) -> void:
    var pity_data: Dictionary = fa_get_synthesis_pity_data(player_index)
    pity_data.erase(pity_id)

func fa_get_synthesis_fail_count(pity_id: String, player_index: int) -> int:
    var pity_data: Dictionary = fa_get_synthesis_pity_data(player_index)
    return pity_data.get(pity_id, 0)

func fa_get_synthesis_pity_multiplier(base_chance: float, pity_id: String, materials: Array, result_id_hash: int, player_index: int) -> float:
    var pity_data: Dictionary = fa_get_synthesis_pity_data(player_index)
    var fail_count: int = pity_data.get(pity_id, 0)
    if fail_count == 0: return 1.0

    var calc: Dictionary = fa_calc_synthesis_pity(base_chance, materials, result_id_hash)
    return min(1.0 + fail_count * calc.growth_rate, calc.max_multiplier)

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
