extends Effect

export(int) var radius = 200
export(float) var range_rate = 0.05

# =========================== Extension =========================== #
static func get_id() -> String:
    return "fantasy_tree_radius_tempstats"

func apply(player_index: int) -> void:
    if custom_key == "": return

    var effects = RunData.get_player_effects(player_index)
    effects[custom_key_hash].append([key_hash, value, radius, range_rate])

func unapply(player_index: int) -> void:
    if custom_key == "": return

    var effects = RunData.get_player_effects(player_index)
    effects[custom_key_hash].erase([key_hash, value, radius, range_rate])

func get_args(player_index: int) -> Array:
    var range_text: String = Utils.ncl_get_range_text_with_scaling(radius, range_rate, player_index)

    return [tr(key.to_upper()), str(value), range_text]

func serialize() -> Dictionary:
    var serialized: Dictionary =.serialize()
    serialized.radius = radius
    serialized.range_rate = range_rate

    return serialized

func deserialize_and_merge(serialized: Dictionary) -> void:
    .deserialize_and_merge(serialized)
    radius = serialized.radius
    range_rate = serialized.range_rate
