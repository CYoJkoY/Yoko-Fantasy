extends "res://singletons/progress_data.gd"

# =========================== Extension =========================== #
func _ready() -> void:
    _fantasy_ready()

# =========================== Custom =========================== #
func _fantasy_ready() -> void:
    var fantasy_data = load("res://mods-unpacked/Yoko-Fantasy/content_data/Fantasy_content_New.tres")
    fantasy_data.add_resources()

    RunData.reset()

    load_game_file()
    add_unlocked_by_default()

    set_max_selectable_difficulty()
