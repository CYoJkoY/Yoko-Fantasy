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
        # Job System[ 1/5 ]
        # STATS: Holy, Soul
        # EFFECTS: gain_stat_for_every_stat[ living_cursed_enemy ],
        #          decaying_slow_enemy_when_below_hp[ 1/2 ]
        #          slow_cursed_enemy
        
        "item_service.gd",
        # Job System[ 2/5 ]
        # STATS: Soul
        
        "enemy.gd",
        # STATS: Holy
        # EFFECTS: extra_curse_enemy
        
        "player_run_data.gd",
        # Job System[ 3/5 ]
        # EFFECTS' NAMES
        
        "utils.gd",
        # Hashes

        "base_shop.gd",
        # EFFECTS: shop_enter_stat_curse[ 1/2 ],
        #          curse_all_on_reroll,
        #          upgrade_specific_tier_weapons[ 1/2 ]

        "player.gd",
        # EFFECTS: damage_clamp,
        #          damage_reflect,
        #          decaying_slow_enemy_when_below_hp[ 2/2 ]

        "weapon_service.gd",
        # STATS: Crit Damage
        # EFFECTS: crit_overflow,
        #          structure_scaling_stats

        "wave_manager.gd",
        # EFFECTS: extra_elites_next_wave

        "entity_spawner.gd",
        # EFFECTS: gain_stat_every_killed_enemies[ 1/3 ]

        "melee_weapon.gd",
        # EFFECTS: gain_stat_every_killed_enemies[ 2/3 ],
        #          reload_when_shoot[ 1/2 ]

        "ranged_weapon.gd",
        # EFFECTS: gain_stat_every_killed_enemies[ 3/3 ],
        #          reload_when_shoot[ 2/2 ]

        "run_data.gd",
        # Job System[ 4/5 ]
        # EFFECTS: specific_set_weapon_effects,
        #          shop_enter_stat_curse[ 2/2 ],
        #          upgrade_specific_tier_weapons[ 2/2 ]

        "turret.gd",
        # EFFECTS: turret_can_pursue_target

        "ingame_main_menu.gd",
        # Job System[ 5/5 ]
    ]

    for path in extensions:
        var extension_path = ext_dir + path
        ModLoaderMod.install_script_extension(extension_path)
