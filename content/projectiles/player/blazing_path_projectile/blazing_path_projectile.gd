extends PlayerProjectile

const HIT_SPLASH_SCENE = preload("res://mods-unpacked/Yoko-Fantasy/content/projectiles/player/blazing_path_projectile/blazing_path_hit_splash.tscn")
const FLUTTER_STEP_SIN_1: float = 0.434965534
const FLUTTER_STEP_COS_1: float = 0.900447102
const FLUTTER_STEP_SIN_2: float = 0.717356091
const FLUTTER_STEP_COS_2: float = 0.696706709

export (int) var num_body_points: int = 26
export (float) var point_spacing: float = 8.0
export (float, 0.0, 1.0) var lifetime_multiplier: float = 0.8

var _base_speed: float
var _base_direction: Vector2 = Vector2.RIGHT
var _normal_direction: Vector2 = Vector2.UP

var _wave_phase: float = 0.0
var _elapsed_time: float = 0.0
var _stop_head_scale: Vector2 = Vector2.ONE

var _history_positions: Array = []

var _seed_1: float = 0.0
var _seed_2: float = 0.0
var _seed_3: float = 0.0
var _seed_4: float = 0.0

onready var _line: Line2D = $"%Line2D" as Line2D
onready var _head_sprite: Sprite = $"%Sprite" as Sprite
onready var _ember_particles: CPUParticles2D = $"%EmberParticles" as CPUParticles2D


func _ready() -> void:
    _init_line_points()


func _init_line_points() -> void:
    _line.clear_points()
    for _i in range(num_body_points):
        _line.add_point(Vector2.ZERO)
    _ember_particles.position = Vector2.ZERO


func shoot_ex(p_from: Node,
        pos: Vector2,
        p_velocity: Vector2,
        p_rotation: float,
        p_weapon_stats,
        damage_tracking_key: int,
        effects: Array,
        hitbox_args: Hitbox.HitboxArgs,
        knockback_direction: Vector2
        ) -> void:

    _base_speed = p_velocity.length()
    if _base_speed < 1.0:
        _base_speed = p_weapon_stats.projectile_speed

    if p_velocity.length_squared() > 0.001:
        _base_direction = p_velocity.normalized()
    else:
        _base_direction = Vector2.RIGHT.rotated(p_rotation)
    _normal_direction = Vector2(-_base_direction.y, _base_direction.x)

    _elapsed_time = 0.0
    _seed_1 = rand_range(0.0, 20.0)
    _seed_2 = rand_range(0.0, 20.0)
    _seed_3 = rand_range(0.0, 20.0)
    _seed_4 = rand_range(0.0, 20.0)
    _history_positions.clear()
    if p_from != null and is_instance_valid(p_from):
        var toggle: bool = p_from.get_meta("blazing_toggle") if p_from.has_meta("blazing_toggle") else false
        p_from.set_meta("blazing_toggle", not toggle)
        _wave_phase = 0.0 if toggle else PI
    else:
        _wave_phase = (randi() % 2) * PI

    _history_positions.push_back(pos)
    _init_line_points()

    .shoot_ex(p_from, pos, p_velocity, p_rotation, p_weapon_stats, damage_tracking_key, effects, hitbox_args, knockback_direction)


func shoot() -> void:
    .shoot()
    _time_until_max_range *= lifetime_multiplier
    var opacity = ProgressData.settings.projectile_opacity
    _head_sprite.modulate.a = opacity
    _head_sprite.scale = Vector2.ONE
    _line.modulate.a = opacity
    _ember_particles.modulate.a = opacity
    _ember_particles.emitting = true
    _ember_particles.restart()


func _physics_process(delta: float) -> void:
    if _enable_stop_delay:
        return

    _elapsed_time += delta
    var t = _elapsed_time

    var w1 = sin(10.3 * t + _seed_1 + _wave_phase) * 270.0
    var w2 = sin(17.9 * t + _seed_2) * 135.0
    var w3 = cos(28.7 * t + _seed_3) * 80.0
    var w4 = sin(44.3 * t + _seed_4) * 45.0
    var lateral_velocity = w1 + w2 + w3 + w4

    var surge = 1.0 + 0.20 * sin(12.5 * t + _seed_1) + 0.10 * cos(25.0 * t + _seed_2)
    var forward_velocity = _base_speed * surge
    var current_velocity = (_base_direction * forward_velocity) + (_normal_direction * lateral_velocity)
    velocity = (_base_direction * _base_speed) + current_velocity

    if current_velocity.length_squared() > 1.0:
        var target_angle = current_velocity.angle()
        rotation = lerp_angle(rotation, target_angle, clamp(delta * 24.0, 0.0, 1.0))

    _history_positions.push_front(global_position)

    _update_fluid_serpent_body(t)

    var pulse = 1.0 + 0.15 * sin(24.0 * t + _seed_1)
    var squish = 1.0 - 0.10 * sin(24.0 * t + _seed_1)
    _head_sprite.scale = Vector2(pulse, squish)


func _process(_delta: float) -> void:
    if not _enable_stop_delay:
        return

    var progress = clamp(_elapsed_delay / max(0.001, stop_delay - 1.0), 0.0, 1.0)
    var opacity = ProgressData.settings.projectile_opacity * (1.0 - progress)
    _head_sprite.modulate.a = opacity
    _head_sprite.scale = _stop_head_scale.linear_interpolate(Vector2.ONE * 0.65, progress)
    _line.modulate.a = opacity
    _ember_particles.modulate.a = opacity


func _update_fluid_serpent_body(t: float) -> void:
    if _history_positions.size() < 2:
        return

    _line.set_point_position(0, Vector2.ZERO)
    var available_distance: float = 0.0
    var required_distance: float = (num_body_points - 1) * point_spacing
    for i in range(1, _history_positions.size()):
        available_distance += (_history_positions[i] - _history_positions[i - 1]).length()
        if available_distance >= required_distance:
            _history_positions.resize(i + 1)
            break

    var history_index: int = 1
    var previous_distance: float = 0.0
    var current_distance: float = (_history_positions[1] - _history_positions[0]).length()
    var flutter_phase_1: float = 18.0 * t - 0.45 + _seed_1
    var flutter_phase_2: float = 32.0 * t - 0.8
    var flutter_sin_1: float = sin(flutter_phase_1)
    var flutter_cos_1: float = cos(flutter_phase_1)
    var flutter_sin_2: float = sin(flutter_phase_2)
    var flutter_cos_2: float = cos(flutter_phase_2)

    for body_index in range(1, num_body_points):
        var target_distance = body_index * point_spacing
        if available_distance <= 0.001:
            _line.set_point_position(body_index, Vector2.ZERO)
            continue

        var clamped_distance = min(target_distance, available_distance)
        while history_index < _history_positions.size() - 1 and current_distance < clamped_distance:
            history_index += 1
            previous_distance = current_distance
            current_distance += (_history_positions[history_index] - _history_positions[history_index - 1]).length()

        var progress = (clamped_distance - previous_distance) / max(0.0001, current_distance - previous_distance)
        var world_point = _history_positions[history_index - 1].linear_interpolate(_history_positions[history_index], progress)

        var emergence = clamp(available_distance / max(0.001, body_index * point_spacing), 0.0, 1.0)
        var spine_flutter = (flutter_sin_1 * 2.5 + flutter_cos_2 * 1.2) * (1.0 - float(body_index) / float(num_body_points)) * emergence
        _line.set_point_position(body_index, to_local(world_point) + Vector2(0, spine_flutter))

        var next_sin_1: float = flutter_sin_1 * FLUTTER_STEP_COS_1 - flutter_cos_1 * FLUTTER_STEP_SIN_1
        flutter_cos_1 = flutter_cos_1 * FLUTTER_STEP_COS_1 + flutter_sin_1 * FLUTTER_STEP_SIN_1
        flutter_sin_1 = next_sin_1
        var next_sin_2: float = flutter_sin_2 * FLUTTER_STEP_COS_2 - flutter_cos_2 * FLUTTER_STEP_SIN_2
        flutter_cos_2 = flutter_cos_2 * FLUTTER_STEP_COS_2 + flutter_sin_2 * FLUTTER_STEP_SIN_2
        flutter_sin_2 = next_sin_2

    _ember_particles.position = _line.get_point_position(num_body_points - 1)


func stop() -> void:
    if _enable_stop_delay:
        return

    _stop_head_scale = _head_sprite.scale
    .stop()
    velocity = Vector2.ZERO
    _ember_particles.emitting = false


func _return_to_pool() -> void:
    ._return_to_pool()
    _ember_particles.emitting = false
    _history_positions.clear()
    _elapsed_time = 0.0
    _stop_head_scale = Vector2.ONE
    _init_line_points()


func bounce(thing_hit: Node) -> void:
    .bounce(thing_hit)

    if velocity.length_squared() > 0.001:
        _base_direction = velocity.normalized()
    else:
        _base_direction = Vector2.RIGHT.rotated(rotation)
    _normal_direction = Vector2(-_base_direction.y, _base_direction.x)

    _elapsed_time = 0.0
    _seed_1 = rand_range(0.0, 20.0)
    _seed_2 = rand_range(0.0, 20.0)
    _seed_3 = rand_range(0.0, 20.0)
    _seed_4 = rand_range(0.0, 20.0)

    _history_positions.clear()
    _history_positions.push_back(global_position)
    _init_line_points()


func _on_Hitbox_hit_something(thing_hit: Node, damage_dealt: int) -> void:
    ._on_Hitbox_hit_something(thing_hit, damage_dealt)

    var main = Utils.get_scene_node()
    var pool_id: int = HIT_SPLASH_SCENE.get_instance_id()
    var splash = main.get_node_from_pool(pool_id, main._effects)
    if splash == null:
        splash = HIT_SPLASH_SCENE.instance()
        main.add_effect(splash)
        splash.set_meta("pool_id", pool_id)
    splash.play(global_position, main, pool_id)
