extends "res://singletons/item_service.gd"

# =========================== Extension =========================== #
func get_consumable_to_drop(unit: Unit, item_chance: float) -> ConsumableData:
    var consumable: ConsumableData =.get_consumable_to_drop(unit, item_chance)
    consumable = _fantasy_get_soul_to_drop(unit, consumable)
    
    return consumable

# =========================== Custom =========================== #
func _fantasy_get_soul_to_drop(unit: Unit, consumable: ConsumableData) -> ConsumableData:
    var stat_holy: float = Utils.average_all_player_stats(Utils.stat_fantasy_holy_hash)
    var chance_drop_soul: float = unit.stats.base_drop_chance * 5.0
    var chance_drop_soul_bouns: float = stat_holy / (stat_holy + 50.0) if stat_holy > 0 else -1.0
    if consumable == null and Utils.get_chance_success(chance_drop_soul * (1.0 + chance_drop_soul_bouns)):
        consumable = get_element(consumables, Utils.consumable_fantasy_soul_hash)
    elif consumable != null and consumable.my_id_hash == Utils.consumable_fantasy_soul_hash:
        consumable = null
    
    return consumable
