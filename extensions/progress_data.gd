extends "res://singletons/progress_data.gd"

var fa_dir: String = ModLoaderMod.get_unpacked_dir() + "Yoko-Fantasy/"

# =========================== Extension =========================== #
func load_dlc_pcks() -> void:
    .load_dlc_pcks()
    fa_install_extensions()

# =========================== Custom =========================== #
func fa_install_extensions() -> void:
    var extensions: Array = [
        
        "dlc_1_data.gd",
        # Curse My Effects

    ]
    
    for path in extensions:
        ModLoaderMod.install_script_extension(fa_dir + "extensions/" + path)
