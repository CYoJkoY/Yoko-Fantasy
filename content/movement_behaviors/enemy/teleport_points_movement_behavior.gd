extends MovementBehavior

signal teleport_point_reached()

export(float) var teleport_interval = 0.5
export(bool) var order_teleport = true

var teleport_points: Array = []
var teleport_point_index: int = 0
var time: float = 0.0

# =========================== Extension =========================== #
func _ready() -> void:
    teleport_point_index = Utils.randi_range(0, teleport_points.size() - 1)

func get_movement() -> Vector2:
    time += _parent.get_physics_process_delta_time()
    if time < teleport_interval: return Vector2.ZERO

    time = 0.0
    var teleport_point: Vector2 = _fantasy_get_teleport_point()
    _parent.global_position = teleport_point
    emit_signal("teleport_point_reached")
    return Vector2.ZERO

# =========================== Custom =========================== #
func _fantasy_get_teleport_point():
    var target_position: Vector2 = Vector2.ZERO
    if order_teleport:
        target_position = teleport_points[teleport_point_index]
        teleport_point_index = (teleport_point_index + 1) % teleport_points.size()
    else: target_position = Utils.get_rand_element(teleport_points)
    return target_position
