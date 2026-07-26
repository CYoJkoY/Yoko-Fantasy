extends Node2D

const SEGMENTS = 30
const GLINT_COUNT = 2

var _radius: float = 100.0
var _y_scale: float = 0.46
var _phase: float = 0.0
var _base_color: Color = Color(0.42, 0.20, 0.88, 0.18)
var _secondary_color: Color = Color(0.20, 0.72, 0.94, 0.12)
var _core_color: Color = Color(0.76, 0.86, 1.0, 0.18)
var _width: float = 4.0
var _last_radius: float = -1.0
var _last_y_scale: float = -1.0
var _last_phase_bucket: int = -1

func configure(radius: float, y_scale: float, phase: float, base_color: Color, secondary_color: Color, core_color: Color, width: float) -> void:
    _radius = max(8.0, radius)
    _y_scale = clamp(y_scale, 0.18, 1.0)
    _phase = phase
    _base_color = base_color
    _secondary_color = secondary_color
    _core_color = core_color
    _width = max(1.0, width)
    visible = true
    var phase_bucket: int = int(floor(_phase * 8.0))
    if abs(_last_radius - _radius) > 0.1 or abs(_last_y_scale - _y_scale) > 0.01 or _last_phase_bucket != phase_bucket:
        _last_radius = _radius
        _last_y_scale = _y_scale
        _last_phase_bucket = phase_bucket
        update()

func hide_visual() -> void:
    visible = false

func _draw() -> void:
    if !visible:
        return

    var rx: float = _radius
    var ry: float = _radius * _y_scale
    var base_width: float = max(1.0, _width)
    for i in range(SEGMENTS):
        var a0: float = float(i) * TAU / float(SEGMENTS)
        var a1: float = float(i + 1) * TAU / float(SEGMENTS)
        var mid: float = (a0 + a1) * 0.5
        var p0: Vector2 = Vector2(cos(a0) * rx, sin(a0) * ry)
        var p1: Vector2 = Vector2(cos(a1) * rx, sin(a1) * ry)
        var depth: float = (sin(mid) + 1.0) * 0.5
        var shimmer: float = 0.70 + sin(mid * 3.0 + _phase * 1.6) * 0.16 + sin(mid * 7.0 - _phase * 1.1) * 0.08
        var shadow_alpha: float = clamp(_base_color.a * (0.34 + depth * 0.16), 0.0, 0.12)
        var aura_alpha: float = clamp(_base_color.a * shimmer * (0.62 + depth * 0.28), 0.0, 0.24)
        var body_alpha: float = clamp(_secondary_color.a * shimmer * (0.42 + depth * 0.26), 0.0, 0.18)
        var core_gate: float = sin(mid * 5.0 - _phase * 2.2)
        var core_alpha: float = clamp(_core_color.a * max(0.0, core_gate - 0.45) * 1.55, 0.0, 0.20)

        if shadow_alpha > 0.005:
            draw_line(p0, p1, Color(_base_color.r * 0.28, _base_color.g * 0.22, _base_color.b * 0.42, shadow_alpha), base_width * 3.4, true)
        if aura_alpha > 0.005:
            draw_line(p0, p1, Color(_base_color.r, _base_color.g, _base_color.b, aura_alpha), base_width * 1.8, true)
        if body_alpha > 0.005:
            draw_line(p0, p1, Color(_secondary_color.r, _secondary_color.g, _secondary_color.b, body_alpha), base_width, true)
        if core_alpha > 0.005 and i % 2 == 0:
            draw_line(p0, p1, Color(_core_color.r, _core_color.g, _core_color.b, core_alpha), max(1.0, base_width * 0.34), true)

    for i in range(GLINT_COUNT):
        var angle: float = _phase * (0.82 + float(i) * 0.07) + float(i) * TAU / float(GLINT_COUNT)
        var point: Vector2 = Vector2(cos(angle) * rx, sin(angle) * ry)
        var pulse: float = 0.55 + sin(_phase * 2.4 + float(i) * 1.7) * 0.22
        var alpha: float = clamp(_secondary_color.a * (0.55 + pulse), 0.0, 0.18)
        if alpha > 0.005:
            draw_circle(point, base_width * (0.56 + pulse * 0.28), Color(_secondary_color.r, _secondary_color.g, _secondary_color.b, alpha))
