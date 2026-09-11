extends "res://mods-unpacked/Yoko-Fantasy/content/projectiles/player/micro_homing_player_projectile.gd"

export(float) var initial_float_speed: float = 170.0
export(float) var min_target_speed: float = 680.0
export(float) var arm_delay: float = 0.15

const TRAIL_MAX_POINTS: int = 22
const TRAIL_MIN_DIST: float = 2.0
const TRAIL_SHRINK_POINTS_PER_SECOND: float = 60.0
const FADE_DURATION: float = 0.65

var _flight_time: float = 0.0
var _arm_timer: float = 0.0
var _dissipating: bool = false
var _dissipate_timer: float = 0.0
var _trail_shrink_progress: float = 0.0
var _current_speed: float = 0.0
var _top_speed: float = 0.0
var _history_points: Array = []
var _visual_opacity: float = 1.0

onready var _glow_sprite: Sprite = $Glow
onready var _trail_line: Line2D = $"%TrailLine" as Line2D
onready var _hit_sparkles: CPUParticles2D = $"%HitSparkles" as CPUParticles2D


func shoot() -> void:
    .shoot()
    _flight_time = 0.0
    _arm_timer = arm_delay
    _dissipating = false
    _dissipate_timer = 0.0
    _visual_opacity = FantasyProjectileVisualUtils.get_opacity()
    _top_speed = max(min_target_speed, _weapon_stats.projectile_speed)

    _hitbox.ignored_objects.clear()
    if _arm_timer > 0.0:
        _hitbox.active = false
        _hitbox.disable()

    var side: float = 1.0 if randf() > 0.5 else -1.0
    var fling_angle: float = rotation + side * deg2rad(rand_range(70.0, 95.0))
    var float_dir: Vector2 = (Vector2.RIGHT.rotated(fling_angle) * 0.75 + Vector2.UP * 0.25).normalized()
    _current_speed = initial_float_speed
    velocity = float_dir * _current_speed
    rotation = velocity.angle()

    _sprite.scale = Vector2.ONE * 0.52
    _sprite.modulate.a = _visual_opacity
    _glow_sprite.scale = Vector2.ONE * 0.72
    _glow_sprite.modulate.a = 0.4 * _visual_opacity
    _trail_line.modulate.a = _visual_opacity
    _hit_sparkles.modulate.a = _visual_opacity
    _hit_sparkles.emitting = false
    _history_points.clear()
    _trail_line.clear_points()
    _update_trail()


func fa_set_initial_homing_target(target) -> void:
    _homing_target = target if is_instance_valid(target) and not target.dead else null


func _physics_process(delta: float) -> void:
    if _dissipating:
        _process_dissipating(delta)
        return

    if _arm_timer > 0.0:
        _arm_timer -= delta
        if _arm_timer <= 0.0:
            _hitbox.active = true
            _hitbox.enable()

    _flight_time += delta
    var turn_speed: float = lerp(3.5, 8.5, clamp(_flight_time / 0.45, 0.0, 1.0))
    if is_instance_valid(_homing_target) and not _homing_target.dead:
        var distance: float = global_position.distance_to(_homing_target.global_position)
        turn_speed += clamp(1.0 - distance / 300.0, 0.0, 1.0) * 4.0
    _process_micro_homing(delta, turn_speed, Utils.LARGE_NUMBER, 180.0, 180.0)

    _current_speed = lerp(_current_speed, _top_speed, clamp(delta * 3.2, 0.0, 1.0))
    velocity = velocity.normalized() * _current_speed
    rotation = velocity.angle()

    var pulse: float = 0.52 + 0.03 * sin(_flight_time * 8.0)
    _sprite.scale = Vector2.ONE * pulse
    _glow_sprite.scale = Vector2.ONE * (pulse + 0.2)

    position += velocity * delta
    _update_trail()
    _time_until_max_range -= delta
    if _time_until_max_range <= 0.0:
        stop()


func _process_dissipating(delta: float) -> void:
    _dissipate_timer -= delta
    var progress: float = clamp(_dissipate_timer / FADE_DURATION, 0.0, 1.0)
    _sprite.scale = Vector2.ONE * (0.52 * progress)
    _sprite.modulate.a = progress * _visual_opacity
    _glow_sprite.modulate.a = progress * 0.4 * _visual_opacity
    _trail_shrink_progress += delta * TRAIL_SHRINK_POINTS_PER_SECOND
    var points_to_remove: int = min(int(_trail_shrink_progress), _history_points.size())
    _trail_shrink_progress -= points_to_remove
    for _i in range(points_to_remove):
        _history_points.pop_back()
        _trail_line.remove_point(_trail_line.get_point_count() - 1)

    if _dissipate_timer <= 0.0:
        _return_to_pool()


func _on_Hitbox_hit_something(thing_hit: Node, damage_dealt: int) -> void:
    if _dissipating:
        return
    _hit_sparkles.restart()
    _hit_sparkles.emitting = true
    ._on_Hitbox_hit_something(thing_hit, damage_dealt)


func _update_trail() -> void:
    var current_position: Vector2 = global_position
    if _history_points.empty() or _history_points[0].distance_squared_to(current_position) >= TRAIL_MIN_DIST * TRAIL_MIN_DIST:
        _history_points.push_front(current_position)
        if _history_points.size() > TRAIL_MAX_POINTS:
            _history_points.pop_back()

    if _trail_line.get_point_count() < _history_points.size():
        _trail_line.add_point(Vector2.ZERO)
    var to_local_transform: Transform2D = _trail_line.global_transform.affine_inverse()
    for i in range(_history_points.size()):
        _trail_line.set_point_position(i, to_local_transform.xform(_history_points[i]))


func _find_best_homing_target(_max_range: float, _acquire_fov_deg: float) -> Node:
    return Utils.fa_get_highest_health_enemy(Utils.get_scene_node()._entity_spawner.get_all_enemies(false))


func _return_to_pool() -> void:
    _hitbox.active = false
    _hitbox.disable()
    _hitbox.ignored_objects.clear()
    _hit_sparkles.emitting = false
    _history_points.clear()
    _trail_line.clear_points()
    ._return_to_pool()


func stop() -> void:
    if _dissipating:
        return
    _dissipating = true
    _dissipate_timer = FADE_DURATION
    _trail_shrink_progress = 0.0
    velocity = Vector2.ZERO
    _hitbox.active = false
    _hitbox.disable()
    _hitbox.ignored_objects.clear()
    if not visible or _visual_opacity <= 0.0:
        _return_to_pool()
