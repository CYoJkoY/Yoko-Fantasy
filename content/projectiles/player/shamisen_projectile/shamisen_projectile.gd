extends "res://projectiles/player_projectile.gd"

const TARGET_INDEX = preload("res://mods-unpacked/Yoko-Fantasy/content/utils/projectile_target_index.gd")
const CHAIN_EFFECT = preload("res://mods-unpacked/Yoko-Fantasy/content/weapons/ranged/shamisen/shamisen_effect.tres")
const NOTE_LIFETIME: float = 5.0
const CHAIN_SPEED: float = 2200.0
const CHAIN_LEG_LIFETIME: float = 0.65

var _note_progress: float = 0.0
var _heading: Vector2 = Vector2.ZERO
var _flight_distance: float = 0.0
var _flight_duration: float = 0.0
var _chained: bool = false
var _target: Node = null
var _chain_source: Node = null
var _leg_origin: Vector2 = Vector2.ZERO
var _leg_age: float = 0.0
var _leg_duration: float = 0.1
var _leg_bend: float = 0.0
var _leg_index: int = 0
var _main: Node
var _target_index: Reference

onready var _visual: Node2D = $Visual


func _ready() -> void:
    stop_delay = _visual.RELEASE_DURATION / PHYSICS_FPS


func shoot_ex(p_from: Node, pos: Vector2, p_velocity: Vector2, p_rotation: float,
        p_weapon_stats, damage_tracking_key: int, effects: Array,
        hitbox_args: Hitbox.HitboxArgs, knockback_direction: Vector2) -> void:
    player_index = p_from.player_index
    _note_progress = 0.0
    _chained = false
    _target = null
    _chain_source = null
    _leg_index = 0
    _heading = p_velocity.normalized()
    _flight_distance = float(p_weapon_stats.max_range + PROJECTILE_ADDITIONAL_DISTANCE)
    var launch_speed: float = p_velocity.length() * max(0.15, _flight_distance / 400.0)
    _flight_duration = min(NOTE_LIFETIME, 3.0 * _flight_distance / launch_speed)
    _main = Utils.get_scene_node()
    if not _main.has_meta(TARGET_INDEX.META_KEY):
        _main.set_meta(TARGET_INDEX.META_KEY, TARGET_INDEX.new())
    _target_index = _main.get_meta(TARGET_INDEX.META_KEY)
    _hitbox.ignored_objects.clear()
    .shoot_ex(p_from, pos, p_velocity, p_rotation, p_weapon_stats,
        damage_tracking_key, effects, hitbox_args, knockback_direction)
    velocity = Vector2.ZERO
    _hitbox.set_meta("fantasy_damage_color", Color("c7a5ff"))
    _visual.begin(p_from.shamisen_note_index, NOTE_LIFETIME)


func _set_time_until_max_range() -> void:
    _time_until_max_range = NOTE_LIFETIME


func _physics_process(delta: float) -> void:
    if _enable_stop_delay or not is_inside_tree():
        return
    if not is_instance_valid(_hitbox.from):
        stop()
        return
    if _chained:
        _advance_chain(delta)
    elif _note_progress < 1.0:
        _note_progress = min(1.0, _note_progress + delta / _flight_duration)
        var remaining: float = 1.0 - _note_progress
        var distance: float = _flight_distance * (1.0 - remaining * remaining * remaining)
        global_position = spawn_position + _heading * distance


func _advance_chain(delta: float) -> void:
    if not is_instance_valid(_target) or _target.dead or _hitbox.ignored_objects.has(_target):
        _visual.finish_link(global_position)
        if not _start_next_leg(null):
            return
    _leg_age += delta
    if is_instance_valid(_chain_source) and not _chain_source.dead:
        _leg_origin = _chain_source._hurtbox._collision.global_position
    var destination: Vector2 = _target._hurtbox._collision.global_position
    var offset: Vector2 = destination - _leg_origin
    var progress: float = clamp(_leg_age / _leg_duration, 0.0, 1.0)
    var normal: Vector2 = offset.normalized().tangent()
    var next_position: Vector2 = _leg_origin.linear_interpolate(destination, progress)
    next_position += normal * sin(progress * PI) * _leg_bend
    var movement: Vector2 = next_position - global_position
    if movement.length_squared() > 0.01:
        rotation = movement.angle()
    global_position = next_position
    _visual.advance_link(_leg_origin, destination, progress)


func _start_next_leg(from_enemy: Node) -> bool:
    _target = _find_next_target()
    if _target == null:
        stop()
        return false
    _chain_source = from_enemy
    _leg_origin = global_position
    _leg_age = 0.0
    var destination: Vector2 = _target._hurtbox._collision.global_position
    var distance: float = _leg_origin.distance_to(destination)
    _leg_duration = clamp(distance / CHAIN_SPEED, 0.075, 0.24)
    _leg_bend = min(38.0, distance * 0.16) * (1.0 if _leg_index % 2 == 0 else -1.0)
    _leg_index += 1
    _time_until_max_range = CHAIN_LEG_LIFETIME
    rotation = (destination - _leg_origin).angle()
    _visual.connect_targets(from_enemy, _target, _leg_origin, destination, _leg_bend)
    return true


func _find_next_target() -> Node:
    var chain_range: float = CHAIN_EFFECT.get_chain_range(player_index)
    if chain_range <= 0.0:
        return null
    var nearest: Node = null
    var best_distance: float = chain_range * chain_range
    for cell in _target_index.nearby_cells(_main, global_position, chain_range):
        if cell[0] > best_distance:
            break
        for enemy in cell[1]:
            if not is_instance_valid(enemy) or enemy.dead or _hitbox.ignored_objects.has(enemy):
                continue
            var distance: float = global_position.distance_squared_to(enemy.global_position)
            if distance < best_distance:
                nearest = enemy
                best_distance = distance
    return nearest


func _on_Hitbox_hit_something(thing_hit: Node, damage_dealt: int) -> void:
    if _enable_stop_delay:
        return
    if not is_instance_valid(_hitbox.from):
        stop()
        return
    global_position = thing_hit._hurtbox._collision.global_position
    _visual.finish_link(global_position, thing_hit)
    _visual.impact(global_position, not _chained)
    var previous_leg: int = _leg_index
    ._on_Hitbox_hit_something(thing_hit, damage_dealt)
    if not _enable_stop_delay and _chained and _leg_index == previous_leg:
        _start_next_leg(thing_hit)


func bounce(thing_hit: Node) -> void:
    _bounce -= 1
    if not _chained:
        _chained = true
        _visual.set_chained()
    velocity = Vector2.ZERO
    set_knockback_vector(Vector2.ZERO, 0.0, 0.0)
    if _hitbox.damage > 0:
        _hitbox.damage = max(1, _hitbox.damage * (1.0 - _weapon_stats.bounce_dmg_reduction))
    _start_next_leg(thing_hit)


func stop() -> void:
    if _enable_stop_delay:
        return
    velocity = Vector2.ZERO
    _target = null
    _chain_source = null
    _visual.release()
    .stop()


func _return_to_pool() -> void:
    _visual.clear()
    _target = null
    _chain_source = null
    _chained = false
    ._return_to_pool()
