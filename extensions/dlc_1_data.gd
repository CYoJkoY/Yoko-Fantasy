extends "res://dlcs/dlc_1/dlc_1_data.gd"

# =========================== Extension =========================== #
func curse_item(item_data: ItemParentData, player_index: int, turn_randomization_off: bool = false, min_modifier: float = 0.0) -> ItemParentData:
    if item_data.is_cursed: return item_data
    
    var new_item_data: ItemParentData =.curse_item(item_data, player_index, turn_randomization_off, min_modifier)
    if has_effect_fantasy(item_data.effects):
        new_item_data = _fantasy_curse_item(new_item_data, player_index, turn_randomization_off, min_modifier)
    return new_item_data
    
# =========================== Custom =========================== #
func _fantasy_curse_item(item_data: ItemParentData, _player_index: int, turn_randomization_off: bool = false, min_modifier: float = 0.0) -> ItemParentData:
    var max_effect_modifier: float = 0.0
    var new_item_data: ItemParentData = item_data.duplicate()
    var new_effects: Array = []

    for effect in item_data.effects:
        if !is_effect_fantasy(effect):
            new_effects.append(effect)
            continue

        var effect_modifier: float = _get_cursed_item_effect_modifier(turn_randomization_off, min_modifier)
        max_effect_modifier = max(max_effect_modifier, effect_modifier)

        var new_effect: Effect = effect.duplicate()

        match new_effect.get_id():
            "fantasy_time_bouns_current_health_damage":
                new_effect.value = Utils.ncl_curse_effect_value(new_effect.value, effect_modifier, {"is_negative": true})

            "fantasy_shop_enter_stat_curse":
                new_effect.value = Utils.ncl_curse_effect_value(new_effect.value, effect_modifier, {"is_negative": true})
                new_effect.chance = Utils.ncl_curse_effect_value(new_effect.value, effect_modifier)

            "fantasy_wandering_pet":
                new_effect.weapon_stats = _boost_weapon_stats_damage(new_effect.weapon_stats, effect_modifier)

            _:
                var has_processed: bool = false

                match new_effect.key_hash:
                    Utils.fantasy_damage_reflect_hash:
                        new_effect.value = Utils.ncl_curse_effect_value(new_effect.value, effect_modifier, {"process_negative": false})
                        has_processed = true

                if has_processed: break

                match new_effect.custom_key_hash:
                    Utils.fantasy_damage_clamp_hash:
                        new_effect.value2 = Utils.ncl_curse_effect_value(new_effect.value2, effect_modifier, {"is_negative": true, "step": 1})
                    
                    Utils.fantasy_curse_all_on_reroll_hash:
                        new_effect.text_key += "_CURSED"
                        new_item_data.replaced_by = ItemService.get_element(ItemService.items, new_effect.key_hash)


        new_effects.append(new_effect)
    new_item_data.effects = new_effects

    return new_item_data as ItemParentData

# =========================== Method =========================== #
func has_effect_fantasy(effects: Array) -> bool:
    for effect in effects:
        if is_effect_fantasy(effect):
            return true
    return false

func is_effect_fantasy(effect: Effect) -> bool:
    return effect.get_id().begins_with("fantasy") or \
    effect.key.begins_with("fantasy") or \
    effect.custom_key.begins_with("fantasy")
