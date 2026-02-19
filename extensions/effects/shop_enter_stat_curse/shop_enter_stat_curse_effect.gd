extends Effect

export(int) var chance = 0
export(int) var curse_num = 0
export(String) var tracking_key = ""
var tracking_key_hash: int = Keys.empty_hash

func duplicate(subresources := false) -> Resource:
    var duplication =.duplicate(subresources)

    if tracking_key_hash == Keys.empty_hash and tracking_key != "":
        tracking_key_hash = Keys.generate_hash(tracking_key)
    
    duplication.tracking_key_hash = tracking_key_hash

    return duplication

static func get_id() -> String:
    return "fantasy_shop_enter_stat_curse"

func _generate_hashes() -> void:
    ._generate_hashes()
    tracking_key_hash = Keys.generate_hash(tracking_key)

func apply(player_index: int) -> void:
    if custom_key_hash == Keys.empty_hash: return

    var effects: Dictionary = RunData.get_player_effects(player_index)
    effects[custom_key_hash].append([key_hash, value, chance, curse_num, tracking_key_hash])

func unapply(player_index: int) -> void:
    if custom_key_hash == Keys.empty_hash: return
    
    var effects: Dictionary = RunData.get_player_effects(player_index)
    effects[custom_key_hash].erase([key_hash, value, chance, curse_num, tracking_key_hash])

func get_args(_player_index: int) -> Array:
    var tracking_value: Array = []
    tracking_value.append(RunData.ncl_get_effect_tracking_value(tracking_key_hash, _player_index, 0))
    tracking_value.append(RunData.ncl_get_effect_tracking_value(tracking_key_hash, _player_index, 1))
    var str_tracking_value: Array = []
    match tracking_value[0] >= 0:
        true: str_tracking_value.append(Utils.ncl_create_tracking("STATS_GAINED", tracking_value[0]))
        false: str_tracking_value.append(Utils.ncl_create_tracking("STATS_LOST", -tracking_value[0]))
    str_tracking_value.append(Utils.ncl_create_tracking("TRACKING_CURSED", tracking_value[1]))

    return [str(value), tr(key.to_upper()), str(chance), str(curse_num), str_tracking_value[0], str_tracking_value[1]]

func serialize() -> Dictionary:
    var serialized: Dictionary =.serialize()
    serialized.chance = chance
    serialized.curse_num = curse_num
    serialized.tracking_key = tracking_key
    
    return serialized

func deserialize_and_merge(serialized: Dictionary) -> void:
    .deserialize_and_merge(serialized)
    chance = serialized.chance as int
    curse_num = serialized.curse_num as int
    tracking_key = serialized.tracking_key as String
    tracking_key_hash = Keys.generate_hash(serialized.tracking_key) as int
