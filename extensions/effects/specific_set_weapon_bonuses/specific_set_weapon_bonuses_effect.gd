extends Effect

export(String) var set_id = ""
var set_id_hash: int = Keys.empty_hash
export(int) var need_num = 1

# =========================== Extension =========================== #
func duplicate(subresources := false) -> Resource:
    var duplication =.duplicate(subresources)

    if set_id_hash == Keys.empty_hash and set_id != "":
        set_id_hash = Keys.generate_hash(set_id)
    
    duplication.set_id_hash = set_id_hash

    return duplication

static func get_id() -> String:
    return "fantasy_specific_set_weapon_bonuses"

func _generate_hashes() -> void:
    ._generate_hashes()
    set_id_hash = Keys.generate_hash(set_id)

func apply(player_index: int) -> void:
    if custom_key_hash == Keys.empty_hash: return

    var effects: Dictionary = RunData.get_player_effects(player_index)
    effects[custom_key_hash].append([key_hash, value, set_id_hash])

func unapply(player_index: int) -> void:
    if custom_key_hash == Keys.empty_hash: return

    var effects: Dictionary = RunData.get_player_effects(player_index)
    effects[custom_key_hash].erase([key_hash, value, set_id_hash])

func get_args(_player_index: int) -> Array:
    var set_data: SetData = ItemService.get_set(set_id_hash)
    var bonuses: Dictionary = RunData.get_player_effect(Utils.fantasy_old_specific_set_weapon_bonuses_hash, _player_index)
    var bonus_value: int = bonuses.get(key_hash, 0)

    return [str(value), tr(key.to_upper()), tr(set_data.name.to_upper()), str(bonus_value), str(need_num)]

func serialize() -> Dictionary:
    var serialized: Dictionary =.serialize()
    serialized.set_id = set_id
    serialized.need_num = need_num
    
    return serialized

func deserialize_and_merge(serialized: Dictionary) -> void:
    .deserialize_and_merge(serialized)
    set_id = serialized.set_id as String
    set_id_hash = Keys.generate_hash(serialized.set_id) as int
    need_num = serialized.need_num as int
