extends NullEffect

export(int) var projectiles_per_frame = 3
export(Resource) var projectile_stats = null

# =========================== Extension =========================== #
static func get_id() -> String:
    return "fantasy_projectiles_every_x_melee_shoot"

func get_args(player_index: int) -> Array:
    var dmg_text: String = Utils.ncl_get_dmg_text_with_scaling_stats(
        projectile_stats.damage, projectile_stats.scaling_stats,
        {
            "player_index": player_index,
            "nb": projectile_stats.nb_projectiles
        }
    )

    return [str(value), dmg_text]

func serialize() -> Dictionary:
    var serialized =.serialize()
    serialized.projectiles_per_frame = projectiles_per_frame
    serialized.projectile_stats = projectile_stats.resource_path

    return serialized

func deserialize_and_merge(serialized: Dictionary) -> void:
    .deserialize_and_merge(serialized)
    projectiles_per_frame = serialized.projectiles_per_frame as int
    projectile_stats = ResourceLoader.load(serialized.projectile_stats) as RangedWeaponStats
