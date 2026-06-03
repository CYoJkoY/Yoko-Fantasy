extends Effect

export(String) var item_id = ""
var item_id_hash: int = Keys.empty_hash
export(String) var sound_path = ""

# =========================== Extension =========================== #
func duplicate(subresources := false) -> Resource:
    var duplication = .duplicate(subresources)

    if item_id_hash == Keys.empty_hash and item_id != "":
        item_id_hash = Keys.generate_hash(item_id)

    duplication.item_id_hash = item_id_hash
    duplication.sound_path = sound_path

    return duplication

static func get_id() -> String:
    return "fantasy_gain_item_on_reroll"

func _generate_hashes() -> void:
    ._generate_hashes()
    item_id_hash = Keys.generate_hash(item_id)

func apply(player_index: int) -> void:
    if custom_key_hash == Keys.empty_hash: return

    RunData.get_player_effects(player_index)[custom_key_hash].append([value, item_id_hash, sound_path])

func unapply(player_index: int) -> void:
    if custom_key_hash == Keys.empty_hash: return

    var effect_items: Array = RunData.get_player_effects(player_index)[custom_key_hash]
    for i in range(effect_items.size()):
        if effect_items[i][0] == value and effect_items[i][1] == item_id_hash:
            effect_items.remove(i)
            return

func get_args(_player_index: int) -> Array:
    var item_text: String = Utils.ncl_get_gear_name_from_id(item_id_hash)
    return [str(value), item_text]

func serialize() -> Dictionary:
    var serialized: Dictionary = .serialize()
    serialized.item_id = item_id
    serialized.sound_path = sound_path
    return serialized

func deserialize_and_merge(serialized: Dictionary) -> void:
    .deserialize_and_merge(serialized)
    item_id = serialized.item_id as String
    item_id_hash = Keys.generate_hash(item_id)
    sound_path = serialized.get("sound_path", "") as String
