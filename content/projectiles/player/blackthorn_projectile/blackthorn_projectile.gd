extends PlayerProjectile

const TARGET_INDEX = preload("res://mods-unpacked/Yoko-Fantasy/content/utils/projectile_target_index.gd")
const TRAIL_HISTORY = preload("res://mods-unpacked/Yoko-Fantasy/content/utils/projectile_trail_history.gd")
const IMPACT_SCENE = preload("res://mods-unpacked/Yoko-Fantasy/content/projectiles/player/blackthorn_projectile/blackthorn_impact.tscn")
const SHARD_IMPACT_SCENE = preload("res://mods-unpacked/Yoko-Fantasy/content/projectiles/player/blackthorn_projectile/blackthorn_shard_impact.tscn")
const VISUAL_STATE = preload("res://mods-unpacked/Yoko-Fantasy/content/projectiles/player/blackthorn_projectile/blackthorn_visual_state.gd")
const TRAIL_INTERVAL: float = 1.0 / 20.0
const SCATTER_DURATION: float = 0.12
const HOMING_RANGE: float = 480.0
const HOMING_RELEASE_RANGE: float = 600.0
const HOMING_RETRY_MIN: float = 0.08
const HOMING_RETRY_MAX: float = 0.12

export(bool) var is_shard: bool = false

var _age: float = 0.0
var _curl: float = 1.0
var _heading: Vector2 = Vector2.ZERO
var _opacity: float = 1.0
var _history = TRAIL_HISTORY.new(48, true)
var _trail_points: Array = []
var _trail_timer: float = 0.0
var _main: Node
var _visual_state: Reference
var _target_index: Reference
var _homing_target: Node = null
var _homing_reacquire_time: float = 0.0
var _initial_ignored_enemy: Node = null

onready var _trail: Line2D = $Trail
onready var _glow: Sprite = $Glow


func _ready() -> void:
    _trail_points.resize(10 if is_shard else 8)
    _trail.set_as_toplevel(true)


func shoot_ex(p_from: Node, pos: Vector2, p_velocity: Vector2, p_rotation: float,
        p_weapon_stats, damage_tracking_key: int, effects: Array,
        hitbox_args: Hitbox.HitboxArgs, knockback_direction: Vector2) -> void:
    _age = 0.0
    player_index = p_from.player_index
    _homing_target = null
    _main = Utils.get_scene_node()
    if not _main.has_meta(VISUAL_STATE.META_KEY):
        _main.set_meta(VISUAL_STATE.META_KEY, VISUAL_STATE.new())
    _visual_state = _main.get_meta(VISUAL_STATE.META_KEY)
    _visual_state.refresh()
    if is_shard:
        if not _main.has_meta(TARGET_INDEX.META_KEY):
            _main.set_meta(TARGET_INDEX.META_KEY, TARGET_INDEX.new())
        _target_index = _main.get_meta(TARGET_INDEX.META_KEY)
    _curl = rand_range(0.85, 1.15) * (-1.0 if randf() < 0.5 else 1.0)
    _history.clear()
    _history.push(pos if is_shard else pos - p_velocity.normalized() * 32.0)
    .shoot_ex(p_from, pos, p_velocity, p_rotation, p_weapon_stats,
        damage_tracking_key, effects, hitbox_args, knockback_direction)
    _heading = velocity
    _homing_reacquire_time = rand_range(0.0, HOMING_RETRY_MAX)
    _trail_timer = rand_range(0.0, TRAIL_INTERVAL)
    _opacity = _visual_state.opacity
    _sprite.visible = true
    _sprite.modulate.a = _opacity
    _glow.visible = true
    _glow.modulate.a = _opacity
    _trail.modulate.a = _opacity
    _trail.global_transform = Transform2D.IDENTITY
    _trail.visible = _opacity > 0.0
    if _trail.visible:
        _update_trail()


func set_ignored_objects(objects: Array) -> void:
    .set_ignored_objects(objects)
    _initial_ignored_enemy = objects[0] if is_shard and not objects.empty() else null


func _physics_process(delta: float) -> void:
    if not is_inside_tree():
        return
    _visual_state.refresh()
    if _opacity != _visual_state.opacity:
        _opacity = _visual_state.opacity
        _trail.visible = _opacity > 0.0
        _trail.modulate.a = _opacity
        if not _enable_stop_delay:
            _history.clear()
            _trail_timer = 0.0
    if _enable_stop_delay:
        var tail_fade: float = max(0.0, 1.0 - _elapsed_delay / stop_delay)
        _trail.modulate.a = _opacity * (tail_fade if is_shard else tail_fade * tail_fade)
        return
    _age += delta
    if is_shard:
        velocity = _heading
        if _age < SCATTER_DURATION:
            velocity = velocity.rotated(_curl * 4.4 * (1.0 - _age / SCATTER_DURATION) * delta)
        else:
            _process_blackthorn_homing(delta)
        _heading = velocity
        if _homing_target == null:
            var weave: float = sin(_age * 10.5) * 0.22 * _curl * exp(-_age * 2.5)
            velocity = _heading.rotated(weave)
        rotation = velocity.angle()
    if _opacity <= 0.0:
        _sprite.modulate.a = 0.0
        _glow.modulate.a = 0.0
        return
    var trail_head: Vector2 = global_position if is_shard else global_transform.xform(Vector2(-32, 0))
    _history.push(trail_head)
    _trail_timer -= delta
    if _trail_timer <= 0.0:
        _trail_timer += TRAIL_INTERVAL
        _update_trail()
    else:
        _trail.set_point_position(0, trail_head)
    var fade: float = clamp(_time_until_max_range / 0.16, 0.0, 1.0)
    _sprite.modulate.a = _opacity * fade
    _glow.modulate.a = _opacity * fade


func _update_trail() -> void:
    _history.sample(_trail_points, 12.0 if is_shard else 36.0, Transform2D.IDENTITY)
    _trail.points = PoolVector2Array(_trail_points)


func _find_best_homing_target() -> Node:
    var forward: Vector2 = velocity.normalized()
    var min_dot: float = cos(deg2rad(165.0))
    var nearest: Node = null
    var best_distance: float = HOMING_RANGE * HOMING_RANGE
    for cell in _target_index.nearby_cells(_main, global_position, HOMING_RANGE):
        if cell[0] > best_distance:
            break
        for enemy in cell[1]:
            if not is_instance_valid(enemy) or not (enemy is Enemy) or enemy.dead or _hitbox.ignored_objects.has(enemy):
                continue
            var offset: Vector2 = enemy.global_position - global_position
            var distance: float = offset.length_squared()
            if distance > best_distance:
                continue
            if distance > 0.0001 and forward.dot(offset / sqrt(distance)) < min_dot:
                continue
            best_distance = distance
            nearest = enemy
    if is_instance_valid(_initial_ignored_enemy):
        _hitbox.ignored_objects.erase(_initial_ignored_enemy)
    _initial_ignored_enemy = null
    return nearest


func _is_valid_homing_target() -> bool:
    if not is_instance_valid(_homing_target) or _homing_target.dead or _hitbox.ignored_objects.has(_homing_target):
        return false
    return global_position.distance_squared_to(_homing_target.global_position) <= HOMING_RELEASE_RANGE * HOMING_RELEASE_RANGE


func _process_blackthorn_homing(delta: float) -> void:
    if not _is_valid_homing_target():
        _homing_target = null
        _homing_reacquire_time -= delta
        if _homing_reacquire_time <= 0.0:
            _homing_target = _find_best_homing_target()
            _homing_reacquire_time = rand_range(HOMING_RETRY_MIN, HOMING_RETRY_MAX)
        if _homing_target == null:
            return
    var offset: Vector2 = _homing_target.global_position - global_position
    var distance: float = offset.length()
    if distance < 0.001:
        return
    var speed: float = velocity.length()
    if distance <= max(36.0, speed * delta * 2.0):
        velocity = offset * (speed / distance)
    else:
        var turn_rate: float = max(9.0, speed * 2.2 / distance)
        var angle_diff: float = velocity.angle_to(offset)
        velocity = velocity.rotated(clamp(angle_diff, -turn_rate * delta, turn_rate * delta))


func _on_Hitbox_hit_something(thing_hit: Node, damage_dealt: int) -> void:
    var impact_position: Vector2 = _sprite.to_global(Vector2(21.0 if is_shard else 44.0, 0))
    if _visual_state.allow_impact(impact_position, is_shard):
        _spawn_impact(impact_position)
    ._on_Hitbox_hit_something(thing_hit, damage_dealt)
    _homing_target = null


func _spawn_impact(impact_position: Vector2) -> void:
    var impact_scene: PackedScene = SHARD_IMPACT_SCENE if is_shard else IMPACT_SCENE
    var pool_id: int = impact_scene.get_instance_id()
    var impact = _main.get_node_from_pool(pool_id, _main._effects)
    if impact == null:
        impact = impact_scene.instance()
        _main.add_effect(impact)
        impact.set_meta("pool_id", pool_id)
    impact.begin(impact_position, velocity.angle(), _main, pool_id, _opacity)


func bounce(thing_hit: Node) -> void:
    .bounce(thing_hit)
    _heading = velocity
    _homing_target = null
    _homing_reacquire_time = 0.0


func stop() -> void:
    if _enable_stop_delay:
        return
    _homing_target = null
    _initial_ignored_enemy = null
    velocity = Vector2.ZERO
    _heading = Vector2.ZERO
    _sprite.visible = false
    _glow.visible = false
    .stop()


func _return_to_pool() -> void:
    _homing_target = null
    _homing_reacquire_time = 0.0
    _initial_ignored_enemy = null
    _history.clear()
    _trail.clear_points()
    _age = 0.0
    ._return_to_pool()
