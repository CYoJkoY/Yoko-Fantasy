extends Reference

static func get_classes() -> Array:
    return [
        # Services
        {
            "base": "Node",
            "class": "UpgradeHooks",
            "language": "GDScript",
            "path": "res://mods-unpacked/Yoko-Fantasy/extensions/services/upgrade_hooks.gd"
        },
        {
            "base": "Reference",
            "class": "LightningChainService",
            "language": "GDScript",
            "path": "res://mods-unpacked/Yoko-Fantasy/extensions/services/lightning_chain_service.gd",
        },
        {
            "base": "Reference",
            "class": "LightningChainDescriptionService",
            "language": "GDScript",
            "path": "res://mods-unpacked/Yoko-Fantasy/extensions/services/lightning_chain_description_service.gd"
        },
        {
            "base": "Reference",
            "class": "ChainTargetService",
            "language": "GDScript",
            "path": "res://mods-unpacked/Yoko-Fantasy/extensions/services/chain_target_service.gd"
        },
        {
            "base": "Reference",
            "class": "VisualPartsSync",
            "language": "GDScript",
            "path": "res://mods-unpacked/Yoko-Fantasy/extensions/services/visual_parts_sync.gd"
        },
        {
            "base": "Reference",
            "class": "EnemySpeedModifierService",
            "language": "GDScript",
            "path": "res://mods-unpacked/Yoko-Fantasy/extensions/services/enemy_speed_modifier_service.gd"
        },

        # Enemies
        {
            "base": "Enemy",
            "class": "LittleSlime",
            "language": "GDScript",
            "path": "res://mods-unpacked/Yoko-Fantasy/content/entities/enemies/little_slime/little_slime.gd"
        },
        {
            "base": "LittleSlime",
            "class": "MediumSlime",
            "language": "GDScript",
            "path": "res://mods-unpacked/Yoko-Fantasy/content/entities/enemies/medium_slime/medium_slime.gd"
        },

    ]
