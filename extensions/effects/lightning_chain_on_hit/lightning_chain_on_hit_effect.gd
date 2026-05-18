extends NullEffect

export(float) var base_chance = 0.5
export(int) var base_chain_targets = 1
export(Array) var scaling_stats = [["stat_elemental_damage", 0.05]]
export(float) var chain_range = 350.0
export(float) var chain_damage_mult = 0.65
export(float) var arc_width = 4.0
export(float) var arc_jaggedness = 20.0
export(Color) var arc_color = Color(0.3, 0.7, 1.0, 0.9)
export(Color) var arc_glow_color = Color(1.0, 1.0, 1.0, 0.5)
export(float) var arc_duration = 0.3
export(PackedScene) var arc_scene = null

# =========================== Extension =========================== #
func duplicate(subresources := false) -> Resource:
    var duplication =.duplicate(subresources)
    if !scaling_stats.empty():
        scaling_stats = Utils.convert_to_hash_array(scaling_stats)

    duplication.scaling_stats = scaling_stats

    return duplication

static func get_id() -> String:
    return "fantasy_lightning_chain_on_hit"

func _generate_hashes() -> void:
    ._generate_hashes()
    scaling_stats = Utils.convert_to_hash_array(scaling_stats)

func get_chain_targets(player_index: int) -> int:
    return Utils.ncl_get_dmg_with_scaling_stats(base_chain_targets, scaling_stats, player_index)

func get_args(player_index: int) -> Array:
    var str_chain_targets_text: String = Utils.ncl_get_dmg_text_with_scaling_stats(
        base_chain_targets, scaling_stats,
        {
            "player_index": player_index
        }
    )

    return [str(int(base_chance * 100)), str_chain_targets_text, str(int(chain_damage_mult * 100))]

func serialize() -> Dictionary:
    var serialized =.serialize()
    serialized.base_chance = base_chance
    serialized.base_chain_targets = base_chain_targets
    serialized.scaling_stats = scaling_stats
    serialized.chain_range = chain_range
    serialized.chain_damage_mult = chain_damage_mult
    serialized.arc_width = arc_width
    serialized.arc_jaggedness = arc_jaggedness
    serialized.arc_color = arc_color.to_html()
    serialized.arc_glow_color = arc_glow_color.to_html()
    serialized.arc_duration = arc_duration
    serialized.arc_scene = arc_scene.resource_path
    return serialized

func deserialize_and_merge(serialized: Dictionary) -> void:
    .deserialize_and_merge(serialized)
    base_chance = serialized.base_chance as float
    base_chain_targets = serialized.base_chain_targets as int
    scaling_stats = Utils.convert_to_hash_array(serialized.get("scaling_stats", [])) as Array
    chain_range = serialized.chain_range as float
    chain_damage_mult = serialized.chain_damage_mult as float
    arc_width = serialized.arc_width as float
    arc_jaggedness = serialized.arc_jaggedness as float
    arc_color = Color(serialized.arc_color)
    arc_glow_color = Color(serialized.arc_glow_color)
    arc_duration = serialized.arc_duration as float
    arc_scene = load(serialized.arc_scene) as PackedScene
