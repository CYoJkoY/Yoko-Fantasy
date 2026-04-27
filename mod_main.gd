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
    
    # Add translations
    ModLoaderMod.add_translation(trans_dir + "Fantasy.en.translation")
    ModLoaderMod.add_translation(trans_dir + "Fantasy.zh.translation")

    # Add extensions
    var extensions: Array = [

        "main.gd",
        # Job System[ 1/6 ]
        # STATS: Soul[ 1/3 ]
        # ENEMIES: World Tree
        # EFFECTS: gain_stat_for_every_stat[ living_cursed_enemy ]
        #          decaying_slow_enemy_when_below_hp[ 1/2 ]
        #          slow_cursed_enemy,
        #          time_bonus_current_health_damage
        #          random_reload_when_picked_up_gold
    
        "item_service.gd",
        # Job System[ 2/6 ]
        # STATS: Holy[ 1/2 ]
        # EFFECTS: gain_stat_for_limited_item[]

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
        #          material_loss_on_hit
        #          dmg_when_pickup_consumable

        "weapon_service.gd",
        # STATS: Crit Damage, %Pet Attack Speed
        # EFFECTS: crit_overflow
        #          structure_scaling_stats

        "wave_manager.gd",
        # EFFECTS: extra_elites_next_wave

        "entity_spawner.gd",
        # ENEMIES: Plant Enemies[ 1/3 ]
        #          Enemies with detect ability
        # EFFECTS: gain_stat_every_killed_enemies[ 1/3 ]

        "melee_weapon.gd",
        # EFFECTS: gain_stat_every_killed_enemies[ 2/3 ]
        #          reload_when_shoot[ 1/2 ]
        #          change_weapon_every_killed_enemies
        #          cannot_damage_tree[ 1/4 ]

        "ranged_weapon.gd",
        # EFFECTS: gain_stat_every_killed_enemies[ 3/3 ]
        #          reload_when_shoot[ 2/2 ]
        #          cannot_damage_tree[ 2/4 ]

        "run_data.gd",
        # Job System[ 4/6 ]
        # STATS: Soul[ 3/3 ]
        # EFFECTS: specific_set_weapon_bonuses
        #          shop_enter_stat_curse[ 2/2 ]
        #          upgrade_specific_tier_weapons[ 2/2 ]
        #          limited_item_bonuses

        "turret.gd",
        # EFFECTS: turret_can_pursue_target[ 1/3 ]

        "garden.gd",
        # EFFECTS: turret_can_pursue_target[ 2/3 ]

        "wandering_bot.gd",
        # EFFECTS: turret_can_pursue_target[ 3/3 ]

        "ingame_main_menu.gd",
        # Job System[ 5/6 ]

        "end_run.gd",
        # Job System[ 6/6 ]

        "linked_stats.gd",
        # EFFECTS: crit_overflow_stat

        "neutral.gd",
        # EFFECTS: cannot_damage_tree[ 3/4 ]

        "lootworm_target_behavior.gd",
        # ENEMIES: Plant Enemies[ 2/3 ]
        # EFFECTS: cannot_damage_tree[ 4/4 ]

        "lootworm.gd",
        # ENEMIES: Plant Enemies[ 3/3 ]

    ]

    for path in extensions:
        var extension_path = ext_dir + path
        ModLoaderMod.install_script_extension(extension_path)
