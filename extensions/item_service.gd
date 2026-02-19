extends "res://singletons/item_service.gd"

# =========================== Extension =========================== #
func get_consumable_to_drop(unit: Unit, item_chance: float) -> ConsumableData:
    var consumable: ConsumableData =.get_consumable_to_drop(unit, item_chance)
    consumable = _fantasy_get_soul_to_drop(consumable)
    
    return consumable

func apply_item_effect_modifications(item: ItemParentData, player_index: int) -> ItemParentData:
    var new_item: ItemParentData =.apply_item_effect_modifications(item, player_index)
    new_item = _fantasy_extra_curse_item(item, player_index)

    return new_item

# =========================== Custom =========================== #
func _fantasy_get_soul_to_drop(consumable: ConsumableData) -> ConsumableData:
    var stat_holy: float = Utils.average_all_player_stats(Utils.stat_fantasy_holy_hash)
    var chance_drop_soul: float = 0.01
    var chance_drop_soul_bonus: float = stat_holy / (stat_holy + 50.0) if stat_holy > 0 else -1.0
    if consumable == null and Utils.get_chance_success(chance_drop_soul * (1.0 + chance_drop_soul_bonus)):
        consumable = get_element(consumables, Utils.consumable_fantasy_soul_hash)
    elif consumable != null and consumable.my_id_hash == Utils.consumable_fantasy_soul_hash:
        consumable = null
    
    return consumable

func _fantasy_extra_curse_item(item: ItemParentData, player_index: int) -> ItemParentData:
    if item.is_cursed: return item

    var effect_items: Array = RunData.get_player_effect(Utils.fantasy_extra_curse_item_hash, player_index)
    for effect in effect_items:
        if !Utils.get_chance_success(effect[1] / 100.0): continue

        RunData.add_tracked_value(player_index, effect[0], 1)
        return Utils.ncl_curse_item(item, player_index)

    return item
