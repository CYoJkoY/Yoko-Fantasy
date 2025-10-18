extends "res://singletons/player_run_data.gd"

static func init_stats(all_null_values: bool = false)->Dictionary:

	if (not Utils == null) :
		var vanilla_stats = .init_stats(all_null_values)

		var new_stats: = {
			
		}

		new_stats.merge(vanilla_stats)

		return new_stats;
	else:
		return {}

static func init_effects()->Dictionary:

	if (not Utils == null) :
		var vanilla_effects = .init_effects()

		var new_effects: = {
			
		}

		new_effects.merge(vanilla_effects)

		return new_effects;
	else:
		return {}
