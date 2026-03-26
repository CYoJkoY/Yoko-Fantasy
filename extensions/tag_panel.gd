extends "res://ui/menus/shop/tag_panel.gd"

# =========================== Extension =========================== #
func set_data(tag: String) -> bool:
    var tag_bool: bool =.set_data(tag)
    tag_bool = _fantasy_set_data(tag, tag_bool)

    return tag_bool

# =========================== Custom =========================== #
func _fantasy_set_data(tag: String, tag_bool: bool) -> bool:
    if tag_bool: return true

    match tag:
        "job":
            _tag_name.text = tr("JOB")
            _tag_effects.bbcode_text = tr("TAG_DESCRIPTION_JOB")
        _: return false

    if RunData.is_coop_run:
        if _tag_effects.text.length() >= 300:
            _tag_effects.add_font_override("normal_font", small_font)
        else:
            _tag_effects.add_font_override("normal_font", normal_font)

    show()
    return true
