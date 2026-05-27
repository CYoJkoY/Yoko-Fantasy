extends "res://mods-unpacked/Yoko-Fantasy/content/projectiles/enemy/enemy_projectile_limit_time.gd"

var _orbit_angle: float = 0.0
var _orbit_radius: float = 50.0
var _orbit_radius_growth: float = 0.0
var _orbit_speed: float = 8.0
var _speed_multiplier: float = 0.85
var _forward_lag_limit: float = 120.0
var _fallback_velocity: Vector2 = Vector2.ZERO
var _forward: Vector2 = Vector2.RIGHT
var _side: Vector2 = Vector2.DOWN
var _last_orbit_offset: Vector2 = Vector2.ZERO
var _orbit_enabled: bool = false

func setup_orbit_parent(parent_projectile: Node2D, orbit_angle: float, orbit_radius: float, orbit_radius_growth: float, orbit_speed: float, speed_multiplier: float, forward_lag_limit: float) -> void:
    _orbit_angle = orbit_angle
    _orbit_radius = orbit_radius
    _orbit_radius_growth = orbit_radius_growth
    _orbit_speed = orbit_speed
    _speed_multiplier = speed_multiplier
    _forward_lag_limit = forward_lag_limit
    _fallback_velocity = parent_projectile.velocity * _speed_multiplier
    velocity = _fallback_velocity
    _forward = parent_projectile.velocity.normalized() if parent_projectile.velocity.length_squared() > 0 else Vector2.RIGHT.rotated(parent_projectile.rotation)
    _side = _forward.tangent()
    _last_orbit_offset = _get_orbit_offset()
    global_position += _last_orbit_offset
    if _hitbox != null and is_instance_valid(_hitbox):
        _hitbox.active = true
        _hitbox.enable()
    _orbit_enabled = true

func _physics_process(delta) -> void:
    if _orbit_enabled:
        delta_time += delta
        if lifetime > 0 and delta_time >= lifetime:
            delta_time = 0.0
            stop()
            return

        _orbit_angle += _orbit_speed * delta
        var orbit_offset: Vector2 = _get_orbit_offset()
        position += velocity * delta + orbit_offset - _last_orbit_offset
        _last_orbit_offset = orbit_offset

        rotation = velocity.angle() if velocity.length_squared() > 0 else rotation
        return

    if velocity == Vector2.ZERO:
        velocity = _fallback_velocity
    ._physics_process(delta)

func stop() -> void:
    _orbit_enabled = false
    _fallback_velocity = Vector2.ZERO
    _last_orbit_offset = Vector2.ZERO
    .stop()

func _return_to_pool() -> void:
    _orbit_enabled = false
    _fallback_velocity = Vector2.ZERO
    _orbit_radius_growth = 0.0
    _forward = Vector2.RIGHT
    _side = Vector2.DOWN
    _last_orbit_offset = Vector2.ZERO
    ._return_to_pool()

func _get_orbit_offset() -> Vector2:
    return _side * cos(_orbit_angle) * (_orbit_radius + _orbit_radius_growth * delta_time)
