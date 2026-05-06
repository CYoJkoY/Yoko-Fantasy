extends NullEffect

export(String) var stat = ""
export(int) var stat_nb = 1
var stat_hash: int = Keys.empty_hash
export(bool) var is_temp = true

# =========================== Extension =========================== #
func duplicate(subresources := false) -> Resource:
    var duplication =.duplicate(subresources)

    if stat_hash == Keys.empty_hash and stat != "":
        stat_hash = Keys.generate_hash(stat)
    
    duplication.stat_hash = stat_hash

    return duplication

func _generate_hashes() -> void:
    ._generate_hashes()
    stat_hash = Keys.generate_hash(stat)

static func get_id() -> String:
    return "fantasy_gain_stat_every_killed_enemies"

func get_args(_player_index: int) -> Array:
    return [str(stat_nb), tr(stat.to_upper()), str(value)]

func apply(player_index: int) -> void:
    if key_hash == Keys.empty_hash: return
    
    var effects: Dictionary = RunData.get_player_effects(player_index)
    effects[key_hash].append([value, stat_hash, stat_nb, is_temp])

func unapply(player_index: int) -> void:
    if key_hash == Keys.empty_hash: return
    
    var effects: Dictionary = RunData.get_player_effects(player_index)
    effects[key_hash].erase([value, stat_hash, stat_nb, is_temp])

func serialize() -> Dictionary:
    var serialized =.serialize()
    serialized.stat = stat
    serialized.stat_nb = stat_nb
    serialized.is_temp = is_temp

    return serialized

func deserialize_and_merge(serialized: Dictionary) -> void:
    .deserialize_and_merge(serialized)
    stat = serialized.stat as String
    stat_hash = Keys.generate_hash(stat)
    stat_nb = serialized.stat_nb as int
    is_temp = serialized.is_temp as bool
