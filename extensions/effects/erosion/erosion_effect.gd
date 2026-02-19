extends Effect

export(Array, Array) var scaling_stats = [["stat_curse", 1.0]]
export(int, 0, 100) var chance = 25
export(int) var times = 3
export(int) var cd = 30
export(int, 0, 100) var crit_chance = 0
export(float) var crit_damage = 1.5
export(String) var source_id = ""
var source_id_hash: int = Keys.empty_hash

# =========================== Extension =========================== #
func duplicate(subresources := false) -> Resource:
    var duplication =.duplicate(subresources)
    if !scaling_stats.empty():
        scaling_stats = Utils.convert_to_hash_array(scaling_stats)
    
    if source_id_hash == Keys.empty_hash and source_id != "":
        source_id_hash = Keys.generate_hash(source_id)

    duplication.scaling_stats = scaling_stats
    duplication.source_id_hash = source_id_hash

    return duplication

static func get_id() -> String:
    return "fantasy_erosion"

func _generate_hashes() -> void:
    ._generate_hashes()
    scaling_stats = Utils.convert_to_hash_array(scaling_stats)
    source_id_hash = Keys.generate_hash(source_id)

func apply(player_index: int) -> void:
    if key_hash == Keys.empty_hash: return

    var effects = RunData.get_player_effects(player_index)
    effects[key_hash].append([value, scaling_stats, chance, times, cd, crit_chance, crit_damage, source_id_hash])

func unapply(player_index: int) -> void:
    if key_hash == Keys.empty_hash: return

    var effects = RunData.get_player_effects(player_index)
    effects[key_hash].erase([value, scaling_stats, chance, times, cd, crit_chance, crit_damage, source_id_hash])

func get_args(player_index: int) -> Array:
    var args: Array = []
    var percent_dmg_bonus: float = (1 + (Utils.get_stat(Keys.stat_percent_damage_hash, player_index) / 100.0))
    var true_damage: float = percent_dmg_bonus * (Utils.ncl_get_scaling_stats_dmg(scaling_stats, player_index) + value)
    var damage: int = max(1, round(true_damage)) as int
    var dmg_text: String = Utils.ncl_get_dmg_text_with_scaling_stats(damage, scaling_stats, value, {"nb": times, "show_initial": false})

    args.append(str(chance))
    args.append(dmg_text)

    return args

func serialize() -> Dictionary:
    var serialized: Dictionary =.serialize()
    serialized.scaling_stats = scaling_stats
    serialized.chance = chance
    serialized.times = times
    serialized.crit_chance = crit_chance
    serialized.crit_damage = crit_damage
    serialized.source_id = source_id

    return serialized

func deserialize_and_merge(serialized: Dictionary) -> void:
    .deserialize_and_merge(serialized)
    scaling_stats = Utils.convert_to_hash_array(serialized.get("scaling_stats", [])) as Array
    chance = serialized.chance as int
    times = serialized.times as int
    crit_chance = serialized.crit_chance as int
    crit_damage = serialized.crit_damage as float
    source_id = serialized.source_id as String
    source_id_hash = Keys.generate_hash(serialized.source_id) as int
