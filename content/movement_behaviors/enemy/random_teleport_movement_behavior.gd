extends MovementBehavior

export(float) var teleport_cooldown: float = 3.0
export(float) var teleport_distance: float = 700.0
export(bool) var base_on_centerx: bool = true
export(bool) var base_on_centery: bool = true

var _current_target: Vector2 = Vector2.ZERO
var _cooldown: float = 0.0
var _is_teleporting: bool = false

# =========================== Extension =========================== #
func get_movement() -> Vector2:
    _cooldown -= _parent.get_physics_process_delta_time()
    
    if _is_teleporting or _cooldown > 0: return Vector2.ZERO

    fa_trigger_teleport()

    return Vector2.ZERO

# =========================== Method =========================== #
func fa_trigger_teleport():
    _is_teleporting = true
    _cooldown = teleport_cooldown
    var angle: float = randf() * TAU
    var direction: Vector2 = Vector2(cos(angle), sin(angle))
    var base_position: Vector2 = _parent.global_position

    match [base_on_centerx, base_on_centery]:
        [true, true]: base_position = ZoneService.get_map_center()
        [true, false]: base_position.x = ZoneService.get_map_center().x
        [false, true]: base_position.y = ZoneService.get_map_center().y
    
    _current_target = base_position + direction * teleport_distance
    _current_target.x = clamp(_current_target.x, 0, ZoneService.current_zone_max_position.x)
    _current_target.y = clamp(_current_target.y, 0, ZoneService.current_zone_max_position.y)

    _parent.global_position = _current_target
    _is_teleporting = false
