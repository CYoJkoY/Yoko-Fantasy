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
        var id: String = new_effect.get_id()
        var key: int = new_effect.key_hash
        var cskey: int = new_effect.custom_key_hash

        match [id, key, cskey]:
            ["fantasy_shop_enter_stat_curse", _, _]:
                new_effect.value = 0 if new_effect.value == 1 else new_effect.value
                new_effect.chance = Utils.ncl_curse_effect_value(new_effect.chance, effect_modifier, {"setp": 1})

            ["fantasy_wandering_pet", _, _]:
                new_effect.weapon_stats = _boost_weapon_stats_damage(new_effect.weapon_stats, effect_modifier)

            [_, _, Utils.fantasy_damage_clamp_hash]:
                new_effect.value2 = Utils.ncl_curse_effect_value(new_effect.value2, effect_modifier, {"is_negative": true, "step": 1})
            
            [_, _, Utils.fantasy_curse_all_on_reroll_hash]:
                new_effect.text_key += "_CURSED"
                new_item_data.replaced_by = ItemService.get_element(ItemService.items, new_effect.key_hash)
            
            [_, _, Utils.fantasy_extra_curse_enemy_hash]:
                var extra_effect: Effect = Effect.new()
                extra_effect.key = new_effect.key
                extra_effect.key_hash = new_effect.key_hash
                extra_effect.value = new_effect.value
                new_effects.append(extra_effect)

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
