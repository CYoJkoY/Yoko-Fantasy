extends "res://zones/wave_manager.gd"

# =========================== Extension =========================== #
func init(p_wave_timer: Timer, zone_data: ZoneData, wave_data: Resource) -> void:
    .init(p_wave_timer, zone_data, wave_data)
    _fantasy_extra_enemies_next_waves_init(wave_data)

# =========================== Custom =========================== #
func _fantasy_extra_enemies_next_waves_init(current_wave_data: Resource):
    for player_index in RunData.get_player_count():
        var effects: Dictionary = RunData.get_player_effects(player_index)
        var extra_enemies_effects: Array = effects[Utils.fantasy_extra_enemies_next_waves_hash]
        var remaining_effects = []
        for effect in extra_enemies_effects:
            var group_data = load(effect[0])
            var group_count = effect[1]
            var waves_remaining = effect[2]
            var tracking_key_hash = effect[3]

            for _i in group_count:
                var new_group = group_data
                if group_data.is_boss: new_group = init_elite_group([effect[2]])
                current_wave_data.groups_data.append(new_group)

            waves_remaining -= 1
            if waves_remaining <= 0:
                RunData.ncl_set_effect_tracking_value(tracking_key_hash, 0, player_index)
                continue

            remaining_effects.append([effect[0], group_count, waves_remaining, tracking_key_hash])
            RunData.ncl_set_effect_tracking_value(tracking_key_hash, waves_remaining, player_index)
        
        effects[Utils.fantasy_extra_enemies_next_waves_hash] = remaining_effects
