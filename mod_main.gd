extends Node

const MYMODNAME_MOD_DIR: String = "Yoko-Fantasy/"
const MYMODNAME_LOG: String = "Yoko-Fantasy"

var dir: String = ""
var ext_dir: String = ""
var trans_dir: String = ""

# =========================== Extension =========================== #
func _init() -> void:
    dir = ModLoaderMod.get_unpacked_dir() + MYMODNAME_MOD_DIR
    trans_dir = dir + "translations/"
    ext_dir = dir + "extensions/"
    
    ModLoaderMod.add_translation(trans_dir + "Fantasy.en.translation")
    ModLoaderMod.add_translation(trans_dir + "Fantasy.zh.translation")

    var extensions: Array = [

        "main.gd",
        # STATS: Holy, Soul
        # EFFECTS: gain_stat_for_every_stat[ living_cursed_enemy ][ 1/2 ], decaying_slow_enemy_when_below_hp[ 1/2 ]
        
        "item_service.gd",
        # STATS: Soul
        
        "enemy.gd",
        # STATS: Holy
        # EFFECTS: extra_curse_enemy
        
        "player_run_data.gd",
        # EFFECTS' NAMES
        
        "utils.gd",
        # EFFECTS' NAMES

        "base_shop.gd",
        # EFFECTS: shop_enter_stat_curse, curse_all_on_reroll

        "player.gd",
        # EFFECTS: damage_clamp, damage_reflect, decaying_slow_enemy_when_below_hp[ 2/2 ]

        "weapon_service.gd",
        # EFFECTS: crit_overflow

        "wave_manager.gd",
        # EFFECTS: extra_elites_next_wave

        "entity_spawner.gd",
        # EFFECTS: gain_temp_stat_every_killed_enemies[ 1/3 ]

        "melee_weapon.gd",
        # EFFECTS: gain_temp_stat_every_killed_enemies[ 2/3 ]

        "ranged_weapon.gd",
        # EFFECTS: gain_temp_stat_every_killed_enemies[ 3/3 ]
        
    ]

    for path in extensions:
        var extension_path = ext_dir + path
        ModLoaderMod.install_script_extension(extension_path)
