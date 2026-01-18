extends "res://singletons/player_run_data.gd"

static func init_effects()->Dictionary:

    if (not Utils == null) :
        var vanilla_effects = .init_effects()

        var new_effects: = {
            
            "fantasy_original_speed": 0.0,
            "fantasy_stat_holy": 110,
            "fantasy_stat_soul": 100,

        }

        new_effects.merge(vanilla_effects)

        return new_effects;
    else:
        return {}
