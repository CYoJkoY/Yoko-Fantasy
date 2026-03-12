extends "res://singletons/run_data.gd"

var fantasy_resumed_from_state_in_shop: bool = false

# =========================== Extension =========================== #
func reset(restart: bool = false) -> void:
    .reset(restart)
    fantasy_resumed_from_state_in_shop = false

func continue_current_run_in_shop() -> void:
    .continue_current_run_in_shop()
    fantasy_resumed_from_state_in_shop = true

func cancel_resume() -> void:
    .cancel_resume()
    fantasy_resumed_from_state_in_shop = false

func update_item_related_effects(player_index: int) -> void:
    _fantasy_update_specific_set_weapon_bonuses(player_index)
    .update_item_related_effects(player_index)

# =========================== Custom =========================== #
func _fantasy_update_specific_set_weapon_bonuses(player_index: int) -> void:
    var effects: Dictionary = get_player_effects(player_index)
    var old_specific_set_weapon_bonuses: Dictionary = effects[Utils.fantasy_old_specific_set_weapon_bonuses_hash]

    for stat_hash in old_specific_set_weapon_bonuses:
        assert(stat_hash is int)
        effects[stat_hash] -= old_specific_set_weapon_bonuses[stat_hash]
    
    old_specific_set_weapon_bonuses.clear()

    var weapons: Array = get_player_weapons_ref(player_index)
    for weapon in weapons: for set in weapon.sets:
        for effect in effects[Utils.fantasy_specific_set_weapon_bonuses_hash]:
            if set.my_id_hash != effect[2]: continue

            old_specific_set_weapon_bonuses[effect[0]] = old_specific_set_weapon_bonuses.get(effect[0], 0) + effect[1]
            effects[effect[0]] += effect[1]

# =========================== Method =========================== #
func fa_add_job(job: UpgradeData, player_index: int) -> void:
    match job.stage:
        0: players_data[player_index].current_s1_job = job
        1: players_data[player_index].current_s2_job = job

    players_data[player_index].jobs.append(job)

func fa_get_current_job(stage: int, player_index: int) -> UpgradeData:
    match stage:
        0: return players_data[player_index].current_s1_job
        1: return players_data[player_index].current_s2_job
    
    return null
