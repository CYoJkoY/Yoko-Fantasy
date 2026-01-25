extends "res://singletons/player_run_data.gd"

static func init_stats(all_null_values: bool = false)->Dictionary:

    if (Utils != null) :
        var vanilla_stats = .init_stats(all_null_values)

        var new_stats: = {
            
            Utils.fantasy_stat_holy_hash: 0,
            Utils.fantasy_stat_soul_hash: 0,
            
        }

        new_stats.merge(vanilla_stats)

        return new_stats;
    else:
        return {}

static func init_effects()->Dictionary:

    if (Utils != null) :
        var mod_stats = init_stats()
        var vanilla_effects = .init_effects()

        var new_effects: = {
            
            Utils.fantasy_original_speed_hash: 0.0,

        }
        
        new_effects.merge(mod_stats)
        new_effects.merge(vanilla_effects)

        return new_effects;
    else:
        return {}
