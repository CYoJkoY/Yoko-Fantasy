extends PlayerProjectile

const HIT_SPLASH_SCENE = preload("res://mods-unpacked/Yoko-Fantasy/content/projectiles/player/myriad_windblades_projectile/myriad_windblades_hit_splash.tscn")
const WIND_FORCE_SCENE = preload("res://mods-unpacked/Yoko-Fantasy/content/projectiles/player/myriad_windblades_projectile/wind_force_effect.tscn")
const MYRIAD_WINDBLADES_EFFECT = preload("res://mods-unpacked/Yoko-Fantasy/content/weapons/ranged/myriad_windblades/myriad_windblades_effect.gd")
const AFTERIMAGE_CORE_TEXTURE = preload("res://mods-unpacked/Yoko-Fantasy/content/projectiles/player/myriad_windblades_projectile/windblade_crescent_core.webp")
const AFTERIMAGE_GLOW_TEXTURE = preload("res://mods-unpacked/Yoko-Fantasy/content/projectiles/player/myriad_windblades_projectile/windblade_crescent_glow.webp")

const TRAIL_SAMPLE_COUNT: int = 20
const TRAIL_SAMPLE_SPACING: float = 7.0
const AFTERIMAGE_POINT_INDICES: Array = [2, 4, 6, 9, 12, 15, 19]
const BLADE_OFFSET: Vector2 = Vector2(24.0, 0.0)
const PROJECTILE_VISUAL_SCALE: float = 1.38
const BLADE_SCALE: float = 0.828
const RELEASE_TENSION_DURATION: float = 0.065
const STREAM_TRAIL_HALF_WIDTH: float = 256.0
const STREAM_TRAIL_ATTACH_X: float = 46.0
const STREAM_TRAIL_LENGTH_SCALE: float = 0.75
const STREAM_TRAIL_HEIGHT_SCALE: float = 0.56
const STREAM_TRAIL_GROW_DURATION: float = 0.1725

var wind_force_ticks: int
var wind_force_base_damage: int
var wind_force_scaling_stats: Array
var wind_force_tick_interval: float

var _elapsed_time: float = 0.0
var _flight_age: float = 0.0
var _seed_1: float = 0.0
var _seed_2: float = 0.0
var _visual_opacity: float = 1.0
var _history_positions: Array = []
var _trail_sample_points: Array = []
var _afterimage_sprites: Array = []

onready var _stream_trail_sprite: Sprite = $"%StreamTrailSprite" as Sprite
onready var _afterimage_layer: Node2D = $"%AfterimageLayer" as Node2D
onready var _blade_root: Node2D = $"%BladeRoot" as Node2D
onready var _glow_sprite: Sprite = $"%GlowSprite" as Sprite
onready var _streak_sprite: Sprite = $"%StreakSprite" as Sprite
onready var _core_sprite: Sprite = $"%CoreSprite" as Sprite
onready var _tip_particles_top: CPUParticles2D = $"%TipParticlesTop" as CPUParticles2D
onready var _tip_particles_bottom: CPUParticles2D = $"%TipParticlesBottom" as CPUParticles2D


func _ready() -> void:
    _sprite.texture = null
    _sprite.visible = false
    _create_afterimage_sprites()
    _init_trail_samples()


func _create_afterimage_sprites() -> void:
    for image_index in range(AFTERIMAGE_POINT_INDICES.size()):
        var afterimage := Sprite.new()
        afterimage.name = "BladeAfterimage%s" % image_index
        afterimage.texture = AFTERIMAGE_CORE_TEXTURE if image_index < 3 else AFTERIMAGE_GLOW_TEXTURE
        afterimage.material = _glow_sprite.material
        afterimage.visible = false
        _afterimage_layer.add_child(afterimage)
        _afterimage_sprites.push_back(afterimage)


func _init_trail_samples() -> void:
    if _trail_sample_points.size() != TRAIL_SAMPLE_COUNT:
        _trail_sample_points.resize(TRAIL_SAMPLE_COUNT)
    for point_index in range(TRAIL_SAMPLE_COUNT):
        _trail_sample_points[point_index] = Vector2.ZERO


func shoot_ex(
    p_from: Node,
    pos: Vector2,
    p_velocity: Vector2,
    p_rotation: float,
    p_weapon_stats: WeaponStats,
    damage_tracking_key: int,
    effects: Array,
    hitbox_args: Hitbox.HitboxArgs,
    knockback_direction: Vector2
) -> void:
    _configure_effect(effects)

    _elapsed_time = rand_range(0.0, 10.0)
    _flight_age = 0.0
    _seed_1 = rand_range(0.0, 100.0)
    _seed_2 = rand_range(0.0, 100.0)
    _history_positions.clear()
    _history_positions.push_back(pos)
    _reset_visual_state()
    var stream_material: ShaderMaterial = _stream_trail_sprite.material as ShaderMaterial
    stream_material.set_shader_param("phase", _seed_1)

    .shoot_ex(p_from, pos, p_velocity, p_rotation, p_weapon_stats, damage_tracking_key, effects, hitbox_args, knockback_direction)


func _configure_effect(effects: Array) -> void:
    var wind_force_effect = null
    for effect in effects:
        if effect.get_script() == MYRIAD_WINDBLADES_EFFECT:
            wind_force_effect = effect
            break

    assert(wind_force_effect != null, "Myriad Windblades effect is missing")
    wind_force_ticks = wind_force_effect.wind_force_ticks
    wind_force_base_damage = wind_force_effect.base_damage
    wind_force_scaling_stats = wind_force_effect.scaling_stats
    wind_force_tick_interval = wind_force_effect.wind_force_tick_interval


func shoot() -> void:
    .shoot()
    _visual_opacity = ProgressData.settings.projectile_opacity
    _blade_root.modulate.a = _visual_opacity
    _afterimage_layer.modulate.a = _visual_opacity
    _stream_trail_sprite.modulate.a = 0.0
    _tip_particles_top.modulate.a = _visual_opacity * 0.12
    _tip_particles_bottom.modulate.a = _visual_opacity * 0.12
    _start_emitter(_tip_particles_top)
    _start_emitter(_tip_particles_bottom)


func _start_emitter(emitter: CPUParticles2D) -> void:
    emitter.emitting = true
    emitter.restart()


func _physics_process(delta: float) -> void:
    if _enable_stop_delay:
        return

    _elapsed_time += delta
    _flight_age += delta
    var release_progress: float = clamp(_flight_age / RELEASE_TENSION_DURATION, 0.0, 1.0)
    var release_tension: float = 1.0 - release_progress

    var stretch_x: float = 1.04 + 0.34 * release_tension + 0.008 * sin(33.0 * _elapsed_time + _seed_1)
    var squish_y: float = 0.97 - 0.25 * release_tension
    _blade_root.scale = Vector2(stretch_x, squish_y) * PROJECTILE_VISUAL_SCALE
    _blade_root.rotation = sin(49.0 * _elapsed_time + _seed_2) * 0.005

    var wind_signal: float = sin(21.0 * _elapsed_time + _seed_1) + 0.5 * sin(37.0 * _elapsed_time + _seed_2)
    var wind_presence: float = clamp((wind_signal - 0.08) * 0.62, 0.0, 1.0)

    _glow_sprite.modulate.a = 0.18 + 0.10 * wind_presence
    _streak_sprite.modulate.a = 0.12 + 0.58 * wind_presence
    _core_sprite.modulate.a = 0.95 + 0.05 * sin(17.0 * _elapsed_time + _seed_1)

    var trail_growth_progress: float = clamp(_flight_age / STREAM_TRAIL_GROW_DURATION, 0.0, 1.0)
    var trail_growth: float = 1.0 - pow(1.0 - trail_growth_progress, 3.0)
    var stream_length: float = STREAM_TRAIL_LENGTH_SCALE * trail_growth
    var stream_height: float = (
        (STREAM_TRAIL_HEIGHT_SCALE + 0.08 * wind_presence)
        * lerp(0.72, 1.0, trail_growth)
    )
    _stream_trail_sprite.position.x = (
        STREAM_TRAIL_ATTACH_X - STREAM_TRAIL_HALF_WIDTH * stream_length
    )
    _stream_trail_sprite.position.y = sin(12.0 * _elapsed_time + _seed_2) * 0.8
    _stream_trail_sprite.scale = Vector2(stream_length, stream_height)
    _stream_trail_sprite.rotation = sin(10.0 * _elapsed_time + _seed_1) * 0.008
    _stream_trail_sprite.modulate = Color(
        1.0,
        1.0,
        1.0,
        _visual_opacity * release_progress * trail_growth * (0.22 + 0.14 * wind_presence)
    )

    var particle_alpha: float = _visual_opacity * (0.10 + 0.24 * wind_presence)
    _tip_particles_top.modulate.a = particle_alpha
    _tip_particles_bottom.modulate.a = particle_alpha
    if _history_positions.empty() or global_position.distance_squared_to(_history_positions.front()) >= 16.0:
        _history_positions.push_front(global_position)
    _update_trail_samples_and_afterimages(wind_presence)


func _update_trail_samples_and_afterimages(wind_presence: float) -> void:
    if _history_positions.size() < 2:
        _hide_afterimages()
        return

    _trail_sample_points[0] = Vector2.ZERO
    var required_distance: float = float(TRAIL_SAMPLE_COUNT - 1) * TRAIL_SAMPLE_SPACING
    var available_distance: float = 0.0

    for i in range(1, _history_positions.size()):
        available_distance += (_history_positions[i] - _history_positions[i - 1]).length()
        if available_distance >= required_distance:
            _history_positions.resize(i + 1)
            break

    var history_index: int = 1
    var previous_distance: float = 0.0
    var current_distance: float = (_history_positions[1] - _history_positions[0]).length()

    for point_index in range(1, TRAIL_SAMPLE_COUNT):
        var target_distance: float = min(float(point_index) * TRAIL_SAMPLE_SPACING, available_distance)
        while history_index < _history_positions.size() - 1 and current_distance < target_distance:
            history_index += 1
            previous_distance = current_distance
            current_distance += (_history_positions[history_index] - _history_positions[history_index - 1]).length()

        var segment_progress: float = (target_distance - previous_distance) / max(0.0001, current_distance - previous_distance)
        var world_point: Vector2 = _history_positions[history_index - 1].linear_interpolate(
            _history_positions[history_index],
            segment_progress
        )
        var local_point: Vector2 = to_local(world_point)
        _trail_sample_points[point_index] = local_point

    _update_afterimages(available_distance, wind_presence)


func _update_afterimages(available_distance: float, wind_presence: float) -> void:
    for image_index in range(AFTERIMAGE_POINT_INDICES.size()):
        var afterimage: Sprite = _afterimage_sprites[image_index]
        var point_index: int = AFTERIMAGE_POINT_INDICES[image_index]
        var target_distance: float = float(point_index) * TRAIL_SAMPLE_SPACING
        if available_distance + 0.1 < target_distance:
            afterimage.visible = false
            continue

        var fade_progress: float = float(image_index) / float(AFTERIMAGE_POINT_INDICES.size() - 1)
        var local_position: Vector2 = _trail_sample_points[point_index] + BLADE_OFFSET
        local_position.y += sin(_seed_2 + float(image_index) * 2.1 + _elapsed_time * 7.0) * fade_progress * 1.4
        afterimage.position = local_position
        var image_scale: float = BLADE_SCALE * lerp(0.96, 0.76, fade_progress)
        afterimage.scale = Vector2(image_scale * lerp(1.12, 1.28, fade_progress), image_scale * lerp(1.0, 0.90, fade_progress))
        var image_alpha: float = lerp(0.32, 0.035, fade_progress) * (0.80 + 0.20 * wind_presence)
        afterimage.modulate = Color(0.52, 0.90, 1.0, image_alpha)
        afterimage.visible = true


func _hide_afterimages() -> void:
    for afterimage in _afterimage_sprites:
        afterimage.visible = false


func _on_Hitbox_hit_something(thing_hit: Node, damage_dealt: int) -> void:
    var will_pierce: bool = _bounce <= 0 and _piercing > 0
    var impact_rotation: float = velocity.angle() if velocity.length_squared() > 1.0 else rotation

    if (
        will_pierce
        and damage_dealt > 0
        and is_instance_valid(thing_hit)
        and thing_hit is Enemy
        and not thing_hit.dead
        and thing_hit.current_stats.health > 0
    ):
        _apply_internal_wind_force(thing_hit)

    _spawn_hit_splash(global_position, impact_rotation)
    ._on_Hitbox_hit_something(thing_hit, damage_dealt)


func _apply_internal_wind_force(enemy: Enemy) -> void:
    var main = Utils.get_scene_node()
    if not is_instance_valid(main):
        return

    var pool_id: int = WIND_FORCE_SCENE.get_instance_id()
    var wind_force = main.get_node_from_pool(pool_id, main._effects)
    if wind_force == null:
        wind_force = WIND_FORCE_SCENE.instance()
        main.add_effect(wind_force)
        wind_force.set_meta("pool_id", pool_id)

    var p_idx: int = _get_player_index()
    var tick_dmg: int = max(1, int(Utils.ncl_get_dmg_with_scaling_stats(wind_force_base_damage, wind_force_scaling_stats, p_idx)))
    var crit_ch: float = _hitbox.crit_chance if _hitbox != null else 0.05
    var crit_dmg: float = _hitbox.crit_damage if _hitbox != null else 2.0
    var weapon_pos: int = _hitbox.from.weapon_pos

    wind_force.init_wind_force(
        enemy,
        wind_force_ticks,
        tick_dmg,
        wind_force_tick_interval,
        p_idx,
        weapon_pos,
        crit_ch,
        crit_dmg,
        main,
        pool_id
    )


func _spawn_hit_splash(pos: Vector2, impact_rotation: float) -> void:
    var main = Utils.get_scene_node()
    if not is_instance_valid(main):
        return

    var pool_id: int = HIT_SPLASH_SCENE.get_instance_id()
    var splash = main.get_node_from_pool(pool_id, main._effects)
    if splash == null:
        splash = HIT_SPLASH_SCENE.instance()
        main.add_effect(splash)
        splash.set_meta("pool_id", pool_id)
    splash.play(pos, impact_rotation, main, pool_id)


func bounce(thing_hit: Node) -> void:
    .bounce(thing_hit)
    _history_positions.clear()
    _history_positions.push_back(global_position)
    _hide_afterimages()


func stop() -> void:
    if _enable_stop_delay:
        return
    _stop_emitters()
    .stop()


func _stop_emitters() -> void:
    _tip_particles_top.emitting = false
    _tip_particles_bottom.emitting = false


func _reset_visual_state() -> void:
    _blade_root.rotation = 0.0
    _blade_root.scale = Vector2.ONE * PROJECTILE_VISUAL_SCALE
    _glow_sprite.modulate.a = 0.18
    _streak_sprite.modulate.a = 0.0
    _core_sprite.modulate.a = 1.0
    _stream_trail_sprite.position = Vector2(
        STREAM_TRAIL_ATTACH_X,
        0.0
    )
    _stream_trail_sprite.scale = Vector2(0.0, STREAM_TRAIL_HEIGHT_SCALE * 0.72)
    _stream_trail_sprite.rotation = 0.0
    _stream_trail_sprite.modulate = Color(1.0, 1.0, 1.0, 0.0)
    _hide_afterimages()


func _return_to_pool() -> void:
    _stop_emitters()
    _history_positions.clear()
    ._return_to_pool()
