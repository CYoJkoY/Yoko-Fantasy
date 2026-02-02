extends "res://singletons/item_service.gd"

# =========================== Extension =========================== #
func get_consumable_to_drop(unit: Unit, item_chance: float) -> ConsumableData:
    var consumable: ConsumableData =.get_consumable_to_drop(unit, item_chance)
    consumable = _fantasy_get_soul_to_drop(consumable)
    
    return consumable

# =========================== Custom =========================== #
func _fantasy_get_soul_to_drop(consumable: ConsumableData) -> ConsumableData:
    for player_index in RunData.get_player_count():
        var stat_holy: float = Utils.get_stat(Utils.stat_fantasy_holy_hash, player_index)
        var chance_drop_soul: float = stat_holy / (stat_holy + 50.0) if stat_holy > 0 else 0.0
        if consumable == null and Utils.get_chance_success(chance_drop_soul):
            consumable = get_element(consumables, Utils.consumable_fantasy_soul_hash)
        elif consumable != null and consumable.my_id_hash == Utils.consumable_fantasy_soul_hash:
            consumable = null
    
    return consumable
