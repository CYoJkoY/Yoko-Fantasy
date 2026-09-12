extends Effect

export(PackedScene) var enemy_scene
export(String) var enemy_name_key = ""
export(float, 0.1, 3600.0) var interval = 1.0
export(bool) var spawn_edge_of_map = true

static func get_id() -> String:
    return "fantasy_spawn_enemies_per_interval"

func apply(player_index: int) -> void:
    RunData.get_player_effect(key_hash, player_index).append([value, interval, enemy_scene.resource_path, spawn_edge_of_map])

func unapply(player_index: int) -> void:
    RunData.get_player_effect(key_hash, player_index).erase([value, interval, enemy_scene.resource_path, spawn_edge_of_map])

func get_args(_player_index: int) -> Array:
    var location_key: String = "FANTASY_ENEMY_SPAWN_EDGE" if spawn_edge_of_map else "FANTASY_ENEMY_SPAWN_ANYWHERE"
    return [str(value), str(interval), tr(enemy_name_key), tr(location_key)]

func serialize() -> Dictionary:
    var serialized: Dictionary = .serialize()
    serialized.enemy_scene = enemy_scene.resource_path
    serialized.enemy_name_key = enemy_name_key
    serialized.interval = interval
    serialized.spawn_edge_of_map = spawn_edge_of_map
    return serialized

func deserialize_and_merge(serialized: Dictionary) -> void:
    .deserialize_and_merge(serialized)
    enemy_scene = load(serialized.enemy_scene) as PackedScene
    enemy_name_key = serialized.enemy_name_key
    interval = serialized.interval
    spawn_edge_of_map = serialized.spawn_edge_of_map
