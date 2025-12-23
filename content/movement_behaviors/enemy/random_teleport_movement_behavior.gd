extends MovementBehavior

export (float) var teleport_cooldown: float = 3.0
export (float) var teleport_distance: float = 700.0
export (float) var teleport_duration: float = 0.1
export (bool) var base_on_centerx: bool = true
export (bool) var base_on_centery: bool = true

var _current_target: Vector2 = Vector2.ZERO
var _last_teleport_time: float = 0.0
var _is_teleporting: bool = false
var _original_speed: float

func get_movement() -> Vector2:
    var current_time = Time.get_ticks_msec() / 1000.0
    
    match _is_teleporting:
        true:
            if (current_time - _last_teleport_time) >= teleport_duration:
                if _original_speed != null:
                    _parent.current_stats.speed = _original_speed
                _is_teleporting = false
                _current_target = Vector2.ZERO
        false:
            if (current_time - _last_teleport_time) >= teleport_cooldown:
                _trigger_teleport()
                _last_teleport_time = current_time
                _is_teleporting = true

    if _current_target != Vector2.ZERO:
        _original_speed = _parent.current_stats.speed
        _parent.current_stats.speed = Utils.LARGE_NUMBER
        return _current_target - _parent.global_position

    return Vector2.ZERO

func _trigger_teleport():
    var angle: float = randf() * TAU
    var direction: Vector2 = Vector2(cos(angle), sin(angle))
    var base_position: Vector2 = _parent.global_position
    
    if base_on_centerx or base_on_centery:
        var map_center: Vector2 = ZoneService.get_map_center()
        
        if base_on_centerx:
            base_position.x = map_center.x
        if base_on_centery:
            base_position.y = map_center.y
    
    _current_target = base_position + direction * teleport_distance
    _current_target.x = clamp(_current_target.x, 0, ZoneService.current_zone_max_position.x)
    _current_target.y = clamp(_current_target.y, 0, ZoneService.current_zone_max_position.y)
