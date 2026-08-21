extends Node2D

const SEGMENTS = 32
const GLINT_COUNT = 2

var _radius: float = 100.0
var _y_scale: float = 0.46
var _phase: float = 0.0
var _base_color: Color = Color(0.42, 0.20, 0.88, 0.18)
var _secondary_color: Color = Color(0.20, 0.72, 0.94, 0.12)
var _core_color: Color = Color(0.76, 0.86, 1.0, 0.18)
var _width: float = 4.0
var _quality: int = 0
var _points: PoolVector2Array = PoolVector2Array()
var _last_radius: float = -1.0
var _last_y_scale: float = -1.0
var _last_phase_bucket: int = -1
var _last_quality: int = -1

func configure(radius: float, y_scale: float, phase: float, base_color: Color, secondary_color: Color, core_color: Color, width: float, quality: int = 0) -> void:
    _radius = max(8.0, radius)
    _y_scale = clamp(y_scale, 0.18, 1.0)
    _phase = phase
    _base_color = base_color
    _secondary_color = secondary_color
    _core_color = core_color
    _width = max(1.0, width)
    _quality = quality
    visible = quality < 3

    var geometry_changed: bool = abs(_last_radius - _radius) > 0.1 or abs(_last_y_scale - _y_scale) > 0.01
    var phase_bucket: int = int(floor(_phase * 8.0))
    var animate_glints: bool = _quality == 0 and _last_phase_bucket != phase_bucket
    if geometry_changed:
        _rebuild_points()
    if geometry_changed or animate_glints or _last_quality != _quality:
        _last_radius = _radius
        _last_y_scale = _y_scale
        _last_phase_bucket = phase_bucket
        _last_quality = _quality
        update()

func hide_visual() -> void:
    visible = false

func _rebuild_points() -> void:
    _points.resize(SEGMENTS + 1)
    for i in range(SEGMENTS + 1):
        var angle: float = float(i) * TAU / float(SEGMENTS)
        _points[i] = Vector2(cos(angle) * _radius, sin(angle) * _radius * _y_scale)

func _draw() -> void:
    if !visible or _points.size() < 2:
        return

    var base_width: float = max(1.0, _width)
    if _quality == 0:
        var shadow_color: Color = Color(_base_color.r * 0.28, _base_color.g * 0.22, _base_color.b * 0.42, min(_base_color.a * 0.42, 0.12))
        draw_polyline(_points, shadow_color, base_width * 3.4, true)
    if _quality <= 1:
        draw_polyline(_points, Color(_base_color.r, _base_color.g, _base_color.b, min(_base_color.a * 0.78, 0.24)), base_width * 1.8, true)
    draw_polyline(_points, Color(_secondary_color.r, _secondary_color.g, _secondary_color.b, min(_secondary_color.a * 0.62, 0.18)), base_width, true)

    if _quality == 0:
        for i in range(GLINT_COUNT):
            var angle: float = _phase * (0.82 + float(i) * 0.07) + float(i) * TAU / float(GLINT_COUNT)
            var point: Vector2 = Vector2(cos(angle) * _radius, sin(angle) * _radius * _y_scale)
            var pulse: float = 0.55 + sin(_phase * 2.4 + float(i) * 1.7) * 0.22
            var alpha: float = clamp(_core_color.a * (0.55 + pulse), 0.0, 0.18)
            if alpha > 0.005:
                draw_circle(point, base_width * (0.56 + pulse * 0.28), Color(_core_color.r, _core_color.g, _core_color.b, alpha))
