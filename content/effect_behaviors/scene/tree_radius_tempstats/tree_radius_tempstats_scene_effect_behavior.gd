extends SceneEffectBehavior

export(Resource) var tree_radius_tempstats_neutral_effect_behavior_data

var tempstats: Array = []

# =========================== Extension =========================== #
func _ready() -> void:
    var nb_players: int = RunData.get_player_count()
    tempstats.resize(nb_players)
    for i in range(nb_players): tempstats[i] = []

    var has_effect: bool = false
    for player_index in range(nb_players):
        tempstats[player_index] = RunData.get_player_effect(Utils.fantasy_tree_radius_tempstats_hash, player_index)
        if tempstats[player_index].empty(): continue

        has_effect = true

    if !has_effect: return

    var _err: int = _entity_spawner_ref.connect("neutral_respawned", self , "fa_on_EntitySpawner_neutral_respawned")
    _err = _entity_spawner_ref.connect("enemy_respawned", self , "fa_on_EntitySpawner_neutral_respawned")

# =========================== Method =========================== #
func fa_on_EntitySpawner_neutral_respawned(neutral: Unit) -> void:
    if !(Utils.ncl_get_validate_node_name(neutral.name) == "Tree" or \
         neutral.get("enemy_id_hash") in Utils.plant_enemies_ids): return

    for player_index in range(tempstats.size()):
        var player_tempstats: Array = tempstats[player_index]
        if player_tempstats.empty(): continue

        for temp_stat in player_tempstats:
            var stat: int = temp_stat[0]
            var stat_num: int = temp_stat[1]
            var radius: int = temp_stat[2]
            var range_rate: float = temp_stat[3]
            var tree_effect_behaviors_node: Node = neutral.effect_behaviors
            var tree_effect_behaviors: Array = tree_effect_behaviors_node.get_children()
            var tree_radius_tempstats_neutral_effect_behavior: Node = tree_radius_tempstats_neutral_effect_behavior_data.scene.instance()

            if tree_effect_behaviors.empty():
                tree_effect_behaviors_node.add_child(tree_radius_tempstats_neutral_effect_behavior.init(neutral, stat, stat_num, radius, range_rate, player_index))
                continue

            for effect_behavior in tree_effect_behaviors:
                if effect_behavior.get("radius") == radius: effect_behavior.fa_add_temp_stat(stat, stat_num, player_index)
                else: tree_effect_behaviors_node.add_child(tree_radius_tempstats_neutral_effect_behavior.init(neutral, stat, stat_num, radius, range_rate, player_index))
