extends Node2D

const TEXTURE_TRAIL = preload("res://mods-unpacked/Yoko-Fantasy/content/entities/pets/flying_blade/visuals/textures/trail_soft_gradient.webp")

var _line_aura: Line2D = null
var _line_core: Line2D = null
var _material: CanvasItemMaterial = null
var _aura_gradient: Gradient = null
var _core_gradient: Gradient = null
var _points: PoolVector2Array = PoolVector2Array()
var _aura_colors: PoolColorArray = PoolColorArray()
var _core_colors: PoolColorArray = PoolColorArray()

var _intensity: float = 0.0
var _quality: int = 0

func _init() -> void:
    _material = CanvasItemMaterial.new()
    _material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
    material = _material
    _aura_gradient = Gradient.new()
    _aura_gradient.offsets = PoolRealArray([0.0, 0.45, 1.0])
    _core_gradient = Gradient.new()
    _core_gradient.offsets = PoolRealArray([0.0, 1.0])

    _line_aura = Line2D.new()
    _line_aura.name = "AuraTrail"
    _line_aura.texture = TEXTURE_TRAIL
    _line_aura.texture_mode = Line2D.LINE_TEXTURE_STRETCH
    _line_aura.joint_mode = Line2D.LINE_JOINT_ROUND
    _line_aura.begin_cap_mode = Line2D.LINE_CAP_ROUND
    _line_aura.end_cap_mode = Line2D.LINE_CAP_ROUND
    _line_aura.material = _material
    _line_aura.set_as_toplevel(true)
    _line_aura.z_as_relative = false
    _line_aura.z_index = 6
    _line_aura.gradient = _aura_gradient
    add_child(_line_aura)

    _line_core = Line2D.new()
    _line_core.name = "CoreTrail"
    _line_core.texture = TEXTURE_TRAIL
    _line_core.texture_mode = Line2D.LINE_TEXTURE_STRETCH
    _line_core.joint_mode = Line2D.LINE_JOINT_ROUND
    _line_core.begin_cap_mode = Line2D.LINE_CAP_ROUND
    _line_core.end_cap_mode = Line2D.LINE_CAP_ROUND
    _line_core.material = _material
    _line_core.set_as_toplevel(true)
    _line_core.z_as_relative = false
    _line_core.z_index = 7
    _line_core.gradient = _core_gradient
    add_child(_line_core)

func configure(points: Array, trail_color: Color, secondary_color: Color, core_color: Color, trail_width: float, aura_width: float, intensity: float, quality: int = 0) -> void:
    _intensity = clamp(intensity, 0.0, 1.5)
    _quality = quality

    if points.size() < 2 or _intensity <= 0.02:
        hide_visual()
        return

    _points.resize(points.size())
    for i in range(points.size()):
        _points[i] = points[i]

    var aura_w: float = max(4.0, aura_width * 1.35)
    _line_aura.width = aura_w
    var col_tail: Color = Color(trail_color.r, trail_color.g, trail_color.b, 0.0)
    var col_mid: Color = Color(secondary_color.r * 1.2, secondary_color.g * 1.2, secondary_color.b * 1.4, min(0.75, trail_color.a * _intensity * 1.3))
    var col_head: Color = Color(trail_color.r * 1.4, trail_color.g * 1.3, trail_color.b * 1.6, min(0.95, trail_color.a * _intensity * 1.6))
    _aura_colors.resize(3)
    _aura_colors[0] = col_tail
    _aura_colors[1] = col_mid
    _aura_colors[2] = col_head
    _aura_gradient.colors = _aura_colors
    _line_aura.points = _points
    _line_aura.modulate.a = 1.0
    _line_aura.visible = true

    if _quality <= 1:
        var core_w: float = max(1.5, trail_width * 0.7)
        _line_core.width = core_w
        var core_col_tail: Color = Color(core_color.r, core_color.g, core_color.b, 0.0)
        var core_col_head: Color = Color(1.0, 1.0, 1.2, min(0.9, core_color.a * _intensity * 1.5))
        _core_colors.resize(2)
        _core_colors[0] = core_col_tail
        _core_colors[1] = core_col_head
        _core_gradient.colors = _core_colors
        _line_core.points = _points
        _line_core.modulate.a = 1.0
        _line_core.visible = true
    else:
        _line_core.visible = false

    visible = true

func fade(delta: float) -> bool:
    if !visible:
        return false
    _intensity = max(0.0, _intensity - delta * 5.0)
    if _intensity <= 0.02:
        hide_visual()
        return false
    if is_instance_valid(_line_aura):
        _line_aura.modulate.a = _intensity
    if is_instance_valid(_line_core):
        _line_core.modulate.a = _intensity
    return true

func hide_visual() -> void:
    visible = false
    _intensity = 0.0
    if is_instance_valid(_line_aura):
        _line_aura.visible = false
        _line_aura.clear_points()
    if is_instance_valid(_line_core):
        _line_core.visible = false
        _line_core.clear_points()
