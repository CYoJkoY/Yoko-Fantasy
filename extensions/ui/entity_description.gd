extends "res://ui/menus/shop/entity_description.gd"

const FANTASY_PET_DATA = preload("res://mods-unpacked/Yoko-Fantasy/content/entities/pets/fantasy_pet_data.gd")

# =========================== Extension =========================== #
func set_item(item_data: ItemEntity, player_index: int, item_count := 1) -> void:
    .set_item(item_data, player_index, item_count)
    if !(item_data is FANTASY_PET_DATA) or (silhouette_locked_items and item_data._is_silhouette_in_codex()):
        return

    var description: String = item_data.get_fantasy_behaviour_description()
    _behaviourDesc.text = description
    _behaviourDesc_scrolled.text = description
