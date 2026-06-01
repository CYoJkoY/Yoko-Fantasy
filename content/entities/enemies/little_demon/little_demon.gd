extends Enemy

const FANTASY_PROJECTILE_OFFSCREEN_MARGIN: float = 160.0

# =========================== Extension =========================== #
func init(zone_min_pos: Vector2, zone_max_pos: Vector2, p_players_ref: Array = [], entity_spawner_ref = null) -> void:
    .init(zone_min_pos, zone_max_pos, p_players_ref, entity_spawner_ref)
    _fantasy_update_spawn_radius()

func respawn() -> void:
    .respawn()
    _fantasy_update_spawn_radius()

# =========================== Custom =========================== #
func _fantasy_update_spawn_radius() -> void:
    var half_map_width: float = ZoneService.current_zone_max_position.x / 2.0
    _attack_behavior.spawn_radius = int(half_map_width + FANTASY_PROJECTILE_OFFSCREEN_MARGIN)
