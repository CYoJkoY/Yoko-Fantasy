extends "res://singletons/utils.gd"

# Enemy Stats
const FANTASY_ENEMY_HP: int = 0
const FANTASY_ENEMY_SPEED: int = 1
const FANTASY_ENEMY_DAMAGE: int = 2
const FANTASY_ENEMY_ARMOR: int = 3

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

# =========================== Method =========================== #
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
