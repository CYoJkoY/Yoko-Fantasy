extends DoubleValueEffect

export(int) var killed_need = 16
export(int) var stat_num = 1
export(int) var gold_num = 8
export(String) var consumable_id = "consumable_fantasy_soul"
var consumable_id_hash: int = Keys.empty_hash
export(int) var consumable_num = 1

# =========================== Extension =========================== #
func duplicate(subresources := false) -> Resource:
    var duplication =.duplicate(subresources)

    if consumable_id_hash == Keys.empty_hash and consumable_id != "":
        consumable_id_hash = Keys.generate_hash(consumable_id)
    
    duplication.consumable_id_hash = consumable_id_hash

    return duplication

static func get_id() -> String:
    return "fantasy_sacrificial_circle"

func _generate_hashes() -> void:
    ._generate_hashes()
    consumable_id_hash = Keys.generate_hash(consumable_id)

func apply(player_index: int) -> void:
    if custom_key == "": return

    var effects = RunData.get_player_effects(player_index)
    effects[custom_key_hash].append([value, value2, killed_need, key_hash, stat_num, gold_num, consumable_id_hash, consumable_num])

func unapply(player_index: int) -> void:
    if custom_key == "": return

    var effects = RunData.get_player_effects(player_index)
    effects[custom_key_hash].erase([value, value2, killed_need, key_hash, stat_num, gold_num, consumable_id_hash, consumable_num])

func get_args(player_index: int) -> Array:
    var range_rate: float = value2 / 100.0
    var total_range: int = int(Utils.get_stat(Keys.stat_range_hash, player_index) * range_rate + value)
    var range_scaling_text: String = Utils.get_scaling_stat_icon_text(Keys.stat_range_hash, range_rate)
    var range_text: String = "[color=%s]%s[/color] (%s)" % [Utils.ncl_get_signed_col(total_range, value), total_range, range_scaling_text]
    
    return [range_text, str(killed_need), str(stat_num), tr(key.to_upper()), str(gold_num), str(consumable_num), tr(consumable_id.to_upper())]

func serialize() -> Dictionary:
    var serialized =.serialize()
    serialized.killed_need = killed_need
    serialized.stat_num = stat_num
    serialized.gold_num = gold_num
    serialized.consumable_id = consumable_id
    serialized.consumable_num = consumable_num

    return serialized

func deserialize_and_merge(serialized: Dictionary) -> void:
    .deserialize_and_merge(serialized)
    killed_need = serialized.killed_need
    stat_num = serialized.stat_num
    gold_num = serialized.gold_num
    consumable_id = serialized.consumable_id
    consumable_id_hash = Keys.generate_hash(consumable_id)
    consumable_num = serialized.consumable_num
