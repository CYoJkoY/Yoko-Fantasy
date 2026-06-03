extends Effect

export(String) var set_id = ""
var set_id_hash: int = Keys.empty_hash

# =========================== Extension =========================== #
func duplicate(subresources := false) -> Resource:
    var duplication = .duplicate(subresources)

    if set_id_hash == Keys.empty_hash and set_id != "":
        set_id_hash = Keys.generate_hash(set_id)

    duplication.set_id_hash = set_id_hash

    return duplication

static func get_id() -> String:
    return "fantasy_add_weapon_set"

func _generate_hashes() -> void:
    ._generate_hashes()
    set_id_hash = Keys.generate_hash(set_id)

func apply(player_index: int) -> void:
    if custom_key_hash == Keys.empty_hash: return

    var effects: Dictionary = RunData.get_player_effects(player_index)
    var effect_items: Array = effects[custom_key_hash]
    if effect_items.has(set_id_hash): return

    effect_items.append(set_id_hash)

func unapply(player_index: int) -> void:
    if custom_key_hash == Keys.empty_hash: return

    RunData.get_player_effects(player_index)[custom_key_hash].erase(set_id_hash)

func get_args(_player_index: int) -> Array:
    var set_data: SetData = ItemService.get_set(set_id_hash)
    var set_name: String = tr(set_data.name.to_upper())
    var set_text: String = "[color=#%s]%s[/color]" % [ProgressData.settings.color_positive, set_name]
    return [set_text]

func serialize() -> Dictionary:
    var serialized: Dictionary = .serialize()
    serialized.set_id = set_id
    return serialized

func deserialize_and_merge(serialized: Dictionary) -> void:
    .deserialize_and_merge(serialized)
    set_id = serialized.set_id as String
    set_id_hash = Keys.generate_hash(set_id)
