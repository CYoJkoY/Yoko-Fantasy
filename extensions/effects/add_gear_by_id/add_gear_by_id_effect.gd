extends Effect

static func get_id() -> String:
    return "fantasy_add_gear_by_id"

func apply(player_index: int) -> void:
    if key_hash == Keys.empty_hash or value <= 0: return

    Utils.ncl_add_gear_by_id(key_hash, player_index, value)

func unapply(player_index: int) -> void:
    if key_hash == Keys.empty_hash or value <= 0: return

    Utils.ncl_remove_gear_by_id(key_hash, player_index, value)

func get_args(_player_index: int) -> Array:
    var item_data: ItemData = ItemService.get_item_from_id(key_hash)
    var item_name: String = tr(item_data.name.to_upper()) if item_data != null else key
    return [str(value), item_name]
