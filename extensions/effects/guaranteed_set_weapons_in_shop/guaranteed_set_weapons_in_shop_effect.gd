extends Effect

export(String) var set_id = ""
var set_id_hash: int = Keys.empty_hash

func duplicate(subresources := false) -> Resource:
    var duplication = .duplicate(subresources)

    if set_id_hash == Keys.empty_hash and set_id != "":
        set_id_hash = Keys.generate_hash(set_id)

    duplication.set_id_hash = set_id_hash

    return duplication

static func get_id() -> String:
    return "fantasy_guaranteed_set_weapons_in_shop"

func _generate_hashes() -> void:
    ._generate_hashes()
    set_id_hash = Keys.generate_hash(set_id)

func apply(player_index: int) -> void:
    if custom_key_hash == Keys.empty_hash: return

    var effect_items: Array = RunData.get_player_effect(custom_key_hash, player_index)
    for existing_item in effect_items:
        if existing_item[0] != set_id_hash: continue

        existing_item[1] += value
        return

    effect_items.append([set_id_hash, value])

func unapply(player_index: int) -> void:
    if custom_key_hash == Keys.empty_hash: return

    var effect_items: Array = RunData.get_player_effect(custom_key_hash, player_index)
    for i in range(effect_items.size()):
        var existing_item: Array = effect_items[i]
        if existing_item[0] != set_id_hash: continue

        existing_item[1] -= value
        if existing_item[1] <= 0:
            effect_items.remove(i)
        return

func get_args(_player_index: int) -> Array:
    var set_data: SetData = ItemService.get_set(set_id_hash)
    var set_name: String = tr(set_data.name.to_upper()) if set_data != null else set_id
    return [str(value), set_name]

func serialize() -> Dictionary:
    var serialized: Dictionary = .serialize()
    serialized.set_id = set_id

    return serialized

func deserialize_and_merge(serialized: Dictionary) -> void:
    .deserialize_and_merge(serialized)
    set_id = serialized.set_id as String
    set_id_hash = Keys.generate_hash(serialized.set_id) as int
