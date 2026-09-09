extends PlayerProjectile

const HIT_SPARK_SCENE: PackedScene = preload("res://mods-unpacked/Yoko-Fantasy/content/weapons/ranged/finger_snap/vfx/finger_snap_hit_spark.tscn")
const DISAPPEAR_SPARK_SCENE: PackedScene = preload("res://mods-unpacked/Yoko-Fantasy/content/weapons/ranged/finger_snap/vfx/finger_snap_disappear_spark.tscn")
onready var _hit_spark_pool_id: int = HIT_SPARK_SCENE.get_instance_id()
onready var _disappear_spark_pool_id: int = DISAPPEAR_SPARK_SCENE.get_instance_id()

const TELEGRAPH_TIME: float = 0.15
const BASE_CONVERGE_SPEED: float = 460.0
const TRAIL_MAX_POINTS: int = 16
const TRAIL_MIN_DIST: float = 3.0

var _target_center: Vector2 = Vector2.ZERO
var _inward_dir: Vector2 = Vector2.RIGHT
var _is_converging: bool = false
var _telegraph_timer: float = 0.0
var _current_speed: float = 0.0
var _initial_pos: Vector2 = Vector2.ZERO
var _history_points: Array = []
var _reached_center_once: bool = false
var _has_hit_something: bool = false
var _spin_angle: float = 0.0
var _setting_opacity: float = 1.0

onready var _star_sprite: Sprite = $"%StarSprite" as Sprite
onready var _trail_line: Line2D = $"%TrailLine" as Line2D
onready var _trail_particles: CPUParticles2D = $"%TrailParticles" as CPUParticles2D


func _ready() -> void:
    if is_instance_valid(_sprite):
        _sprite.visible = false
        _sprite.texture = null
    _init_trail()


func _init_trail() -> void:
    _history_points.clear()
    if is_instance_valid(_trail_line):
        _trail_line.clear_points()
        _trail_line.set_as_toplevel(true)


func init_converge(
    target_center: Vector2,
    spawn_pos: Vector2,
    speed_val: float = BASE_CONVERGE_SPEED
) -> void:
    _target_center = target_center
    _initial_pos = spawn_pos
    global_position = spawn_pos
    velocity = Vector2.ZERO
    sinusoidal_motion = Vector2.ZERO

    _setting_opacity = FantasyProjectileVisualUtils.get_opacity()

    _inward_dir = (target_center - spawn_pos).normalized()
    if _inward_dir == Vector2.ZERO:
        _inward_dir = Vector2.RIGHT

    rotation = _inward_dir.angle()
    _spin_angle = rand_range(0.0, TAU)
    _current_speed = speed_val * 0.45
    _is_converging = true
    _telegraph_timer = TELEGRAPH_TIME
    _reached_center_once = false
    _has_hit_something = false
    _enable_stop_delay = false
    _elapsed_delay = 0.0
    _time_until_max_range = 5.0

    if is_instance_valid(_hitbox):
        _hitbox.active = true
        _hitbox.enable()
        _hitbox.ignored_objects.clear()

    _init_trail()
    _record_trail_point(spawn_pos)
    if is_instance_valid(_trail_line):
        _trail_line.add_point(spawn_pos)

    if is_instance_valid(_star_sprite):
        _star_sprite.visible = true
        _star_sprite.scale = Vector2(0.2, 0.2)
        _star_sprite.modulate = Color(1.0, 0.98, 0.85, 0.9 * _setting_opacity)
        _star_sprite.rotation = _spin_angle

    if is_instance_valid(_trail_line):
        _trail_line.modulate.a = _setting_opacity

    if is_instance_valid(_trail_particles):
        _trail_particles.modulate.a = _setting_opacity
        _trail_particles.emitting = true
        _trail_particles.restart()


func _physics_process(delta: float) -> void:
    if not _is_converging:
        _update_trail()
        ._physics_process(delta)
        return

    _time_until_max_range = 5.0
    _spin_angle += delta * 6.0

    if _telegraph_timer > 0.0:
        _telegraph_timer -= delta
        global_position = _initial_pos
        rotation = _inward_dir.angle()
        if is_instance_valid(_star_sprite):
            var p = 1.0 - max(0.0, _telegraph_timer / TELEGRAPH_TIME)
            var ease_p = sin(p * PI * 0.5)
            _star_sprite.scale = Vector2.ONE * lerp(0.18, 0.45, ease_p)
            _star_sprite.rotation = _spin_angle
            _star_sprite.modulate = Color(1.0, 0.96, 0.75, lerp(0.5, 1.0, ease_p) * _setting_opacity)
        _update_trail()
        return


    _current_speed = lerp(_current_speed, BASE_CONVERGE_SPEED * 1.3, delta * 8.0)
    var move_vec = _inward_dir * (_current_speed * delta)
    global_position += move_vec
    rotation = _inward_dir.angle()

    if is_instance_valid(_star_sprite):
        _star_sprite.rotation = _spin_angle
        _star_sprite.scale = Vector2.ONE * 0.42
        _star_sprite.modulate.a = _setting_opacity

    _update_trail()

    var to_center = _target_center - global_position
    var passed_center = to_center.dot(_inward_dir) <= 6.0 or global_position.distance_to(_target_center) <= 16.0

    if passed_center and not _reached_center_once:
        _reached_center_once = true
        _on_reach_center()


func _on_reach_center() -> void:
    var can_continue: bool = _piercing > 0 or (_bounce > 0 and _has_hit_something)
    if not can_continue:
        stop()
    else:
        _is_converging = false
        _set_time_until_max_range()
        var proj_speed: float = _weapon_stats.projectile_speed if is_instance_valid(_weapon_stats) else BASE_CONVERGE_SPEED
        velocity = _inward_dir * max(proj_speed, _current_speed)
        _spawn_hit_spark(global_position)


func _on_Hitbox_hit_something(thing_hit: Node, damage_dealt: int) -> void:
    _has_hit_something = true
    _spawn_hit_spark(global_position)
    ._on_Hitbox_hit_something(thing_hit, damage_dealt)


func bounce(thing_hit: Node) -> void:
    _is_converging = false
    var speed: float = max(_current_speed, _weapon_stats.projectile_speed if is_instance_valid(_weapon_stats) else BASE_CONVERGE_SPEED)

    .bounce(thing_hit)

    if velocity.length_squared() < 10.0:
        var target = null
        if is_instance_valid(thing_hit) and "_entity_spawner_ref" in thing_hit and thing_hit._entity_spawner_ref != null:
            target = thing_hit._entity_spawner_ref.get_rand_enemy(thing_hit)
        var direction = (target.global_position - global_position).angle() if target != null and is_instance_valid(target) else rand_range(-PI, PI)
        velocity = Vector2.RIGHT.rotated(direction) * speed
        rotation = velocity.angle()

    _time_until_max_range = 5.0


func _update_trail() -> void:
    if not is_instance_valid(_trail_line):
        return

    var cur_pos = global_position
    if _history_points.empty() or _history_points[0].distance_to(cur_pos) >= TRAIL_MIN_DIST:
        _record_trail_point(cur_pos)

    _trail_line.clear_points()
    for point in _history_points:
        _trail_line.add_point(point)


func _record_trail_point(pos: Vector2) -> void:
    _history_points.push_front(pos)
    if _history_points.size() > TRAIL_MAX_POINTS:
        _history_points.pop_back()


func _spawn_hit_spark(pos: Vector2) -> void:
    var main = Utils.get_scene_node()
    if main == null or not is_instance_valid(main):
        return
    var spark = main.get_node_from_pool(_hit_spark_pool_id, main._effects)
    if spark == null:
        spark = HIT_SPARK_SCENE.instance()
        main.add_effect(spark)
        spark.set_meta("pool_id", _hit_spark_pool_id)
    spark.play_hit(pos, main, _hit_spark_pool_id)


func _spawn_disappear_spark(pos: Vector2) -> void:
    var main = Utils.get_scene_node()
    if main == null or not is_instance_valid(main):
        return
    var spark = main.get_node_from_pool(_disappear_spark_pool_id, main._effects)
    if spark == null:
        spark = DISAPPEAR_SPARK_SCENE.instance()
        main.add_effect(spark)
        spark.set_meta("pool_id", _disappear_spark_pool_id)
    spark.play_disappear(pos, main, _disappear_spark_pool_id)


func stop() -> void:
    if not _enable_stop_delay and visible and modulate.a > 0.05:
        _spawn_disappear_spark(global_position)
    .stop()


func _return_to_pool() -> void:
    _is_converging = false
    _has_hit_something = false
    if is_instance_valid(_trail_line):
        _trail_line.clear_points()
    _history_points.clear()
    ._return_to_pool()
