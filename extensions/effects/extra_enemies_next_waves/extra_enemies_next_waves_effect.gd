extends Effect

export(String) var name: String = ""
export(Resource) var extra_group_data: Resource = null
export(int) var waves: int = 0
export(String) var tracking_key = ""
var tracking_key_hash: int = Keys.empty_hash

# =========================== Extension =========================== #
func duplicate(subresources := false) -> Resource:
    var duplication =.duplicate(subresources)
    if tracking_key_hash == Keys.empty_hash and tracking_key != "":
        tracking_key_hash = Keys.generate_hash(tracking_key)
    
    duplication.tracking_key_hash = tracking_key_hash

    return duplication

static func get_id() -> String:
    return "fantasy_extra_enemies_next_waves"

func _generate_hashes() -> void:
    ._generate_hashes()
    tracking_key_hash = Keys.generate_hash(tracking_key)

func apply(player_index: int) -> void:
    if key_hash == Keys.empty_hash: return
    
    var effects: Dictionary = RunData.get_player_effects(player_index)
    effects[key_hash].append([extra_group_data.resource_path, value, waves, tracking_key_hash])

func unapply(player_index: int) -> void:
    if key_hash == Keys.empty_hash: return
    
    var effects: Dictionary = RunData.get_player_effects(player_index)
    effects[key_hash].erase([extra_group_data.resource_path, value, waves, tracking_key_hash])

func get_args(_player_index: int) -> Array:
    var args: Array =.get_args(_player_index)
    var str_waves: String = "∞" if waves >= 999 else str(waves)
    var enemy_name: String = tr(name.to_upper())
    var remaining_waves: int = RunData.ncl_get_effect_tracking_value(tracking_key_hash, _player_index)
    var tracking: String = Utils.ncl_create_tracking("TRACKING_REMAINING", remaining_waves)
    
    args.append(str_waves)
    args.append(enemy_name)
    args.append(tracking)
    
    return args

func serialize() -> Dictionary:
    var serialized =.serialize()
    serialized.name = name
    serialized.extra_group_data = extra_group_data.resource_path
    serialized.waves = waves
    serialized.tracking_key = tracking_key

    return serialized

func deserialize_and_merge(serialized: Dictionary) -> void:
    .deserialize_and_merge(serialized)
    name = serialized.name as String
    extra_group_data = load(serialized.extra_group_data) as Resource
    waves = serialized.waves as int
    tracking_key = serialized.tracking_key as String
    tracking_key_hash = Keys.generate_hash(serialized.tracking_key) as int
