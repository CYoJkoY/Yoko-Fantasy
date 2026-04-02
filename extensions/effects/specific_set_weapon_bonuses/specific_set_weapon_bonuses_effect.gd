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
    var effect_items: Array = effects[custom_key_hash]
    for existing_item in effect_items:
        if existing_item[2] == set_id_hash:
            existing_item[1] += value
            return

    effect_items.append([key_hash, value, set_id_hash])

func unapply(player_index: int) -> void:
    if custom_key_hash == Keys.empty_hash: return

    var effects: Dictionary = RunData.get_player_effects(player_index)
    var effect_items: Array = effects[custom_key_hash]
    for i in range(effect_items.size()):
        var existing_item: Array = effect_items[i]
        if existing_item[2] == set_id_hash:
            existing_item[1] -= value
            if existing_item[1] == 0: effect_items.remove(i)
            return

func get_args(_player_index: int) -> Array:
    var set_data: SetData = ItemService.get_set(set_id_hash)
    var weapons: Array = RunData.get_player_weapons_ref(_player_index)
    var nb_specific_set_weapons: int = 0
    var bonus_value: int = 0
    for weapon in weapons: for set in weapon.sets:
        if set.my_id_hash != set_id_hash: continue

        nb_specific_set_weapons += 1
        bonus_value = value * nb_specific_set_weapons

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
