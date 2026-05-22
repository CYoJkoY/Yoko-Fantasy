extends Effect

export(float) var base_chance = 0.5
export(Array) var damage_scaling_stats = [["stat_elemental_damage", 0.4]]
export(int) var base_chain_targets = 2
export(Array) var targets_scaling_stats = [["stat_elemental_damage", 0.1]]
export(float) var chain_damage_mult = 1.0
export(float) var arc_width = 4.0
export(float) var arc_jaggedness = 20.0
export(Color) var arc_color = Color("#54b8e3")
export(Color) var arc_glow_color = Color("#5588ff")
export(float) var arc_duration = 0.3
export(float) var arc_crit_chance = 0.0
export(float) var arc_crit_damage = 1.5
export(PackedScene) var arc_scene = preload("res://mods-unpacked/Yoko-Fantasy/content/specials/player/lightning_arc/lightning_arc.tscn")

# =========================== Extension =========================== #
func duplicate(subresources: bool = false) -> Resource:
    var duplication =.duplicate(subresources)
    if !damage_scaling_stats.empty():
        damage_scaling_stats = Utils.convert_to_hash_array(damage_scaling_stats)
    if !targets_scaling_stats.empty():
        targets_scaling_stats = Utils.convert_to_hash_array(targets_scaling_stats)

    duplication.damage_scaling_stats = damage_scaling_stats
    duplication.targets_scaling_stats = targets_scaling_stats

    return duplication

static func get_id() -> String:
    return "fantasy_lightning_chain_on_hit"

func _generate_hashes() -> void:
    ._generate_hashes()
    damage_scaling_stats = Utils.convert_to_hash_array(damage_scaling_stats)
    targets_scaling_stats = Utils.convert_to_hash_array(targets_scaling_stats)

func apply(player_index: int) -> void:
    if custom_key_hash == Keys.empty_hash: return

    var effects: Dictionary = RunData.get_player_effects(player_index)
    effects[custom_key_hash].append([base_chance, value, damage_scaling_stats,
        base_chain_targets, targets_scaling_stats, chain_damage_mult,
        arc_width, arc_jaggedness, arc_color.to_html(), arc_glow_color.to_html(),
        arc_duration, arc_crit_chance, arc_crit_damage, arc_scene.resource_path])

func unapply(player_index: int) -> void:
    if custom_key_hash == Keys.empty_hash: return

    var effects: Dictionary = RunData.get_player_effects(player_index)
    effects[custom_key_hash].erase([key_hash, base_chance, value, damage_scaling_stats,
        base_chain_targets, targets_scaling_stats, chain_damage_mult,
        arc_width, arc_jaggedness, arc_color.to_html(), arc_glow_color.to_html(),
        arc_duration, arc_crit_chance, arc_crit_damage, arc_scene.resource_path])

func get_args(player_index: int) -> Array:
    var chain_damage_text: String = Utils.ncl_get_dmg_text_with_scaling_stats(
        value, damage_scaling_stats,
        {
            "player_index": player_index
        }
    )

    var chain_targets_count_text: String = Utils.ncl_get_dmg_text_with_scaling_stats(
        base_chain_targets, targets_scaling_stats,
        {
            "player_index": player_index,
            "show_initial": false
        }
    )

    var chain_targets_text: String = Text.text(
        "FANTASY_CHAIN_TARGETS_FORMATTED",
        [
            "[color=%s]%s[/color]" % [Utils.SECONDARY_FONT_COLOR_HTML, tr("FANTASY_CHAIN_TARGETS")],
            chain_targets_count_text
        ]
    )

    var chain_damage_mult_text: String = Text.text(
        "FANTASY_CHAIN_DAMAGE_MULT_FORMATTED",
        [
            "[color=%s]%s[/color]" % [Utils.SECONDARY_FONT_COLOR_HTML, tr("FANTASY_CHAIN_DAMAGE_MULT")],
            "x" + str(chain_damage_mult * 100.0)
        ]
    )

    var chain_crit_text: String = Text.text(
        "CRITICAL_FORMATTED",
        [
            "[color=%s]%s[/color]" % [Utils.SECONDARY_FONT_COLOR_HTML, tr("CRITICAL")],
            "x" + str(arc_crit_damage), str(max(arc_crit_chance * 100.0, 0))
        ]
    )

    return [str(int(base_chance * 100)), chain_damage_text, chain_targets_text, chain_damage_mult_text, chain_crit_text]

func serialize() -> Dictionary:
    var serialized =.serialize()
    serialized.damage_scaling_stats = damage_scaling_stats
    serialized.base_chance = base_chance
    serialized.base_chain_targets = base_chain_targets
    serialized.targets_scaling_stats = targets_scaling_stats
    serialized.chain_damage_mult = chain_damage_mult
    serialized.arc_width = arc_width
    serialized.arc_jaggedness = arc_jaggedness
    serialized.arc_color = arc_color.to_html()
    serialized.arc_glow_color = arc_glow_color.to_html()
    serialized.arc_duration = arc_duration
    serialized.arc_crit_chance = arc_crit_chance
    serialized.arc_crit_damage = arc_crit_damage
    serialized.arc_scene = arc_scene.resource_path
    return serialized

func deserialize_and_merge(serialized: Dictionary) -> void:
    .deserialize_and_merge(serialized)
    damage_scaling_stats = Utils.convert_to_hash_array(serialized.get("damage_scaling_stats", []))
    base_chance = serialized.base_chance as float
    base_chain_targets = serialized.base_chain_targets as int
    targets_scaling_stats = Utils.convert_to_hash_array(serialized.get("targets_scaling_stats", []))
    chain_damage_mult = serialized.chain_damage_mult as float
    arc_width = serialized.arc_width as float
    arc_jaggedness = serialized.arc_jaggedness as float
    arc_color = Color(serialized.arc_color)
    arc_glow_color = Color(serialized.arc_glow_color)
    arc_duration = serialized.arc_duration as float
    arc_crit_chance = serialized.arc_crit_chance as float
    arc_crit_damage = serialized.arc_crit_damage as float
    arc_scene = load(serialized.arc_scene) as PackedScene
