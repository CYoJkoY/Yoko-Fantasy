extends "res://weapons/melee/melee_weapon.gd"

const SWING_FADE_DURATION: float = 0.09

onready var _swing: Sprite = $SwingGlow

var _swing_fade: float = 0.0
export(Vector2) var swing_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
    _swing.visible = false
    _shooting_behavior.set_physics_process(false)


func _process(delta: float) -> void:
    ._process(delta)
    _swing.flip_v = sprite.flip_v
    if _swing_fade > 0.0:
        _swing_fade = max(0.0, _swing_fade - delta)
        var fade: float = _swing_fade / SWING_FADE_DURATION
        _swing.modulate.a = fade * fade * 0.18 * ProgressData.settings.explosion_opacity
        _swing.visible = _swing_fade > 0.0 and ProgressData.settings.visual_effects


func begin_swing(distance: float) -> void:
    _swing_fade = 0.0
    _swing.scale = Vector2.ONE * distance / 250.0
    _swing.position = swing_offset
    update_swing(0.0)


func update_swing(progress: float) -> void:
    _swing.visible = ProgressData.settings.visual_effects
    _swing.material.set_shader_param("progress", progress)
    _swing.modulate.a = (0.18 + sin(progress * PI) * 0.18) * ProgressData.settings.explosion_opacity


func end_swing() -> void:
    _swing_fade = SWING_FADE_DURATION
