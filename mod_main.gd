extends Node

const MYMODNAME_MOD_DIR: String = "Yoko-Fantasy/"
const MYMODNAME_LOG: String = "Yoko-Fantasy"

var dir: String = ""
var ext_dir: String = ""
var trans_dir: String = ""

# =========================== Extension =========================== #
func _init() -> void:
    ModLoaderLog.info("========== Add Translation ==========", MYMODNAME_LOG)
    dir = ModLoaderMod.get_unpacked_dir() + MYMODNAME_MOD_DIR
    trans_dir = dir + "translations/"
    ext_dir = dir + "extensions/"
    
    #######################################
    ########## Add translations ##########
    #####################################
    ModLoaderMod.add_translation(trans_dir + "Fantasy.en.translation")
    ModLoaderMod.add_translation(trans_dir + "Fantasy.zh_Hans_CN.translation")

    #####################################
    ########## Add extensions ##########
    ###################################
    var extensions: Array = [

        "progress_data.gd",
        # Mod's Contents
        
        "main.gd",
        # Entry: Display Holy, Display Soul
        
        "item_service.gd",
        # Entry: Soul Drop
        
        "enemy.gd",
        # Entry: Holy Effect
        
        "player_run_data.gd",
        # EFFECTS' NAMES
        
        "keys.gd",
        # EFFECTS' NAMES
        
    ]    

    for path in extensions:
        var extension_path = ext_dir + path
        ModLoaderMod.install_script_extension(extension_path)
