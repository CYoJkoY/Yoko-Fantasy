extends MovementBehavior

export(float) var check_interval: float = 1.0
export(float) var center_tolerance: float = 50.0

var _cooldown: float = 0.0
var _is_teleporting: bool = false
var _target_position: Vector2 = Vector2.ZERO

# =========================== Extension =========================== #
func get_movement() -> Vector2:
    _cooldown -= _parent.get_physics_process_delta_time()
    if _is_teleporting or _cooldown > 0: return Vector2.ZERO

    fa_check_and_teleport_to_center()

    return Vector2.ZERO

# =========================== Method =========================== #
func fa_check_and_teleport_to_center():
    _is_teleporting = true
    _cooldown = check_interval
    _parent.global_positon = ZoneService.get_map_center()
    _is_teleporting = false
