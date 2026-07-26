extends Node2D

var _points: PoolVector2Array = PoolVector2Array()
var _inner_points: PoolVector2Array = PoolVector2Array()
var _color: Color = Color.white
var _inner_color: Color = Color.white
var _base_color: Color = Color.white
var _age: float = 0.0
var _lifetime: float = 0.08
var _radius: float = 20.0

func flash(p_position: Vector2, direction: Vector2, color: Color, radius: float, lifetime: float) -> void:
    position = p_position
    rotation = direction.angle()
    _base_color = color
    _color = color
    _radius = radius
    _lifetime = max(0.01, lifetime)
    _age = 0.0
    visible = true
    _refresh(1.0)
    update()

func tick(delta: float) -> bool:
    if !visible:
        return false
    _age += delta
    var pct: float = _age / _lifetime
    if pct >= 1.0:
        hide_visual()
        return false
    _refresh(1.0 - pct)
    update()
    return true

func hide_visual() -> void:
    visible = false

func _draw() -> void:
    if _points.size() >= 3 and _color.a > 0.0:
        draw_colored_polygon(_points, _color)
    if _inner_points.size() >= 3 and _inner_color.a > 0.0:
        draw_colored_polygon(_inner_points, _inner_color)

func _refresh(strength: float) -> void:
    var radius: float = _radius * (0.35 + strength * 0.65)
    _color = _base_color
    _color.a = _base_color.a * strength * 0.82
    _inner_color = Color(_base_color.r, _base_color.g, _base_color.b, _base_color.a * strength)
    _points.resize(6)
    _points[0] = Vector2(radius * 1.10, 0.0)
    _points[1] = Vector2(radius * 0.36, radius * 0.28)
    _points[2] = Vector2(-radius * 0.46, radius * 0.18)
    _points[3] = Vector2(-radius * 0.82, 0.0)
    _points[4] = Vector2(-radius * 0.46, -radius * 0.18)
    _points[5] = Vector2(radius * 0.36, -radius * 0.28)
    _inner_points.resize(6)
    _inner_points[0] = Vector2(radius * 0.72, 0.0)
    _inner_points[1] = Vector2(radius * 0.16, radius * 0.12)
    _inner_points[2] = Vector2(-radius * 0.24, radius * 0.06)
    _inner_points[3] = Vector2(-radius * 0.42, 0.0)
    _inner_points[4] = Vector2(-radius * 0.24, -radius * 0.06)
    _inner_points[5] = Vector2(radius * 0.16, -radius * 0.12)
