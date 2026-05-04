extends SceneEffectBehavior

export(Resource) var periodic_radius_damage_player_effect_behavior_data

var has_radius_damages: Array = []

# =========================== Extension =========================== #
func _ready() -> void:
    var nb_players: int = RunData.get_player_count()
    has_radius_damages.resize(nb_players)
    for i in range(nb_players): has_radius_damages[i] = false

    for player_index in range(nb_players):
        var effect_items: Array = RunData.get_player_effect(Utils.fantasy_periodic_radius_damage_hash, player_index)
        if effect_items.empty(): continue

        has_radius_damages[player_index] = true

    if !has_radius_damages.has(true): return

    var _err: int = _entity_spawner_ref.connect("players_spawned", self , "fa_on_EntitySpawner_players_spawned")

# =========================== Method =========================== #
func fa_on_EntitySpawner_players_spawned(players: Array) -> void:
    for player in players:
        var player_radius_damages: Array = RunData.get_player_effect(Utils.fantasy_periodic_radius_damage_hash, player.player_index)

        if player_radius_damages.empty(): continue

        for radius_damage in player_radius_damages:
            var base_range: int = radius_damage[0]
            var range_rate: float = radius_damage[1] / 100.0
            var scaling_stats: Array = radius_damage[2]
            var base_cooldown: int = radius_damage[3]
            var base_damage: int = radius_damage[4]
            var tracked_key: int = radius_damage[5]
            var damage_color: Color = Color(Keys.hash_to_string[radius_damage[6]])
            var hit_visual_scene: PackedScene = load(Keys.hash_to_string[radius_damage[7]])
            var can_light: bool = radius_damage[8]
            var player_effect_behaviors_node: Node = player.effect_behaviors
            var periodic_radius_damage_player_effect_behavior: UnitEffectBehavior = periodic_radius_damage_player_effect_behavior_data.scene.instance()

            player_effect_behaviors_node.add_child(periodic_radius_damage_player_effect_behavior.init(player, base_range, range_rate, scaling_stats, base_cooldown, base_damage, tracked_key, damage_color, hit_visual_scene, can_light))
