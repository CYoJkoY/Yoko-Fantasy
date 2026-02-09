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
            Utils.fantasy_time_bouns_current_health_damage_hash: [],
            Utils.fantasy_shop_enter_stat_curse_hash: [],
            Utils.fantasy_damage_clamp_hash: [],
            Utils.fantasy_damage_reflect_hash: [],
            Utils.fantasy_curse_all_on_reroll_hash: [],
            Utils.fantasy_extra_curse_enemy_hash: [],
            Utils.fantasy_crit_overflow_hash: [],
            Utils.fantasy_random_reload_when_pickup_gold_hash: [],
        }
        
        new_effects.merge(mod_stats)
        new_effects.merge(vanilla_effects)

        return new_effects;
    else:
        return {}
