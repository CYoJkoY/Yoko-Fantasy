extends "res://singletons/run_data.gd"

# =========================== Extension =========================== #
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
