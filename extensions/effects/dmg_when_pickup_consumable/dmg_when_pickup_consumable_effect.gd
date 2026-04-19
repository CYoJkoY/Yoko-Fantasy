extends DoubleValueEffect

export(Array, Array) var scaling_stats = [["stat_fantasy_holy", 1.0]]

# =========================== Extension =========================== #
func duplicate(subresources := false) -> Resource:
    var duplication =.duplicate(subresources)
    if !scaling_stats.empty():
        scaling_stats = Utils.convert_to_hash_array(scaling_stats)
    
    duplication.scaling_stats = scaling_stats

    return duplication

static func get_id() -> String:
    return "fantasy_dmg_when_pickup_consumable"

func _generate_hashes() -> void:
    ._generate_hashes()
    scaling_stats = Utils.convert_to_hash_array(scaling_stats)

func apply(player_index: int) -> void:
    if custom_key == "": return

    var effects = RunData.get_player_effects(player_index)
    effects[custom_key_hash].append([key_hash, value, scaling_stats, value2])

func unapply(player_index: int) -> void:
    if custom_key == "": return

    var effects = RunData.get_player_effects(player_index)
    effects[custom_key_hash].erase([key_hash, value, scaling_stats, value2])

func get_args(player_index: int) -> Array:
    var scaling_dmg: float = Utils.ncl_get_scaling_stats_dmg(scaling_stats, player_index)
    var total_damage: float = value2 + scaling_dmg
    var dmg_text: String = Utils.ncl_get_dmg_text_with_scaling_stats(total_damage, scaling_stats, value2)

    return [tr(key.to_upper()), str(value), dmg_text]

func serialize() -> Dictionary:
    var serialized: Dictionary =.serialize()
    serialized.scaling_stats = scaling_stats

    return serialized

func deserialize_and_merge(serialized: Dictionary) -> void:
    .deserialize_and_merge(serialized)
    scaling_stats = Utils.convert_to_hash_array(serialized.get("scaling_stats", [])) as Array
