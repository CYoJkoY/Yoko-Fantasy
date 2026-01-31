extends "res://singletons/progress_data.gd"

var fa_dir: String = ModLoaderMod.get_unpacked_dir() + "Yoko-Fantasy/"

# =========================== Extension =========================== #
func _ready() -> void:
    _fantasy_ready()

func load_dlc_pcks() -> void:
    .load_dlc_pcks()
    fa_install_extensions()

# =========================== Custom =========================== #
func _fantasy_ready() -> void:
    load(fa_dir + "content_data/Fantasy_content_New.tres").add_resources()

    RunData.reset()

    load_game_file()
    add_unlocked_by_default()

    set_max_selectable_difficulty()

func fa_install_extensions() -> void:
    var extensions: Array = [
        
        "dlc_1_data.gd",
        # Curse My Effects
        
    ]
    
    for path in extensions:
        ModLoaderMod.install_script_extension(fa_dir + "extensions/" + path)
