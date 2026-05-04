extends Effect

export(int) var need_times: int = 4
export(float) var speed: float = 300.0

# =========================== Extension =========================== #
static func get_id() -> String:
	return "fantasy_dance"

func apply(player_index: int) -> void:
    if custom_key_hash == Keys.empty_hash: return

    var effects: Dictionary = RunData.get_player_effects(player_index)
    effects[custom_key_hash].append([speed, need_times, value, key_hash])

func unapply(player_index: int) -> void:
    if custom_key_hash == Keys.empty_hash: return

    var effects: Dictionary = RunData.get_player_effects(player_index)
    effects[custom_key_hash].erase([speed, need_times, value, key_hash])

func get_args(_player_index: int) -> Array:
	return [str(need_times), str(stepify(value / 60.0, 0.1)), str(stepify(value / 180.0, 0.1))]

func serialize() -> Dictionary:
    var serialized: Dictionary =.serialize()
    serialized.need_times = need_times
    serialized.speed = speed

    return serialized

func deserialize(serialized: Dictionary) -> void:
    .deserialize(serialized)
    need_times = serialized.need_times
    speed = serialized.speed
