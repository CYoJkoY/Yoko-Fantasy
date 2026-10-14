extends NullEffect

export (int) var base_range: int = 650
export (float) var range_scaling: float = 1.0


static func get_id() -> String:
    return "weapon_shamisen"


func get_chain_range(player_index: int) -> float:
    return max(0.0, base_range + Utils.get_stat(Keys.stat_range_hash, player_index) * range_scaling)


func get_args(player_index: int) -> Array:
    return [Utils.ncl_get_range_text_with_scaling(base_range, range_scaling, player_index)]


func serialize() -> Dictionary:
    var serialized: Dictionary = .serialize()
    serialized.base_range = base_range
    serialized.range_scaling = range_scaling
    return serialized


func deserialize_and_merge(serialized: Dictionary) -> void:
    .deserialize_and_merge(serialized)
    base_range = serialized.base_range
    range_scaling = serialized.range_scaling
