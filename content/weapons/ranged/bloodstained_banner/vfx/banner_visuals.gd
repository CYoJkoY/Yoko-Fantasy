extends Node2D

const Palette = preload("res://mods-unpacked/Yoko-Fantasy/content/weapons/ranged/bloodstained_banner/vfx/blood_palette.gd")

onready var _weapon_sprite: Sprite = get_parent()
onready var _halo: Sprite = $BloodHalo
onready var _corona: Sprite = $IdleCorona
onready var _accent: Sprite = $IdleAccent
onready var _cast_wave: Sprite = $CastWave
onready var _embers: CPUParticles2D = $CastEmbers
onready var _veins: Sprite = $BloodVeins
onready var _glint: Sprite = $CastGlint
onready var _orbit_spark: Sprite = $OrbitSpark
onready var _orbit_echo: Sprite = $OrbitEcho
onready var _idle_motes: CPUParticles2D = $IdleMotes
onready var _tinted_sprites: Array = [_halo, _accent, _cast_wave, _glint, _orbit_spark, _orbit_echo]

var _cursed: bool = false
var _particle_colors: PoolColorArray
var _cast_elapsed: float = 1.0
var _cast_energy: float = 0.0
var _cast_press: float = 0.0
var _cast_sway: float = 0.0


func _ready() -> void:
    _particle_colors = _embers.color_ramp.colors
    _embers.color_ramp = _embers.color_ramp.duplicate()
    _idle_motes.color_ramp = _embers.color_ramp


func set_cursed(cursed: bool) -> void:
    _cursed = cursed
    _corona.material.set_shader_param("cursed", 1.0 if cursed else 0.0)
    _veins.material.set_shader_param("cursed", 1.0 if cursed else 0.0)
    Palette.set_gradient(_embers.color_ramp, _particle_colors, cursed)


func play_cast() -> void:
    _cast_elapsed = 0.0
    _embers.restart()
    _embers.emitting = true


func advance(delta: float, time: float) -> void:
    _cast_elapsed += delta
    var t: float = clamp(_cast_elapsed / 0.62, 0.0, 1.0)
    var energy: float = sin(pow(t, 0.52) * PI)
    var press: float = 0.0
    if _cast_elapsed < 0.055:
        press = -0.12 * smoothstep(0.0, 0.055, _cast_elapsed)
    elif _cast_elapsed < 0.15:
        press = lerp(-0.12, 1.0, smoothstep(0.055, 0.15, _cast_elapsed))
    else:
        press = 1.0 - smoothstep(0.20, 0.58, _cast_elapsed)
    var blend: float = 1.0 - exp(-delta * 28.0)
    _cast_energy = lerp(_cast_energy, energy, blend)
    _cast_press = lerp(_cast_press, press, blend)
    _cast_sway = lerp(_cast_sway, sin(t * TAU) * energy * 0.12, blend)
    var breath: float = sin(time * 2.2)
    modulate.a = FantasyProjectileVisualUtils.get_opacity()
    _halo.scale = Vector2(0.70, 0.48) * (1.0 + breath * 0.05 + _cast_energy * 0.16)
    _halo.modulate = Color(1.0, 0.035, 0.13, 0.42 + breath * 0.04 + _cast_energy * 0.32)
    _corona.rotation = time * 1.05 + sin(time * 1.7) * 0.18 + _cast_sway * 1.4
    _corona.position = Vector2(2.0 + sin(time * 1.4) * 3.0, -4.0 + cos(time * 1.8) * 2.0)
    _corona.scale = Vector2(0.68, 0.47) * (1.0 + breath * 0.035 + _cast_energy * 0.10)
    _corona.modulate = Color(1.0, 1.0, 1.0, 0.48 + breath * 0.06 + _cast_energy * 0.22)
    _corona.material.set_shader_param("age", time)
    _corona.material.set_shader_param("energy", _cast_energy)
    _accent.rotation = 2.0 - time * 0.76 + sin(time * 1.3) * 0.16 - _cast_sway
    _accent.scale = Vector2(0.55, 0.39) * (1.0 - breath * 0.025 + _cast_energy * 0.08)
    _accent.modulate = Color(0.72, 0.12, 0.90, 0.18 + _cast_energy * 0.10)
    _cast_wave.rotation = -time * 0.32 - _cast_energy * 0.70
    var wave_scale: Vector2 = Vector2(0.46, 0.32) + Vector2(0.42, 0.24) * sin(t * PI * 0.5)
    _cast_wave.scale = _cast_wave.scale.linear_interpolate(wave_scale, blend)
    _cast_wave.modulate = Color(1.0, 0.28, 0.37, _cast_energy * 0.85)
    _cast_wave.visible = _cast_energy > 0.005
    _veins.material.set_shader_param("age", time)
    _veins.material.set_shader_param("energy", _cast_energy)
    _glint.scale = Vector2(0.28, 0.60) * (0.85 + _cast_energy * 0.35)
    _glint.modulate = Color(1.0, 0.55, 0.46, _cast_energy * _cast_energy * 0.90)
    _glint.rotation = time * 0.12
    var orbit: float = time * 1.9
    _orbit_spark.position = Vector2(3.0 + cos(orbit) * 40.0, -4.0 + sin(orbit) * 26.0)
    _orbit_spark.rotation = orbit
    _orbit_spark.modulate = Color(1.0, 0.30, 0.35, 0.34 + 0.16 * sin(orbit) + _cast_energy * 0.15)
    _orbit_echo.position = Vector2(5.0 + cos(-orbit * 0.73 + 2.4) * 32.0, -3.0 + sin(-orbit * 0.73 + 2.4) * 22.0)
    _orbit_echo.rotation = -orbit
    _orbit_echo.modulate = Color(0.82, 0.12, 0.66, 0.20 + 0.09 * cos(orbit * 0.73))
    _weapon_sprite.rotation = sin(time * 2.1) * 0.025 + sin(time * 1.1 + 0.6) * 0.012 + _cast_sway
    _weapon_sprite.position = Vector2(-_cast_press * 32.0, _cast_sway * 9.0)
    if _cursed:
        for visual in _tinted_sprites:
            visual.modulate = Palette.tint(visual.modulate, true)
