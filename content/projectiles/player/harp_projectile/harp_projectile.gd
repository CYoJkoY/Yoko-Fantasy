extends "res://mods-unpacked/Yoko-Fantasy/content/projectiles/player/micro_homing_player_projectile.gd"

const NOTES = [
    preload("res://mods-unpacked/Yoko-Fantasy/content/projectiles/player/harp_projectile/harp_note_eighth.webp"),
    preload("res://mods-unpacked/Yoko-Fantasy/content/projectiles/player/harp_projectile/harp_note_beamed.webp"),
    preload("res://mods-unpacked/Yoko-Fantasy/content/projectiles/player/harp_projectile/harp_note_treble_clef.webp"),
    preload("res://mods-unpacked/Yoko-Fantasy/content/projectiles/player/harp_projectile/harp_note_bass_clef.webp")
]
const COLORS = [Color(0.46, 0.86, 1.0), Color(1.0, 0.67, 0.3), Color(0.83, 0.48, 1.0), Color(1.0, 0.86, 0.48)]
const LAUNCH_ANGLES = [-0.12, 0.55, -0.72, 0.18]
const SPEEDS = [1.12, 1.02, 0.94, 1.06]
const TURN_RATES = [2.6, 1.65, 3.2, 1.15]
const SEEK_DELAYS = [0.04, 0.22, 0.36, 0.1]
const SEEK_RANGES = [620.0, 700.0, 760.0, 680.0]

var _note_index: int = 0
var _age: float = 0.0
var _heading: Vector2 = Vector2.RIGHT
var _note_scale: float = 1.0

onready var _score: Node2D = $Score
onready var _aura: Sprite = $Aura


func shoot_ex(p_from: Node, pos: Vector2, p_velocity: Vector2, p_rotation: float,
        p_weapon_stats, damage_tracking_key: int, effects: Array,
        hitbox_args: Hitbox.HitboxArgs, knockback_direction: Vector2) -> void:
    _note_index = p_from.harp_note_index
    _age = 0.0
    .shoot_ex(p_from, pos, p_velocity.rotated(LAUNCH_ANGLES[_note_index]) * SPEEDS[_note_index], p_rotation,
        p_weapon_stats, damage_tracking_key, effects, hitbox_args, knockback_direction)
    _heading = velocity
    _sprite.texture = NOTES[_note_index]
    _note_scale = 45.0 / _sprite.texture.get_height()
    _sprite.scale = Vector2.ONE * _note_scale
    _sprite.visible = true
    _sprite.material.set_shader_param("accent", COLORS[_note_index])
    _aura.modulate = COLORS[_note_index]
    _aura.modulate.a = FantasyProjectileVisualUtils.get_opacity()
    _aura.visible = true
    _score.begin(_sprite.texture, _note_scale, COLORS[_note_index])
    _update_note_pose()


func _physics_process(delta: float) -> void:
    if _enable_stop_delay:
        return
    _age += delta
    velocity = _heading
    if _age >= SEEK_DELAYS[_note_index]:
        _process_micro_homing(delta, TURN_RATES[_note_index], SEEK_RANGES[_note_index],
            105.0 + _note_index * 20.0, 175.0)
    _heading = velocity
    var wave: float = 0.0
    match _note_index:
        0:
            wave = sin(_age * 8.0) * 0.16 * exp(-_age * 0.7)
        1:
            wave = -sin(_age * 3.5) * 0.62
        2:
            wave = sin(_age * 6.2) * 0.8 * exp(-_age * 0.6)
        3:
            wave = sin(_age * 2.5) * 0.32 + sin(_age * 7.5) * 0.14
    velocity = _heading.rotated(wave * (1.0 - exp(-_age * 6.0)))
    rotation = velocity.angle()
    _update_note_pose()


func _update_note_pose() -> void:
    _sprite.global_rotation = sin(_age * (4.2 + _note_index * 0.6) + _note_index * 0.7) * 0.19
    var breath: float = sin(_age * 5.0 + _note_index) * 0.045
    _sprite.scale = Vector2(1.0 + breath, 1.0 - breath * 0.65) * _note_scale
    _sprite.material.set_shader_param("age", _age)
    _aura.global_rotation = _sprite.global_rotation
    _aura.scale = Vector2(0.62, 0.72) * (1.0 + breath)


func _set_time_until_max_range() -> void:
    ._set_time_until_max_range()
    _time_until_max_range /= SPEEDS[_note_index]


func bounce(thing_hit: Node) -> void:
    .bounce(thing_hit)
    _heading = velocity
    _reset_micro_homing()


func stop() -> void:
    if _enable_stop_delay:
        return
    velocity = Vector2.ZERO
    _heading = Vector2.ZERO
    _sprite.visible = false
    _aura.visible = false
    _score.release()
    .stop()


func _on_Hitbox_hit_something(thing_hit: Node, damage_dealt: int) -> void:
    _score.hit(global_position)
    ._on_Hitbox_hit_something(thing_hit, damage_dealt)


func _return_to_pool() -> void:
    _score.clear()
    ._return_to_pool()
