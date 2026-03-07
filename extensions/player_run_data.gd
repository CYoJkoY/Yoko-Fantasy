extends "res://singletons/player_run_data.gd"

static func init_stats(all_null_values: bool = false) -> Dictionary:
    if (Utils != null):
        var vanilla_stats =.init_stats(all_null_values)

        var new_stats := {
            
            Utils.stat_fantasy_holy_hash: 0,
            Utils.gain_stat_fantasy_holy_hash: 0,
            Utils.stat_fantasy_soul_hash: 0,
            Utils.gain_stat_fantasy_soul_hash: 0,
            Utils.stat_fantasy_living_cursed_enemy_hash: 0,
            Utils.gain_stat_fantasy_living_cursed_enemy_hash: 0,
            Utils.stat_fantasy_decaying_slow_enemy_hash: 0,
            Utils.gain_stat_fantasy_decaying_slow_enemy_hash: 0,
            
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
            
            Utils.fantasy_original_speed_hash: 0.0,
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
            Utils.fantasy_gain_temp_stat_every_killed_enemies_hash: [],
            Utils.fantasy_decaying_slow_enemy_when_below_hp_hash: [],
            Utils.fantasy_job_stage_hash: 0,
            Utils.fantasy_job_pending_tier_hash: 0,
            Utils.fantasy_job_family_hash: 0,
            Utils.fantasy_job_tier1_id_hash: 0,
            Utils.fantasy_job_tier2_id_hash: 0,
            Utils.fantasy_job_blacksmith_tier3_upgrade_hash: 0,
            Utils.fantasy_job_dual_blade_skip_cooldown_chance_hash: 0,
            Utils.fantasy_job_elemental_weapon_count_hash: 0,
            Utils.fantasy_job_gun_weapon_count_hash: 0,
            Utils.fantasy_job_musical_weapon_count_hash: 0,
            Utils.fantasy_job_has_musical_weapon_hash: 0,
            Utils.fantasy_job_total_weapon_count_hash: 0,
            Utils.fantasy_cursed_enemy_speed_percent_hash: 0,
            Utils.fantasy_job_cursed_enemy_base_speed_percent_hash: 0,
            Utils.fantasy_job_thunder_projectile_on_death_hash: 0,
            Utils.fantasy_job_dark_mage_kill_counter_hash: 0,
            Utils.fantasy_job_fire_mage_active_hash: 0,
            Utils.fantasy_job_thunder_mage_active_hash: 0,
            Utils.fantasy_structure_elemental_damage_scale_hash: 0,

        }
        
        new_effects.merge(mod_stats)
        new_effects.merge(vanilla_effects)

        return new_effects;
    else:
        return {}
