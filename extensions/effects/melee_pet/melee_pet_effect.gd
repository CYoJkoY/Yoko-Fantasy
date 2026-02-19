extends PetEffect

export(Resource) var weapon_stats

# =========================== Extension =========================== #
static func get_id() -> String:
    return "fantasy_melee_pet"

func get_args(player_index: int) -> Array:
    var args: WeaponServiceInitStatsArgs = WeaponServiceInitStatsArgs.new()
    var _current_weapon_stats: MeleeWeaponStats = WeaponService.init_melee_pet_stats(weapon_stats, player_index, args)
    var scaling_stats_text: String = WeaponService.get_scaling_stats_icon_text(_current_weapon_stats.scaling_stats)
    var cooldown_text: String = stepify(_current_weapon_stats.cooldown / 60.0, 0.1) as String

    return [cooldown_text, str(weapon_stats.max_range), str(_current_weapon_stats.damage), scaling_stats_text]

func serialize() -> Dictionary:
    var serialized =.serialize()
    serialized.weapon_stats = weapon_stats.serialize()

    return serialized

func deserialize_and_merge(serialized: Dictionary) -> void:
    .deserialize_and_merge(serialized)

    var stats = MeleeWeaponStats.new()
    stats.deserialize_and_merge(serialized.weapon_stats)
    weapon_stats = stats as Resource
