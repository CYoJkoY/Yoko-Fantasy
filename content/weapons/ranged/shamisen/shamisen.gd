extends "res://weapons/ranged/ranged_weapon.gd"

const FANTASY_PROJECTILE_VISUAL_UTILS = preload("res://mods-unpacked/Yoko-Fantasy/content/utils/projectile_visual_utils.gd")

const PLUCK_DURATION: float = 0.50

var shamisen_note_index: int = 0
var _pluck_age: float = PLUCK_DURATION

onready var _strings: Sprite = $Sprite/Strings
onready var _resonance: Sprite = $Sprite/Resonance


func shoot() -> void:
    _pluck_age = 0.0
    _strings.material.set_shader_param("age", 0.0)
    _resonance.material.set_shader_param("age", 0.0)
    _update_pluck_opacity()
    .shoot()


func _process(delta: float) -> void:
    if _pluck_age >= PLUCK_DURATION:
        return
    _pluck_age = min(PLUCK_DURATION, _pluck_age + delta)
    var envelope: float = exp(-_pluck_age * 16.0)
    var flip_sign: float = -1.0 if sprite.flip_v else 1.0
    sprite.rotation = sin(_pluck_age * 40.0) * 0.115 * envelope * flip_sign
    var kick: float = sin(min(_pluck_age / 0.10, 1.0) * PI) * envelope
    sprite.scale = Vector2(1.0 - kick * 0.13, 1.0 + kick * 0.10)
    _strings.material.set_shader_param("age", _pluck_age)
    _resonance.material.set_shader_param("age", _pluck_age)
    _update_pluck_opacity()
    if _pluck_age >= PLUCK_DURATION:
        sprite.rotation = 0.0
        sprite.scale = Vector2.ONE
        _resonance.visible = false


func _update_pluck_opacity() -> void:
    var opacity: float = FANTASY_PROJECTILE_VISUAL_UTILS.get_opacity() if ProgressData.settings.visual_effects else 0.0
    _strings.material.set_shader_param("strength", opacity)
    _resonance.modulate.a = opacity
    _resonance.visible = opacity > 0.0


func update_sprite_flipv() -> void:
    .update_sprite_flipv()
    _strings.flip_v = sprite.flip_v
    _resonance.flip_v = sprite.flip_v
