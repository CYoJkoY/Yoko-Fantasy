extends "res://zones/wave_manager.gd"

# =========================== Extension =========================== #
func init(p_wave_timer: Timer, zone_data: ZoneData, wave_data: Resource) -> void:
    .init(p_wave_timer, zone_data, wave_data)
    _fantasy_extra_enemies_next_waves(wave_data)
    _fantasy_extra_elites_next_wave()

# =========================== Custom =========================== #
func _fantasy_extra_enemies_next_waves(current_wave_data: Resource):
    for player_index in range(RunData.get_player_count()):
        var effects: Dictionary = RunData.get_player_effects(player_index)
        var extra_enemies_effects: Array = effects[Utils.fantasy_extra_enemies_next_waves_hash]
        var remaining_effects = []
        for effect in extra_enemies_effects:
            var group_data: Resource = load(effect[0])
            var group_count: int = effect[1]
            var waves_remaining: int = effect[2]
            var tracking_key_hash: int = effect[3]

            for _i in range(group_count): current_wave_data.groups_data.append(group_data)

            waves_remaining -= 1
            if waves_remaining <= 0:
                RunData.ncl_set_effect_tracking_value(tracking_key_hash, 0, player_index)
                continue

            remaining_effects.append([effect[0], group_count, waves_remaining, tracking_key_hash])
            RunData.ncl_set_effect_tracking_value(tracking_key_hash, waves_remaining, player_index)
        
        effects[Utils.fantasy_extra_enemies_next_waves_hash] = remaining_effects

func _fantasy_extra_elites_next_wave():
    for player_index in range(RunData.get_player_count()):
        var effects: Dictionary = RunData.get_player_effects(player_index)
        var number_of_extra_elites: int = effects[Utils.fantasy_extra_elites_next_wave_hash]
        for _i in range(number_of_extra_elites):
            var rand_elite_id = ItemService.get_random_elite_id_hash_from_zone(ZoneService.current_zone.my_id)
            effects[Keys.extra_enemies_next_wave_hash].append(["res://zones/common/elite/group_elite.tres", 1, rand_elite_id])

        effects[Utils.fantasy_extra_elites_next_wave_hash] = 0
