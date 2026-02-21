extends MovementBehavior

export(float) var check_interval: float = 1.0
export(float) var center_tolerance: float = 25.0

onready var _center_position: Vector2 = ZoneService.get_map_center()

var _cooldown: float = 0.0
var _is_teleporting: bool = false

# =========================== Extension =========================== #
func _ready() -> void:
    center_tolerance = pow(center_tolerance, 2)

func get_movement() -> Vector2:
    _cooldown -= _parent.get_physics_process_delta_time()
    if _is_teleporting or _cooldown > 0: return Vector2.ZERO

    fa_check_and_teleport_to_center()

    return Vector2.ZERO

# =========================== Method =========================== #
func fa_check_and_teleport_to_center():
    _is_teleporting = true
    if _parent.global_position.distance_squared_to(_center_position) > center_tolerance: _parent.global_position = _center_position
    _cooldown = check_interval
    _is_teleporting = false
