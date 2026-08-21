extends Node2D

var _points: Array = []
var _trail_color: Color = Color(0, 0, 0, 0)
var _secondary_color: Color = Color(0, 0, 0, 0)
var _core_color: Color = Color(0, 0, 0, 0)
var _trail_width: float = 4.0
var _aura_width: float = 10.0
var _core_width: float = 1.0
var _intensity: float = 0.0
var _quality: int = 0

func configure(points: Array, trail_color: Color, secondary_color: Color, core_color: Color, trail_width: float, aura_width: float, core_width: float, intensity: float, quality: int = 0) -> void:
    _points.clear()
    for point in points:
        _points.append(point)
    _trail_color = trail_color
    _secondary_color = secondary_color
    _core_color = core_color
    _trail_width = trail_width
    _aura_width = aura_width
    _core_width = core_width
    _intensity = clamp(intensity, 0.0, 1.35)
    _quality = quality
    visible = _points.size() >= 2 and _intensity > 0.02
    update()

func fade(delta: float) -> bool:
    if !visible:
        return false
    _intensity = max(0.0, _intensity - delta * 4.2)
    if _intensity <= 0.02:
        hide_visual()
        return false
    update()
    return true

func hide_visual() -> void:
    visible = false
    _points.clear()
    _intensity = 0.0

func _draw() -> void:
    if _points.size() < 2 or _intensity <= 0.0:
        return
    var segment_count: int = _points.size() - 1
    for i in range(segment_count):
        var start: Vector2 = _points[i]
        var end: Vector2 = _points[i + 1]
        var pct: float = float(i + 1) / float(max(segment_count, 1))
        var shaped: float = pow(pct, 1.55)
        var head_softness: float = clamp((pct - 0.18) / 0.82, 0.0, 1.0)
        var shadow_color: Color = Color(_trail_color.r * 0.40, _trail_color.g * 0.32, _trail_color.b * 0.58, _trail_color.a * _intensity * shaped * 0.34)
        var aura_color: Color = Color(_trail_color.r, _trail_color.g, _trail_color.b, _trail_color.a * _intensity * shaped * 0.66)
        var body_color: Color = Color(_secondary_color.r, _secondary_color.g, _secondary_color.b, _secondary_color.a * _intensity * (0.18 + shaped * 0.82))
        var core_color: Color = Color(_core_color.r, _core_color.g, _core_color.b, _core_color.a * _intensity * shaped * 0.56)
        var aura_width: float = max(1.0, _aura_width * (0.16 + head_softness * 1.04))
        var body_width: float = max(1.0, _trail_width * (0.22 + head_softness * 1.12))
        var core_width: float = max(1.0, _core_width * (0.45 + head_softness * 0.62))
        if _quality == 0 and shadow_color.a > 0.01:
            draw_line(start, end, shadow_color, aura_width * 1.22, true)
        if _quality <= 1 and aura_color.a > 0.01:
            draw_line(start, end, aura_color, aura_width, true)
        if body_color.a > 0.01:
            draw_line(start, end, body_color, body_width, true)
        if _quality == 0 and core_color.a > 0.01 and i >= segment_count - 2:
            draw_line(start, end, core_color, core_width, true)
        if _quality == 0 and i == segment_count - 1 and aura_color.a > 0.01:
            draw_circle(end, max(1.0, body_width * 0.42), Color(body_color.r, body_color.g, body_color.b, body_color.a * 0.72))
