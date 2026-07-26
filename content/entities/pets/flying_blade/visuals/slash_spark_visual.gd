extends Node2D

var velocity: Vector2 = Vector2.ZERO
var angular_velocity: float = 0.0
var age: float = 0.0
var lifetime: float = 0.16
var color: Color = Color.white
var _base_color: Color = Color.white
var length: float = 24.0
var width: float = 3.0
var _points: PoolVector2Array = PoolVector2Array()

func ignite(p_position: Vector2, direction: Vector2, p_color: Color, p_lifetime: float, p_length: float, p_width: float, p_velocity: Vector2, p_angular_velocity: float) -> void:
    position = p_position
    rotation = direction.angle()
    _base_color = p_color
    color = p_color
    lifetime = max(0.01, p_lifetime)
    length = p_length
    width = p_width
    velocity = p_velocity
    angular_velocity = p_angular_velocity
    age = 0.0
    visible = true
    _refresh_points(1.0)
    update()

func tick(delta: float) -> bool:
    if !visible:
        return false
    age += delta
    var pct: float = age / lifetime
    if pct >= 1.0:
        hide_visual()
        return false
    position += velocity * delta
    rotation += angular_velocity * delta
    var remaining: float = 1.0 - pct
    _refresh_points(remaining)
    update()
    return true

func hide_visual() -> void:
    visible = false

func _draw() -> void:
    if _points.size() < 3 or color.a <= 0.0:
        return
    draw_colored_polygon(_points, color)

func _refresh_points(strength: float) -> void:
    var half_len: float = length * strength * 0.5
    var half_width: float = width * max(0.15, strength)
    var c: Color = _base_color
    c.a = _base_color.a * strength * strength
    color = c
    _points.resize(5)
    _points[0] = Vector2(-half_len, -half_width * 0.32)
    _points[1] = Vector2(half_len * 0.75, -half_width)
    _points[2] = Vector2(half_len, 0.0)
    _points[3] = Vector2(half_len * 0.55, half_width)
    _points[4] = Vector2(-half_len, half_width * 0.26)
