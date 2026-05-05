extends "res://mods-unpacked/Yoko-NewContentLoader/NewContent.gd"

const BASE_CHANCE_DROP_SOUL: float = 0.01
const MAX_LUCK_BONUS: float = 2.0

export(Array, Resource) var jobs = []
export(Resource) var soul_data

# =========================== Extension =========================== #
func add_resources() -> void:
    .add_resources()
    add_if_not_null(ItemService.jobs, jobs)

func remove_resources() -> void:
    .remove_resources()
    erase_if_not_null(ItemService.jobs, jobs)

func ncl_update_consumable_to_get(base_consumable_data: ConsumableData) -> ConsumableData:
    if base_consumable_data != null: return base_consumable_data

    var stat_holy: float = Utils.average_all_player_stats(Utils.stat_fantasy_holy_hash)
    var chance_drop_soul: float = BASE_CHANCE_DROP_SOUL + Utils.sum_all_player_stats(Utils.fantasy_base_chance_drop_soul_hash) / 100.0
    var chance_drop_soul_luck_bonus: float = min(MAX_LUCK_BONUS, 1 + Utils.average_all_player_stats(Keys.stat_luck_hash) / 100.0)
    var chance_drop_soul_holy_bonus: float = 1.0 + stat_holy / (stat_holy + 50.0) if stat_holy > 0 else 0.0
    if Utils.get_chance_success(chance_drop_soul * chance_drop_soul_luck_bonus * chance_drop_soul_holy_bonus): return soul_data

    return base_consumable_data
