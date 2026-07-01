extends Node

const MYMODNAME_MOD_DIR: String = "Yoko-Fantasy/"
const MYMODNAME_LOG: String = "Yoko-Fantasy"

var dir: String = ""
var ext_dir: String = ""
var service_dir: String = ""
var content_dir: String = ""
var entity_dir: String = ""
var enemy_dir: String = ""
var pet_dir: String = ""

# =========================== Extension =========================== #
func _init() -> void:
    dir = ModLoaderMod.get_unpacked_dir() + MYMODNAME_MOD_DIR
    ext_dir = dir + "extensions/"
    service_dir = ext_dir + "services/"
    content_dir = dir + "content/"
    entity_dir = content_dir + "entities/"
    enemy_dir = entity_dir + "enemies/"
    pet_dir = entity_dir + "pets/"

    # Add Classes
    var classes: Array = [
        # Services
        {
            "base": "Node",
            "class": "UpgradeHooks",
            "language": "GDScript",
            "path": service_dir + "upgrade_hooks.gd"
        },
        {
            "base": "Reference",
            "class": "LightningChainService",
            "language": "GDScript",
            "path": service_dir + "lightning_chain_service.gd",
        },
        {
            "base": "Reference",
            "class": "LightningChainDescriptionService",
            "language": "GDScript",
            "path": service_dir + "lightning_chain_description_service.gd"
        },
        {
            "base": "Reference",
            "class": "ChainTargetService",
            "language": "GDScript",
            "path": service_dir + "chain_target_service.gd"
        },
        {
            "base": "Reference",
            "class": "VisualPartsSync",
            "language": "GDScript",
            "path": service_dir + "visual_parts_sync.gd"
        },

        # Enemies
        {
            "base": "Enemy",
            "class": "LittleSlime",
            "language": "GDScript",
            "path": enemy_dir + "little_slime/little_slime.gd"
        },
        {
            "base": "LittleSlime",
            "class": "MediumSlime",
            "language": "GDScript",
            "path": enemy_dir + "medium_slime/medium_slime.gd"
        },

        # Pets
        {
            "base": "Pet",
            "class": "FollowMeleePet",
            "language": "GDScript",
            "path": pet_dir + "follow_melee_pet.gd"
        },
        {
            "base": "Pet",
            "class": "FollowRangedPet",
            "language": "GDScript",
            "path": pet_dir + "follow_ranged_pet.gd"
        },
        {
            "base": "Pet",
            "class": "TacticalGlobalPet",
            "language": "GDScript",
            "path": pet_dir + "tactical_global_pet.gd"
        },
        {
            "base": "Pet",
            "class": "WanderingRangedPet",
            "language": "GDScript",
            "path": pet_dir + "wandering_ranged_pet.gd"
        },

    ]

    var registered_classes: Array = ProjectSettings.get_setting("_global_script_classes")
    var registered_names: Dictionary = {}
    for old_class in registered_classes:
        registered_names[old_class.class ] = true

    var classes_to_register: Array = []
    for new_class in classes:
        if !registered_names.has(new_class.class ):
            classes_to_register.append(new_class)

    if !classes_to_register.empty():
        ModLoaderMod.register_global_classes_from_array(classes_to_register)

    # Add Extensions
    var extensions: Array = [

        "main.gd",
        "singletons/debug_service.gd",
        # SYSTEMS: Job[ 1/6 ]
        # STATS: Soul[ 1/3 ]
        # ENEMIES: World Tree
        #          Slime
        # EFFECTS: gain_stat_for_every_stat[ living_cursed_enemy ]
        #          decaying_slow_enemy_when_below_hp[ 1/2 ]
        #          slow_cursed_enemy,
        #          time_bonus_current_health_damage
        #          random_reload_when_picked_up_gold
    
        "services/item_service.gd",
        # SYSTEMS: Job[ 2/6 ]
        # ITEMS: Erosion Items
        # STATS: Holy[ 1/2 ]
        # EFFECTS: gain_stat_for_limited_item

        "charging_attack_behavior.gd",
        # ENEMIES: stop delayed charge unlock signals after death/cleanup

        "enemy.gd",
        # STATS: Holy[ 2/2 ]
        # EFFECTS: extra_curse_enemy
        #          on_target_enemy_killed_buff_future_target_enemy[ 1/2 ]
        #          cannot_damage_tree[ 1/5 ]

        "player_run_data.gd",
        # SYSTEMS: Job[ 3/6 ]
        # EFFECTS' NAMES

        "services/utils.gd",
        # HASHES

        "music_manager.gd",
        # SYSTEMS: one-shot job theme override

        "base_shop.gd",
        # EFFECTS: shop_enter_stat_curse[ 1/2 ],
        #          curse_all_on_reroll,
        #          upgrade_specific_tier_weapons[ 1/2 ]
        #          scrap_specific_tier_weapons_for_items
        #          shop_enter_synthesis

        "player.gd",
        # STATS: Soul[ 2/3 ]
        # CONSUMABLES: Attract Soul
        # EFFECTS: damage_clamp,
        #          damage_reflect,
        #          decaying_slow_enemy_when_below_hp[ 2/2 ]
        #          material_loss_on_hit
        #          dmg_when_pickup_consumable
        #          add_stat_when_pickup_consumable
        #          lose_hp_per_second_min_hp
        #          lose_hp_per_second_stop_threshold

        "services/weapon_service.gd",
        # STATS: Crit Damage, %Pet Attack Speed
        # EFFECTS: crit_overflow
        #          structure_scaling_stats

        "weapon.gd",
        # EFFECTS: cannot_attack_while_stationary

        "wave_manager.gd",
        # EFFECTS: extra_elites_next_wave
        #          extra_enemies_each_wave_by_stat

        "entity_service.gd",
        # ITEMS: Prism Tower turret ordering

        "entity_spawner.gd",
        # ENEMIES: Plant Enemies[ 1/3 ]
        #          Enemies with detect ability
        # EFFECTS: gain_stat_every_killed_enemies[ 1/3 ]
        #          on_target_enemy_killed_buff_future_target_enemy[ 2/2 ]
        #          cursed_kill_healing

        "melee_weapon.gd",
        # EFFECTS: gain_stat_every_killed_enemies[ 2/3 ]
        #          reload_when_shoot[ 1/2 ]
        #          change_weapon_every_killed_enemies[ 1/2]
        #          cannot_damage_tree[ 2/5 ]
        #          reload_when_critically_hit[ 1/2 ]
        #          lightning_chain_on_hit[ 1/2 ]
        #          weapon_hit_proc[ 1/2 ]

        "ranged_weapon.gd",
        # EFFECTS: gain_stat_every_killed_enemies[ 3/3 ]
        #          reload_when_shoot[ 2/2 ]
        #          change_weapon_every_killed_enemies[ 2/2]
        #          cannot_damage_tree[ 3/5 ]
        #          reload_when_critically_hit[ 2/2 ]
        #          lightning_chain_on_hit[ 2/2 ]
        #          weapon_hit_proc[ 2/2 ]

        "run_data.gd",
        # SYSTEMS: Job[ 4/6 ]
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

        "ui/ingame_main_menu.gd",
        # SYSTEMS: Job[ 5/6 ]

        "ui/menu_confirm.gd",
        "ui/menu_restart.gd",
        "ui/menu_end_run.gd",
        "ui/menu_codex.gd",
        # UI: pause menu coop focus

        "ui/upgrades_ui_player_container.gd",
        # SYSTEMS: Job[ skip job selection ]

        "ui/upgrades_ui.gd",
        # SYSTEMS: Job[ skip job selection ]

        "ui/end_run.gd",
        # SYSTEMS: Job[ 6/6 ]

        "linked_stats.gd",
        # EFFECTS: crit_overflow_stat

        "neutral.gd",
        # EFFECTS: cannot_damage_tree[ 4/5 ]

        "lootworm_target_behavior.gd",
        # ENEMIES: Plant Enemies[ 2/3 ]
        # EFFECTS: cannot_damage_tree[ 5/5 ]

        "lootworm.gd",
        # ENEMIES: Plant Enemies[ 3/3 ]

    ]

    for path in extensions:
        var extension_path: String = ext_dir + path
        ModLoaderMod.install_script_extension(extension_path)
