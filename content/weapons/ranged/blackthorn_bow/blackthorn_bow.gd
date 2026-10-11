extends "res://weapons/ranged/ranged_weapon.gd"

var _release_age: float = 1.0
var _draw_cooldown: float = 1.0

onready var _charge: Sprite = $Sprite/Charge
onready var _nocked_arrow: Sprite = $Sprite/NockedArrow
onready var _string: Line2D = $Sprite/String
onready var _muzzle_flash: Sprite = $Sprite/MuzzleFlash


func shoot() -> void:
    _release_age = 0.0
    .shoot()


func get_next_cooldown(at_wave_begin: bool = false) -> float:
    var cooldown: float = .get_next_cooldown(at_wave_begin)
    _draw_cooldown = max(1.0, cooldown)
    return cooldown


func _process(delta: float) -> void:
    _release_age = min(1.0, _release_age + delta)
    var charge: float = clamp(1.0 - _current_cooldown / _draw_cooldown, 0.0, 1.0)
    var remaining: float = max(0.0, _current_cooldown) / 60.0
    if _is_shooting:
        remaining += max(0.0, current_stats.recoil_duration * 2.0 - _release_age)
    var cycle: float = max(0.001, _release_age + remaining)
    var nock_delay: float = min(0.12, cycle * 0.1)
    var nock_fade: float = min(0.16, cycle * 0.18)
    var nock_alpha: float = clamp((_release_age - nock_delay) / nock_fade, 0.0, 1.0)
    var kick: float = pow(max(0.0, 1.0 - _release_age / 0.12), 2.0)
    var side: float = -1.0 if sprite.flip_v else 1.0
    var opacity: float = FantasyProjectileVisualUtils.get_opacity()
    sprite.scale = Vector2(1.0 - kick * 0.08, 1.0 + kick * 0.05)
    _charge.flip_v = sprite.flip_v
    _charge.modulate.a = opacity
    _charge.material.set_shader_param("charge", charge)
    _charge.material.set_shader_param("release_flash", kick)
    _string.set_point_position(0, Vector2(-5, -12 * side))
    _string.set_point_position(1, Vector2(-4 - charge * 10 + sin(_release_age * 88) * kick * 8, 8 * side))
    _string.set_point_position(2, Vector2(2, 52 * side))
    _string.modulate.a = 0.3 + charge * 0.45 + kick * 0.25
    _nocked_arrow.visible = nock_alpha > 0.0
    _nocked_arrow.position = Vector2(19 - charge * 10, 8 * side)
    _nocked_arrow.modulate.a = nock_alpha * opacity
    muzzle.position.y = 8 * side
    _muzzle_flash.visible = kick > 0.0
    _muzzle_flash.position = muzzle.position
    _muzzle_flash.scale = Vector2(1.1 + _release_age * 3.5, 0.46)
    _muzzle_flash.modulate.a = kick * opacity
