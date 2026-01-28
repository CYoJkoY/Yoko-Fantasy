extends MovementBehavior

export (float) var check_interval: float = 1.0
export (float) var teleport_duration: float = 0.1
export (float) var center_tolerance: float = 50.0  

var _last_check_time: float = 0.0
var _is_teleporting: bool = false
var _original_speed: float = -1.0
var _target_position: Vector2 = Vector2.ZERO

func get_movement() -> Vector2:
    var current_time = Time.get_ticks_msec() / 1000.0
    
    match _is_teleporting:
        true:
            if (current_time - _last_check_time) >= teleport_duration:
                _parent.current_stats.speed = _original_speed
                _is_teleporting = false
                _target_position = Vector2.ZERO
        false:
            if (current_time - _last_check_time) >= check_interval:
                _check_and_teleport_to_center()
                _last_check_time = current_time

    if _target_position != Vector2.ZERO:
        if _original_speed == -1.0:
            _original_speed = _parent.current_stats.speed
        _parent.current_stats.speed = Utils.LARGE_NUMBER
        return _target_position - _parent.global_position

    return Vector2.ZERO

func _check_and_teleport_to_center():
    var map_center: Vector2 = ZoneService.get_map_center()
    var distance_to_center: float = _parent.global_position.distance_to(map_center)
    
    if distance_to_center > center_tolerance:
        _target_position = map_center
        _is_teleporting = true
