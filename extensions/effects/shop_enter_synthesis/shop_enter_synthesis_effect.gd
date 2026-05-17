extends Effect

export(Array, Array) var materials: Array = [["weapon_fantasy_fake_brave_sword_4", 5]]
export(String) var result_id = "weapon_fantasy_brave_sword_4"
var result_id_hash: int = Keys.empty_hash

# =========================== Extension =========================== #
func duplicate(subresources := false) -> Resource:
    var duplication =.duplicate(subresources)
    if !materials.empty():
        materials = Utils.convert_to_hash_array(materials)
    
    if result_id_hash == Keys.empty_hash and result_id != "":
        result_id_hash = Keys.generate_hash(result_id)

    duplication.materials = materials
    duplication.result_id_hash = result_id_hash

    return duplication

static func get_id() -> String:
    return "fantasy_shop_enter_synthesis"

func _generate_hashes() -> void:
    ._generate_hashes()
    materials = Utils.convert_to_hash_array(materials)
    result_id_hash = Keys.generate_hash(result_id)

func apply(player_index: int) -> void:
    if custom_key_hash == Keys.empty_hash: return

    var effects = RunData.get_player_effects(player_index)
    effects[custom_key_hash].append([key_hash, value, materials, result_id_hash])

func unapply(player_index: int) -> void:
    if custom_key_hash == Keys.empty_hash: return

    var effects = RunData.get_player_effects(player_index)
    effects.erase([key_hash, value, materials, result_id_hash])

func get_args(_player_index: int) -> Array:
    var parts: Array = []
    for material in materials: parts.append(Utils.ncl_get_gear_name_from_id(material[0], material[1]))
    var materials_text: String = ", ".join(parts)
    var result_text: String = Utils.ncl_get_gear_name_from_id(result_id_hash)

    var pity_text: String = ""
    var pity_id: String = Utils.fa_get_synthesis_pity_id(materials, result_id_hash)
    var fail_count: int = Utils.fa_get_synthesis_fail_count(pity_id, _player_index)
    if fail_count > 0:
        var multiplier: float = Utils.fa_get_synthesis_pity_multiplier(value, pity_id, materials, result_id_hash, _player_index)
        pity_text = "[color=%s]%s[/color]" % [Utils.SECONDARY_FONT_COLOR_HTML, tr("FANTASY_PITY_MULTIPLIER").format([str(stepify(multiplier, 0.1))])]

    return [str(value), materials_text, result_text, pity_text]

func serialize() -> Dictionary:
    var serialized: Dictionary =.serialize()
    serialized.materials = materials
    serialized.result_id = result_id

    return serialized

func deserialize_and_merge(serialized: Dictionary) -> void:
    .deserialize_and_merge(serialized)
    materials = Utils.convert_to_hash_array(serialized.get("materials", []))
    result_id = serialized.result_id as String
    result_id_hash = Keys.generate_hash(result_id)
