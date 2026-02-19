extends MovementBehavior

export(float) var wave_period = 2.0
export(float) var wave_amplitude = 1000.0

var time: float = 0.0

# =========================== Extension =========================== #
func get_movement() -> Vector2:
    time += _parent.get_physics_process_delta_time()
    var to_target: Vector2 = (get_target_position() - _parent.global_position).normalized()
    var sway_direction: Vector2 = Vector2(to_target.y, -to_target.x)
    var sway_offset: Vector2 = sway_direction * sin(time * 2.0 * PI / wave_period) * wave_amplitude
    var forward_movement: Vector2 = to_target * _parent.stats.speed * 2.0
    var final_movement: Vector2 = forward_movement + sway_offset
    
    return final_movement

func get_target_position():
    if !is_instance_valid(_parent.current_target): return global_position
    return _parent.current_target.global_position
