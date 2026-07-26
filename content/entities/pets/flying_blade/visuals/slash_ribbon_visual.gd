extends Node2D

const FlyingBladeMotion = preload("res://mods-unpacked/Yoko-Fantasy/content/entities/pets/flying_blade/motion_math.gd")
const SEGMENTS = 8

var _aura_polygon: PoolVector2Array = PoolVector2Array()
var _body_polygon: PoolVector2Array = PoolVector2Array()
var _aura_color: Color = Color(0, 0, 0, 0)
var _body_color: Color = Color(0, 0, 0, 0)
var _head_position: Vector2 = Vector2.ZERO
var _head_radius: float = 0.0
var _head_color: Color = Color(0, 0, 0, 0)
var _left_aura: Array = []
var _right_aura: Array = []
var _left_body: Array = []
var _right_body: Array = []

func configure(start: Vector2, control: Vector2, end: Vector2, fallback_direction: Vector2, curve_side: float, progress: float, windup: bool, visibility: float, slash_width: float, slash_color: Color, ticks: float, phase: float) -> void:
    var head_pct: float = clamp(0.24 + progress * 0.84, 0.18, 1.0)
    var tail_pct: float = clamp(head_pct - (0.50 + progress * 0.12), 0.0, 0.78)
    if windup:
        head_pct = 0.46
        tail_pct = 0.08

    var flash: float = 0.88 + sin(phase * 8.0 + ticks * 1.7) * 0.12
    var volume: float = clamp(slash_width / 12.0, 0.70, 1.55)
    _left_aura.clear()
    _right_aura.clear()
    _left_body.clear()
    _right_body.clear()

    for i in range(SEGMENTS):
        var local_pct: float = float(i) / float(max(SEGMENTS - 1, 1))
        var path_pct: float = lerp(tail_pct, head_pct, local_pct)
        var point: Vector2 = FlyingBladeMotion.bezier2(start, control, end, path_pct)
        var tangent: Vector2 = FlyingBladeMotion.bezier2_tangent(start, control, end, path_pct)
        if tangent.length_squared() <= 0.1:
            tangent = fallback_direction
        if tangent.length_squared() <= 0.1:
            tangent = Vector2.RIGHT
        tangent = tangent.normalized()

        var side: Vector2 = Vector2(-tangent.y, tangent.x) * curve_side
        var head_weight: float = FlyingBladeMotion.ease_out_cubic(local_pct)
        var tail_weight: float = clamp(local_pct * 3.2, 0.0, 1.0)
        var tip_fade: float = clamp((1.06 - local_pct) * 3.0, 0.0, 1.0)
        var mass: float = tail_weight * tip_fade * (0.42 + head_weight * 0.74)
        var ripple: float = sin(float(i) * 1.73 + ticks * 0.72 + phase) * 0.08
        var forward: Vector2 = tangent * (head_weight - 0.45) * slash_width * 0.12
        var center: Vector2 = point + side * slash_width * (0.12 + mass * 0.26 + ripple * 0.12) + forward
        var aura_half: float = slash_width * (0.42 + mass * 1.25 + ripple) * volume
        var body_half: float = slash_width * (0.18 + mass * 0.92 + ripple * 0.55) * volume

        _left_aura.append(center + side * aura_half)
        _right_aura.push_front(center - side * aura_half * (0.48 + head_weight * 0.10))
        _left_body.append(center + side * body_half)
        _right_body.push_front(center - side * body_half * (0.44 + head_weight * 0.08))
        if i == SEGMENTS - 1:
            _head_position = center + side * body_half * 0.08
            _head_radius = max(2.0, body_half * 0.50)

    _aura_polygon.resize(_left_aura.size() + _right_aura.size())
    _body_polygon.resize(_left_body.size() + _right_body.size())
    var point_index: int = 0
    for point in _left_aura:
        _aura_polygon[point_index] = point
        point_index += 1
    for point in _right_aura:
        _aura_polygon[point_index] = point
        point_index += 1
    point_index = 0
    for point in _left_body:
        _body_polygon[point_index] = point
        point_index += 1
    for point in _right_body:
        _body_polygon[point_index] = point
        point_index += 1
    _aura_color = Color(slash_color.r, slash_color.g, slash_color.b, min(0.50, slash_color.a * 0.78 * visibility * flash))
    _body_color = Color(slash_color.r, slash_color.g, slash_color.b, min(0.76, slash_color.a * 1.52 * visibility * flash))
    _head_color = Color(slash_color.r, slash_color.g, slash_color.b, min(0.64, slash_color.a * 1.28 * visibility * flash))
    visible = true
    update()

func fade(delta: float) -> bool:
    if !visible:
        return false
    _aura_color.a = max(0.0, _aura_color.a - delta * 2.8)
    _body_color.a = max(0.0, _body_color.a - delta * 3.4)
    _head_color.a = max(0.0, _head_color.a - delta * 3.8)
    if _aura_color.a <= 0.01 and _body_color.a <= 0.01 and _head_color.a <= 0.01:
        hide_visual()
        return false
    update()
    return true

func hide_visual() -> void:
    visible = false

func _draw() -> void:
    if _aura_polygon.size() >= 3 and _aura_color.a > 0.0:
        draw_colored_polygon(_aura_polygon, _aura_color)
    if _body_polygon.size() >= 3 and _body_color.a > 0.0:
        draw_colored_polygon(_body_polygon, _body_color)
    if _head_radius > 0.0 and _head_color.a > 0.0:
        draw_circle(_head_position, _head_radius, _head_color)
