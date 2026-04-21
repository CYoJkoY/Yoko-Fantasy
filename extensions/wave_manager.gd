extends "res://zones/wave_manager.gd"

# =========================== Extension =========================== #
func init(p_wave_timer: Timer, zone_data: ZoneData, wave_data: Resource) -> void:
    _fantasy_extra_elites_next_wave()
    .init(p_wave_timer, zone_data, wave_data)

# =========================== Custom =========================== #
func _fantasy_extra_elites_next_wave():
    for player_index in range(RunData.get_player_count()):
        var effects: Dictionary = RunData.get_player_effects(player_index)
        var number_of_extra_elites: int = effects[Utils.fantasy_extra_elites_next_wave_hash]
        for _i in range(number_of_extra_elites):
            var rand_elite_id = ItemService.get_random_elite_id_hash_from_zone(ZoneService.current_zone.my_id)
            effects[Keys.extra_enemies_next_wave_hash].append(["res://zones/common/elite/group_elite.tres", 1, rand_elite_id])

        effects[Utils.fantasy_extra_elites_next_wave_hash] = 0
