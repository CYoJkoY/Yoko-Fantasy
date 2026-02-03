extends "res://dlcs/dlc_1/dlc_1_data.gd"

# =========================== Extension =========================== #
func curse_item(item_data: ItemParentData, player_index: int, turn_randomization_off: bool = false, min_modifier: float = 0.0) -> ItemParentData:
    if fa_has_effect_fantasy(item_data.effects):
        return _fantasy_curse_item(item_data, player_index, turn_randomization_off, min_modifier)
    else:
        return.curse_item(item_data, player_index, turn_randomization_off, min_modifier)
    
# =========================== Custom =========================== #
func _fantasy_curse_item(item_data: ItemParentData, _player_index: int, turn_randomization_off: bool = false, min_modifier: float = 0.0) -> ItemParentData:
    if item_data.is_cursed:
        return item_data

    var new_effects := []
    var max_effect_modifier = 0.0
    var curse_effect_modified := false
    var new_item_data = item_data.duplicate()

    if item_data is WeaponData:
        var effect_modifier := _get_cursed_item_effect_modifier(turn_randomization_off, min_modifier)
        max_effect_modifier = max(max_effect_modifier, effect_modifier)
        new_item_data.stats = _boost_weapon_stats_damage(item_data.stats, effect_modifier)

    for effect in item_data.effects:
        var effect_modifier := _get_cursed_item_effect_modifier(turn_randomization_off, min_modifier)
        max_effect_modifier = max(max_effect_modifier, effect_modifier)

        var new_effect = effect.duplicate()

        match new_effect.get_id():
            "fantasy_time_bouns_current_health_damage":
                new_effect.value = Utils.ncl_curse_effect_value(new_effect.value, effect_modifier, {"is_negative": true})

            "fantasy_shop_enter_stat_curse":
                new_effect.value = Utils.ncl_curse_effect_value(new_effect.value, effect_modifier, {"is_negative": true})
                new_effect.chance = Utils.ncl_curse_effect_value(new_effect.value, effect_modifier)

            _: new_effect = fa_process_other_effect(new_effect, effect_modifier)

        new_effects.append(new_effect)

    if !curse_effect_modified:
        var curse_effect = Effect.new()
        curse_effect.key = "stat_curse"
        curse_effect.value = round(max(1.0, curse_per_item_value * item_data.value * (1.0 + max_effect_modifier))) as int
        curse_effect.effect_sign = Sign.OVERRIDE
        new_effects.append(curse_effect)

    new_item_data.effects = new_effects
    new_item_data.is_cursed = true

    new_item_data.curse_factor = max_effect_modifier

    return new_item_data as ItemParentData

func fa_process_other_effect(effect: Resource, modifier: float) -> Resource:
    match effect.custom_key:
        "fantasy_damage_clamp":
            effect.value2 = Utils.ncl_curse_effect_value(effect.value2, modifier, {"is_negative": true})

    effect.value = Utils.ncl_curse_effect_value(effect.value, modifier, {"process_negative": false})
    return effect

# =========================== Method =========================== #
func fa_has_effect_fantasy(effects: Array) -> bool:
    for effect in effects:
        if effect.get_id().begins_with("fantasy") or \
        effect.key.begins_with("fantasy") or \
        effect.custom_key.begins_with("fantasy"):
            return true
    return false
