extends NullEffect

export (int) var chance = 0
export (int) var curse_num = 0

static func get_id() -> String:
	return "fantasy_shop_enter_stat_curse"

func apply(player_index: int) -> void:
    var effects: Dictionary = RunData.get_player_effects(player_index)
    effects[custom_key_hash].append(key_hash, value, chance, curse_num)
    Utils.reset_stat_cache(player_index)

func unapply(player_index: int) -> void:
    var effects: Dictionary = RunData.get_player_effects(player_index)
    effects[custom_key_hash].erase(key_hash, value, chance, curse_num)
    Utils.reset_stat_cache(player_index)

func get_args(_player_index: int) -> Array:
    return [str(value), tr(key.to_upper()), str(chance), str(curse_num)]

func serialize() -> Dictionary:
    var serialized: Dictionary = .serialize()
    serialized.chance = chance as int
    serialized.curse_num = curse_num as int
    
    return serialized

func deserialize_and_merge(serialized: Dictionary) -> void:
    .deserialize_and_merge(serialized)
    chance = serialized.chacne
    curse_num = serialized.curse_num
