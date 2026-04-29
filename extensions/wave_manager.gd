extends "res://zones/wave_manager.gd"

const EXTRA_ENEMIES_GROUP_DATA = preload("res://mods-unpacked/Yoko-Fantasy/extensions/effects/extra_enemies_each_wave_by_stat/extra_enemies_each_wave_by_stat_group.tres")

# =========================== Extension =========================== #
func init(p_wave_timer: Timer, zone_data: ZoneData, wave_data: Resource) -> void:
    _fantasy_extra_elites_next_wave()
    _fantasy_extra_enemies_each_wave_by_stat(wave_data)
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

func _fantasy_extra_enemies_each_wave_by_stat(current_wave_data: Resource) -> void:
    for player_index in range(RunData.get_player_count()):
        var effect_items: Array = RunData.get_player_effect(Utils.fantasy_extra_enemies_each_wave_by_stat_hash, player_index)
        for effect in effect_items:
            var base_count: int = int(effect[0])
            var stat_ratio: float = float(effect[1]) / 100.0
            var enemy_data: Resource = load(effect[2])
            var stat_hsh: int = int(effect[3])

            var scaled_count: float = Utils.get_stat(stat_hsh, player_index)
            var extra_count: int = base_count + int(scaled_count * stat_ratio)
            enemy_data.min_number = extra_count
            enemy_data.max_number = extra_count
            var group_data: Resource = EXTRA_ENEMIES_GROUP_DATA.duplicate(true)
            group_data.wave_units_data.append(enemy_data)

            current_wave_data.groups_data.append(group_data)
