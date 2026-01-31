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
        # Extensions After DLC

        "main.gd",
        # STATS: Holy, Soul
        
        "item_service.gd",
        # STATS: Soul
        
        "enemy.gd",
        # STATS: Holy
        
        "player_run_data.gd",
        # EFFECTS' NAMES
        
        "utils.gd",
        # EFFECTS' NAMES

        "run_data.gd",
        # Tracked Effects

        "shop.gd",
        # EFFECTS: shop_enter_stat_curse[ 1/2 ]

        "coop_shop.gd",
        # EFFECTS: shop_enter_stat_curse[ 2/2 ]

        "player.gd",
        # EFFECTS: damage_clamp
        
    ]

    for path in extensions:
        var extension_path = ext_dir + path
        ModLoaderMod.install_script_extension(extension_path)
