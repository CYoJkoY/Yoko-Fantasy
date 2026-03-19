extends "res://singletons/utils.gd"

# Jobs
var job_fantasy_elemental_hash: int = Keys.generate_hash("job_fantasy_elemental")
var job_fantasy_engineering_hash: int = Keys.generate_hash("job_fantasy_engineering")
var job_fantasy_melee_hash: int = Keys.generate_hash("job_fantasy_melee")
var job_fantasy_ranged_hash: int = Keys.generate_hash("job_fantasy_ranged")
var job_fantasy_universal_hash: int = Keys.generate_hash("job_fantasy_universal")
var icon_job_to_process_hash: int = Keys.generate_hash("icon_job_to_process")

# Stats
var stat_fantasy_holy_hash: int = Keys.generate_hash("stat_fantasy_holy")
var stat_fantasy_soul_hash: int = Keys.generate_hash("stat_fantasy_soul")
var stat_fantasy_decaying_slow_enemy_hash: int = Keys.generate_hash("stat_fantasy_decaying_slow_enemy")
var stat_fantasy_crit_damage_hash: int = Keys.generate_hash("stat_fantasy_crit_damage")
var gain_stat_fantasy_crit_damage_hash: int = Keys.generate_hash("gain_stat_fantasy_crit_damage")

# Effects
var fantasy_original_speed_hash: int = Keys.generate_hash("fantasy_original_speed")
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

# Consumables
var consumable_fantasy_soul_hash: int = Keys.generate_hash("consumable_fantasy_soul")
