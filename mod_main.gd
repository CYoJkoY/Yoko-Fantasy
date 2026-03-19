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
        # Job System[ 1/6 ]
        # EFFECTS: gain_stat_for_every_stat[ living_cursed_enemy ],
        #          decaying_slow_enemy_when_below_hp[ 1/2 ]
        #          slow_cursed_enemy
        
        "item_service.gd",
        # Job System[ 2/6 ]
        # STATS: Soul[ 1/3 ], Holy[ 1/2 ]
        
        "enemy.gd",
        # STATS: Holy[ 2/2 ]
        # EFFECTS: extra_curse_enemy
        
        "player_run_data.gd",
        # Job System[ 3/6 ]
        # EFFECTS' NAMES
        
        "utils.gd",
        # Hashes

        "base_shop.gd",
        # EFFECTS: shop_enter_stat_curse[ 1/2 ],
        #          curse_all_on_reroll,
        #          upgrade_specific_tier_weapons[ 1/2 ]

        "player.gd",
        # STATS: Soul[ 2/3 ]
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
        # Job System[ 4/6 ]
        # STATS: Soul[ 3/3 ]
        # EFFECTS: specific_set_weapon_effects,
        #          shop_enter_stat_curse[ 2/2 ],
        #          upgrade_specific_tier_weapons[ 2/2 ]

        "turret.gd",
        # EFFECTS: turret_can_pursue_target

        "ingame_main_menu.gd",
        # Job System[ 5/6 ]

        "end_run.gd",
        # Job System[ 6/6 ]
    
        "wave_manager.gd",
        # EFFECTS: extra_enemies_next_waves

    ]

    for path in extensions:
        var extension_path = ext_dir + path
        ModLoaderMod.install_script_extension(extension_path)
