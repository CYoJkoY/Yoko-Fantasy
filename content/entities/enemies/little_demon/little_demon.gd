extends Enemy

# =========================== Extension =========================== #
func init(zone_min_pos: Vector2, zone_max_pos: Vector2, p_players_ref: Array = [], entity_spawner_ref = null) -> void:
    .init(zone_min_pos, zone_max_pos, p_players_ref, entity_spawner_ref)
    var map_mult: float = ZoneService.current_zone_max_position.x / 1920.0
    _attack_behavior.spawn_radius *= map_mult
