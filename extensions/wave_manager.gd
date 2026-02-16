extends "res://zones/wave_manager.gd"

# =========================== Extension =========================== #
func init(p_wave_timer: Timer, zone_data: ZoneData, wave_data: Resource) -> void:
    .init(p_wave_timer, zone_data, wave_data)
    _fantasy_extra_elite_next_wave_init()

# =========================== Custom =========================== #
func _fantasy_extra_elite_next_wave_init() -> void:
    for player_index in RunData.get_player_count():
        var effects: Dictionary = RunData.get_player_effects(player_index)
        var extra_elites_next_wave: int = effects[Utils.fantasy_extra_elites_next_wave_hash]
        for i in extra_elites_next_wave:
            var rand_elite_id = ItemService.get_random_elite_id_hash_from_zone(ZoneService.current_zone.my_id)
            effects[Keys.extra_enemies_next_wave_hash].append(["res://zones/common/elite/group_elite.tres", 1, rand_elite_id])
        effects[Utils.fantasy_extra_elites_next_wave_hash] = 0
