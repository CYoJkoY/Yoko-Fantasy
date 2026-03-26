extends "res://ui/menus/shop/tags_container.gd"

# =========================== Extension =========================== #
func set_tags_text(item_data: ItemParentData, player_index: int) -> void:
    .set_tags_text(item_data, player_index)
    _fantasy_set_job_tags_text(item_data)

# =========================== Custom =========================== #
func _fantasy_set_job_tags_text(item_data: ItemParentData) -> void:
    if !(item_data is UpgradeData) or item_data.get("stage") == null: return

    hide()
    var tag_panels_size: int = tag_panels.size()
    tag_panels[tag_panels_size].set_data("job")
    show()
