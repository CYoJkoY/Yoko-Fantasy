extends DoubleValueEffect

export(Array, Array) var scaling_stats = [["stat_fantasy_holy", 1.0]]
export(String) var tracked_key = ""
var tracked_key_hash: int = Keys.empty_hash

# =========================== Extension =========================== #
func duplicate(subresources := false) -> Resource:
    var duplication =.duplicate(subresources)
    if !scaling_stats.empty():
        scaling_stats = Utils.convert_to_hash_array(scaling_stats)
    
    if tracked_key_hash == Keys.empty_hash and tracked_key != "":
        tracked_key_hash = Keys.hash(tracked_key)
    
    duplication.scaling_stats = scaling_stats
    duplication.tracked_key_hash = tracked_key_hash

    return duplication

static func get_id() -> String:
    return "fantasy_dmg_when_pickup_consumable"

func _generate_hashes() -> void:
    ._generate_hashes()
    scaling_stats = Utils.convert_to_hash_array(scaling_stats)
    tracked_key_hash = Keys.hash(tracked_key)

func apply(player_index: int) -> void:
    if custom_key == "": return

    var effects = RunData.get_player_effects(player_index)
    effects[custom_key_hash].append([key_hash, value, scaling_stats, value2, tracked_key_hash])

func unapply(player_index: int) -> void:
    if custom_key == "": return

    var effects = RunData.get_player_effects(player_index)
    effects[custom_key_hash].erase([key_hash, value, scaling_stats, value2, tracked_key_hash])

func get_args(player_index: int) -> Array:
    var scaling_dmg: float = Utils.ncl_get_scaling_stats_dmg(scaling_stats, player_index)
    var total_damage: float = value2 + scaling_dmg
    var dmg_text: String = Utils.ncl_get_dmg_text_with_scaling_stats(total_damage, scaling_stats, value2)

    return [tr(key.to_upper()), str(value), dmg_text]

func serialize() -> Dictionary:
    var serialized: Dictionary =.serialize()
    serialized.scaling_stats = scaling_stats
    serialized.tracked_key = tracked_key

    return serialized

func deserialize_and_merge(serialized: Dictionary) -> void:
    .deserialize_and_merge(serialized)
    scaling_stats = Utils.convert_to_hash_array(serialized.get("scaling_stats", [])) as Array
    tracked_key = serialized.tracked_key as String
    tracked_key_hash = Keys.generate_hash(serialized.tracked_key) as int
