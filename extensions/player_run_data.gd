extends "res://singletons/player_run_data.gd"

var jobs: Dictionary = {}

# =========================== Extension =========================== #
func duplicate(): # Avoid class problem
    var copy =.duplicate()
    copy.jobs = jobs.duplicate()

    return copy

func serialize() -> Dictionary:
    var serialized: Dictionary =.serialize()

    var serialized_jobs: Dictionary = {}
    for job_stage in jobs: serialized_jobs[job_stage] = jobs[job_stage].serialize()

    serialized.jobs = serialized_jobs

    return serialized

func deserialize(data: Dictionary) -> PlayerRunData:
    .deserialize(data)

    for job_stage in data.jobs:
        var job_data: Resource = ItemService.get_element_safe(ItemService.upgrades, job_stage)

        if job_data != null:
            job_data = job_data.duplicate()
            job_data.deserialize_and_merge(data.jobs[job_stage])
            jobs[job_stage] = job_data

    return self

static func init_stats(all_null_values: bool = false) -> Dictionary:
    if (Utils != null):
        var vanilla_stats =.init_stats(all_null_values)

        var new_stats := {
            
            Utils.stat_fantasy_holy_hash: 0,
            Utils.stat_fantasy_soul_hash: 0,
            Utils.stat_fantasy_decaying_slow_enemy_hash: 0,
            Utils.stat_fantasy_crit_damage_hash: 0,
            Utils.gain_stat_fantasy_crit_damage_hash: 0,
            Utils.stat_fantasy_pet_attack_speed_hash: 0,

        }

        new_stats.merge(vanilla_stats)

        return new_stats;
    else:
        return {}

static func init_effects() -> Dictionary:
    if (Utils != null):
        var mod_stats = init_stats()
        var vanilla_effects =.init_effects()

        var new_effects := {

            Utils.fantasy_time_bonus_current_health_damage_hash: [],
            Utils.fantasy_shop_enter_stat_curse_hash: [],
            Utils.fantasy_damage_clamp_hash: [],
            Utils.fantasy_damage_reflect_hash: [],
            Utils.fantasy_curse_all_on_reroll_hash: [],
            Utils.fantasy_extra_curse_enemy_hash: [],
            Utils.fantasy_crit_overflow_hash: [],
            Utils.fantasy_random_reload_when_pickup_gold_hash: [],
            Utils.fantasy_erosion_hash: [],
            Utils.fantasy_erosion_can_crit_hash: 0,
            Utils.fantasy_erosion_speed_hash: 0,
            Utils.fantasy_extra_elites_next_wave_hash: 0,
            Utils.fantasy_extra_curse_item_hash: [],
            Utils.fantasy_soul_bonus_hash: 0,
            Utils.fantasy_gain_stat_every_killed_enemies_hash: [],
            Utils.fantasy_decaying_slow_enemy_when_below_hp_hash: [],
            Utils.fantasy_reload_when_shoot_hash: [],
            Utils.fantasy_old_specific_set_weapon_bonuses_hash: {},
            Utils.fantasy_specific_set_weapon_bonuses_hash: [],
            Utils.fantasy_living_cursed_enemy_hash: 0,
            Utils.fantasy_structure_scaling_stats_hash: [],
            Utils.fantasy_turret_can_pursue_target_hash: 0,
            Utils.fantasy_upgrade_specific_tier_weapons_hash: [],
            Utils.fantasy_slow_cursed_enemy_hash: 0,
            Utils.fantasy_extra_enemies_next_waves_hash: [],
            Utils.fantasy_material_loss_on_hit_hash: 0,
            Utils.fantasy_crit_overflow_stat_hash: [],
            Utils.fantasy_limited_item_hash: 0,
            Utils.fantasy_old_limited_item_bonuses_hash: {},
            Utils.fantasy_limited_item_bonuses_hash: [],
            Utils.fantasy_dmg_when_pickup_consumable_hash: [],
            Utils.fantasy_periodic_radius_damage_hash: [],
            Utils.fantays_base_chance_drop_soul_hash: 0,
            Utils.fantasy_tree_radius_tempstats_hash: [],
            Utils.fantasy_cannot_damage_tree_hash: 0,

        }
        
        new_effects.merge(mod_stats)
        new_effects.merge(vanilla_effects)

        return new_effects;
    else:
        return {}
