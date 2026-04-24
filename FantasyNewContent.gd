extends "res://mods-unpacked/Yoko-NewContentLoader/NewContent.gd"

const BASE_CHANCE_DROP_SOUL: float = 0.01

export(Array, Resource) var jobs = []
export(Resource) var soul_data

# =========================== Extension =========================== #
func update_consumable_to_get(base_consumable_data: ConsumableData) -> ConsumableData:
    var stat_holy: float = Utils.average_all_player_stats(Utils.stat_fantasy_holy_hash)
    var base_chance_drop_soul: float = BASE_CHANCE_DROP_SOUL + Utils.average_all_player_stats(Utils.fantays_base_chance_drop_soul_hash) / 100.0
    var chance_drop_soul: float = base_chance_drop_soul + stat_holy * (1 + Utils.average_all_player_stats(Keys.stat_luck_hash) / 100.0)
    var chance_drop_soul_bonus: float = stat_holy / (stat_holy + 50.0) if stat_holy > 0 else -1.0
    if base_consumable_data == null and Utils.get_chance_success(chance_drop_soul * (1.0 + chance_drop_soul_bonus)):
        return soul_data

    return base_consumable_data

func add_resources() -> void:
    .add_resources()
    add_if_not_null(ItemService.jobs, jobs)

func remove_resources() -> void:
    .remove_resources()
    erase_if_not_null(ItemService.jobs, jobs)
