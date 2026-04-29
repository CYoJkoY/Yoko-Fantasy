extends DoubleValueEffect

export(Resource) var enemy_data = null
export(String) var enemy_name_key = ""

# =========================== Extension =========================== #
static func get_id() -> String:
    return "fantasy_extra_enemies_each_wave_by_stat"

func apply(player_index: int) -> void:
    if custom_key == "": return

    var effects: Dictionary = RunData.get_player_effects(player_index)
    effects[custom_key_hash].append([value, value2, enemy_data.resource_path, key_hash])

func unapply(player_index: int) -> void:
    if custom_key == "": return

    var effects: Dictionary = RunData.get_player_effects(player_index)
    effects[custom_key_hash].erase([value, value2, enemy_data.resource_path, key_hash])

func get_args(player_index: int) -> Array:
    var finall_value: int = value + int(Utils.get_stat(key_hash, player_index) * value2 / 100.0)
    var str_value: String = "[color=%s]%s[/color]" % [Utils.ncl_get_signed_col(finall_value, value), finall_value]
    var scaling_stat_text: String = Utils.get_scaling_stat_icon_text(key_hash, value2 / 100.0)
    str_value = "%s (%s)" % [str_value, scaling_stat_text]
    return [str_value, tr(enemy_name_key)]

func serialize() -> Dictionary:
    var serialized: Dictionary =.serialize()
    serialized.enemy_data = enemy_data.resource_path
    serialized.enemy_name_key = enemy_name_key
    return serialized

func deserialize_and_merge(serialized: Dictionary) -> void:
    .deserialize_and_merge(serialized)
    enemy_data = load(serialized.enemy_data) as Resource
    enemy_name_key = serialized.enemy_name_key as String
