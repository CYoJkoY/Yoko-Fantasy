extends Enemy

export (float) var wave_period = 2.0
export (float) var wave_amplitude = 1000.0

var time: float = 0.0

func _physics_process(delta) -> void:
	time += delta

func get_movement() -> Vector2:
	if not current_target: return Vector2.ZERO
	
	var to_target: Vector2 = (current_target.global_position - global_position).normalized()
	var sway_direction: Vector2 = Vector2(to_target.y, -to_target.x)
	var sway_offset: Vector2 = sway_direction * sin(time * 2.0 * PI / wave_period) * wave_amplitude
	var forward_movement: Vector2 = to_target * stats.speed * 2.0
	var final_movement: Vector2 = forward_movement + sway_offset
	
	return final_movement
