extends DoubleValueEffect

export(int) var base_cooldown = 180
export(int) var base_damage = 10
export(Array, Array) var scaling_stats = [["stat_fantasy_holy", 1.0]]

# =========================== Extension =========================== #
func duplicate(subresources := false) -> Resource:
    var duplication =.duplicate(subresources)
    if !scaling_stats.empty():
        scaling_stats = Utils.convert_to_hash_array(scaling_stats)
    
    duplication.scaling_stats = scaling_stats

    return duplication

static func get_id() -> String:
    return "fantasy_periodic_radius_damage"

func _generate_hashes() -> void:
    ._generate_hashes()
    scaling_stats = Utils.convert_to_hash_array(scaling_stats)

func apply(player_index: int) -> void:
    if key == "": return

    var effects = RunData.get_player_effects(player_index)
    effects[key_hash].append([value, value2, scaling_stats, base_cooldown, base_damage])

func get_args(player_index: int) -> Array:
    var scaling_dmg: float = Utils.ncl_get_scaling_stats_dmg(scaling_stats, player_index)
    var total_damage: float = base_damage + scaling_dmg
    var dmg_text: String = Utils.ncl_get_dmg_text_with_scaling_stats(total_damage, scaling_stats, base_damage)

    var final_cooldown: float = base_cooldown / (1 + Utils.get_stat(Keys.stat_attack_speed_hash, player_index) / 100.0)
    var cooldown_text: String = str(stepify(final_cooldown / 60.0, 0.01))

    var total_range: String = str(Utils.get_stat(Keys.stat_range_hash, player_index) * value2 / 100.0 + value)
    var range_scaling_text: String = Utils.get_scaling_stat_icon_text(Keys.stat_range_hash, 0.5, player_index)
    var range_text: String = "%s(+%s)" % [total_range, range_scaling_text]

    return [cooldown_text, range_text, dmg_text]

func unapply(player_index: int) -> void:
    if key == "": return

    var effects = RunData.get_player_effects(player_index)
    effects[key_hash].erase([value, value2, scaling_stats, base_cooldown, base_damage])

func serialize() -> Dictionary:
    var serialized: Dictionary =.serialize()
    serialized.base_cooldown = base_cooldown
    serialized.base_damage = base_damage
    serialized.scaling_stats = scaling_stats

    return serialized

func deserialize_and_merge(serialized: Dictionary) -> void:
    .deserialize_and_merge(serialized)
    base_cooldown = serialized.base_cooldown
    base_damage = serialized.base_damage
    scaling_stats = Utils.convert_to_hash_array(serialized.get("scaling_stats", [])) as Array
