extends Node2D

var _aura_polygon: PoolVector2Array = PoolVector2Array()
var _body_polygon: PoolVector2Array = PoolVector2Array()
var _core_points: PoolVector2Array = PoolVector2Array()
var _aura_color: Color = Color(0, 0, 0, 0)
var _body_color: Color = Color(0, 0, 0, 0)
var _core_color: Color = Color(0, 0, 0, 0)
var _core_width: float = 1.0

func configure(start: Vector2, end: Vector2, fallback_direction: Vector2, progress: float, visibility: float, body_width: float, aura_width: float, core_width: float, trail_color: Color, secondary_color: Color, core_color: Color, ticks: float, phase: float) -> void:
    var direction: Vector2 = end - start
    if direction.length_squared() <= 0.1:
        direction = fallback_direction
    if direction.length_squared() <= 0.1:
        direction = Vector2.RIGHT
    direction = direction.normalized()

    var travel: float = clamp(progress, 0.0, 1.0)
    var head: Vector2 = start.linear_interpolate(end, clamp(travel * 1.06, 0.0, 1.0))
    var tail: Vector2 = start.linear_interpolate(end, clamp(travel - 0.34, 0.0, 1.0))
    var side: Vector2 = Vector2(-direction.y, direction.x)
    var pulse: float = 0.86 + sin(ticks * 2.4 + phase) * 0.14
    var thrust_mass: float = sin(travel * PI)
    var body_half: float = max(1.0, body_width * (0.24 + thrust_mass * 0.56) * pulse)
    var aura_half: float = max(body_half * 1.42, aura_width * (0.24 + thrust_mass * 0.62) * pulse)
    var tail_half: float = max(0.8, body_half * 0.24)
    var visible_length: float = max((head - tail).dot(direction), max(12.0, body_width * 1.8))
    var visual_tail: Vector2 = head - direction * visible_length
    var shoulder_distance: float = min(visible_length * 0.45, max(6.0, body_width * 1.25))
    var shoulder: Vector2 = head - direction * shoulder_distance
    var waist: Vector2 = visual_tail.linear_interpolate(shoulder, 0.62)

    _aura_polygon.resize(7)
    _aura_polygon[0] = visual_tail - side * tail_half * 1.75
    _aura_polygon[1] = waist - side * aura_half * 0.82
    _aura_polygon[2] = shoulder - side * aura_half
    _aura_polygon[3] = head + direction * body_width * 0.48
    _aura_polygon[4] = shoulder + side * aura_half
    _aura_polygon[5] = waist + side * aura_half * 0.82
    _aura_polygon[6] = visual_tail + side * tail_half * 1.75

    _body_polygon.resize(7)
    _body_polygon[0] = visual_tail - side * tail_half
    _body_polygon[1] = waist - side * body_half * 0.72
    _body_polygon[2] = shoulder - side * body_half
    _body_polygon[3] = head + direction * body_width * 0.30
    _body_polygon[4] = shoulder + side * body_half
    _body_polygon[5] = waist + side * body_half * 0.72
    _body_polygon[6] = visual_tail + side * tail_half

    _core_points.resize(2)
    _core_points[0] = visual_tail + direction * body_width * 0.55
    _core_points[1] = head + direction * body_width * 0.18

    var flash: float = 0.90 + sin(phase * 5.0 + ticks * 1.8) * 0.10
    _aura_color = Color(trail_color.r, trail_color.g, trail_color.b, min(0.38, trail_color.a * 1.10 * visibility * flash))
    _body_color = Color(secondary_color.r, secondary_color.g, secondary_color.b, min(0.52, secondary_color.a * 1.80 * visibility * flash))
    _core_color = Color(core_color.r, core_color.g, core_color.b, min(0.30, core_color.a * 1.18 * visibility * flash))
    _core_width = max(1.0, core_width * 0.85)
    visible = true
    update()

func fade(delta: float) -> bool:
    if !visible:
        return false
    _aura_color.a = max(0.0, _aura_color.a - delta * 3.0)
    _body_color.a = max(0.0, _body_color.a - delta * 3.8)
    _core_color.a = max(0.0, _core_color.a - delta * 4.6)
    if _aura_color.a <= 0.01 and _body_color.a <= 0.01 and _core_color.a <= 0.01:
        hide_visual()
        return false
    update()
    return true

func hide_visual() -> void:
    visible = false

func _draw() -> void:
    if _aura_color.a > 0.0 and _has_drawable_area(_aura_polygon):
        draw_colored_polygon(_aura_polygon, _aura_color)
    if _body_color.a > 0.0 and _has_drawable_area(_body_polygon):
        draw_colored_polygon(_body_polygon, _body_color)
    if _core_points.size() >= 2 and _core_color.a > 0.0:
        draw_polyline(_core_points, _core_color, _core_width, true)

func _has_drawable_area(points: PoolVector2Array) -> bool:
    if points.size() < 3:
        return false
    var twice_area: float = 0.0
    for index in range(points.size()):
        var next_index: int = (index + 1) % points.size()
        twice_area += points[index].cross(points[next_index])
    return abs(twice_area) > 1.0
