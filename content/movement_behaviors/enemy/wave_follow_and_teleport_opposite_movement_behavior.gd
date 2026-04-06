extends MovementBehavior

signal teleport_point_reached()

export(float) var wave_period = 2.0
export(float) var wave_amplitude = 1000.0
export(float) var teleport_distance = 100.0
export(float) var teleport_offset = 400.0

var time: float = 0.0

# =========================== Extension =========================== #
func get_movement() -> Vector2:
    time += _parent.get_physics_process_delta_time()
    var target_position: Vector2 = get_target_position()
    var distance: float = target_position.distance_squared_to(_parent.global_position)
    var base_vec: Vector2 = target_position - _parent.global_position
    var to_target: Vector2 = base_vec.normalized()
    if distance <= teleport_distance * teleport_distance:
        var teleport_position: Vector2 = target_position + to_target * (teleport_distance + teleport_offset)
        teleport_position.x = clamp(teleport_position.x, 0, ZoneService.current_zone_max_position.x)
        teleport_position.y = clamp(teleport_position.y, 0, ZoneService.current_zone_max_position.y)
        _parent.global_position = teleport_position
        emit_signal("teleport_point_reached")
        return Vector2.ZERO

    var sway_direction: Vector2 = Vector2(to_target.y, -to_target.x)
    var sway_offset: Vector2 = sway_direction * sin(time * 2.0 * PI / wave_period) * wave_amplitude
    var forward_movement: Vector2 = to_target * _parent.stats.speed * 2.0
    var final_movement: Vector2 = forward_movement + sway_offset
    return final_movement

func get_target_position():
    if !is_instance_valid(_parent.current_target): return global_position
    return _parent.current_target.global_position
