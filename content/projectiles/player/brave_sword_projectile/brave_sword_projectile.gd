extends PlayerProjectile

const LASER_COUNT: int = 6
const LASER_DURATION: float = 0.55

const WAVE_GROW_DURATION: float = 0.16
const WAVE_START_SCALE := Vector2(0.10, 0.12)
const WAVE_END_SCALE := Vector2(0.88, 1.38)
const WAVE_BASE_COLLISION_POS := Vector2(-27.0, -20.0)

var _is_laser_mode: bool = true
var _elapsed: float = 0.0
var _visual_opacity: float = 1.0
var _wave_scale_finished: bool = false

# 六芒星阵动态几何参数
var _hex_base_angle: float = 0.0
var _hex_rot_speed: float = 0.0
var _hex_start_radius: float = 65.0
var _hex_target_radius: float = 195.0

var _laser_visuals: Array = []
var _laser_collisions: Array = []

onready var _particles: CPUParticles2D = $"%CPUParticles2D" as CPUParticles2D
onready var _wave_collision: CollisionShape2D = $Hitbox/Collision as CollisionShape2D
onready var _laser_container: Node2D = $LaserContainer as Node2D


func _ready() -> void:
    _laser_visuals.clear()
    _laser_collisions.clear()
    for i in range(LASER_COUNT):
        var beam = _laser_container.get_node_or_null("LaserBeam%d" % i)
        if beam:
            _laser_visuals.push_back(beam)
        var col = _hitbox.get_node_or_null("LaserCollision%d" % i)
        if col:
            _laser_collisions.push_back(col)


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
    _elapsed = 0.0

    _is_laser_mode = true
    var actual_spawn_pos: Vector2 = pos

    if is_instance_valid(p_from):
        var shot_idx = p_from.get("_nb_shots_taken")
        if shot_idx != null:
            _is_laser_mode = (int(shot_idx) % 2 != 0)
        else:
            _is_laser_mode = not bool(p_from.get_meta("fa_laser_state", false))
            p_from.set_meta("fa_laser_state", _is_laser_mode)

        if _is_laser_mode:
            actual_spawn_pos = p_from.global_position
            p_velocity = Vector2.ZERO
            p_rotation = 0.0
        else:
            actual_spawn_pos = p_from.global_position + Vector2(18.0, 0.0).rotated(p_rotation)

    .shoot_ex(
        p_from,
        actual_spawn_pos,
        p_velocity,
        p_rotation,
        p_weapon_stats,
        damage_tracking_key,
        effects,
        hitbox_args,
        knockback_direction
    )


func shoot() -> void:
    .shoot()
    _visual_opacity = ProgressData.settings.projectile_opacity

    if _is_laser_mode:
        _piercing = 9999
        _bounce = 0
        destroy_on_leaving_screen = false
        _time_until_max_range = LASER_DURATION
        _sprite.visible = false
        _particles.emitting = false
        _wave_collision.set_deferred("disabled", true)
        _setup_lasers()
    else:
        if _weapon_stats != null:
            _piercing = _weapon_stats.piercing if "piercing" in _weapon_stats else 0
            _bounce = _weapon_stats.bounce if "bounce" in _weapon_stats else 0

        destroy_on_leaving_screen = true
        _wave_scale_finished = false

        _sprite.visible = true
        _sprite.modulate = Color(1.0, 1.0, 1.0, _visual_opacity)
        _sprite.scale = WAVE_START_SCALE

        _particles.visible = true
        _particles.modulate.a = _visual_opacity
        _particles.scale = WAVE_START_SCALE
        _particles.emitting = true
        _particles.restart()

        _wave_collision.position = WAVE_BASE_COLLISION_POS * WAVE_START_SCALE
        _wave_collision.scale = Vector2.ONE * WAVE_START_SCALE.x
        _wave_collision.set_deferred("disabled", false)

        _disable_lasers()


func _setup_lasers() -> void:
    # 1. 每次发射生成随机整体旋转基角与极细微的缓动自转角速度
    _hex_base_angle = rand_range(0.0, TAU)
    _hex_rot_speed = rand_range(-0.25, 0.25)

    # 2. 随机内收/外展起始区间：由内至外平滑外扩横扫
    _hex_start_radius = rand_range(50.0, 75.0)
    _hex_target_radius = _hex_start_radius + rand_range(110.0, 150.0)

    # 3. 初始化首帧六芒星位置并启用碰撞
    _update_hexagram_transforms(_hex_base_angle, _hex_start_radius)

    for i in range(_laser_visuals.size()):
        _laser_visuals[i].visible = true
    for i in range(_laser_collisions.size()):
        _laser_collisions[i].set_deferred("disabled", false)

    _laser_container.modulate = Color(1.0, 1.0, 1.0, _visual_opacity)


func _update_hexagram_transforms(base_rot: float, radius: float) -> void:
    var angle_step: float = PI / 3.0 # 60度对称

    for i in range(LASER_COUNT):
        # 连接角色与该光束中点的法线方向
        var normal_angle: float = base_rot + float(i) * angle_step
        var normal_dir: Vector2 = Vector2.RIGHT.rotated(normal_angle)

        # 光束垂直于向径展开，六道无限光束自然相交为完美六芒星
        var local_pos: Vector2 = normal_dir * radius
        var beam_angle: float = normal_angle + (PI * 0.5)

        if i < _laser_visuals.size():
            var beam_root: Node2D = _laser_visuals[i]
            beam_root.position = local_pos
            beam_root.rotation = beam_angle

        if i < _laser_collisions.size():
            var col: CollisionShape2D = _laser_collisions[i]
            col.position = local_pos
            col.rotation = beam_angle


func _disable_lasers() -> void:
    for i in range(_laser_visuals.size()):
        _laser_visuals[i].visible = false
    for i in range(_laser_collisions.size()):
        _laser_collisions[i].set_deferred("disabled", true)


func _physics_process(delta: float) -> void:
    if _enable_stop_delay:
        return

    _elapsed += delta

    if _is_laser_mode:
        _process_laser_mode()
    else:
        _process_wave_mode()
        ._physics_process(delta)


func _process_laser_mode() -> void:
    var progress: float = _elapsed / LASER_DURATION
    if progress >= 1.0:
        stop()
        return

    # 1. 计算六芒星阵当前的中心旋转与外展半径（带柔和减速的横扫）
    var current_base_rot: float = _hex_base_angle + _hex_rot_speed * _elapsed
    var sweep_t: float = clamp(_elapsed / (LASER_DURATION * 0.75), 0.0, 1.0)
    var sweep_eased: float = 1.0 - pow(1.0 - sweep_t, 2.5)
    var current_radius: float = lerp(_hex_start_radius, _hex_target_radius, sweep_eased)

    # 实时更新 6 束激光与碰撞盒位置，产生物理横扫打击
    _update_hexagram_transforms(current_base_rot, current_radius)

    # 2. 动效曲线：强力展开 -> 辉煌斩杀 -> 优雅渐隐
    var width_scale: float
    var alpha_mult: float

    if progress < 0.12:
        # 0.0s ~ 0.06s 瞬爆成阵
        var t_in: float = progress / 0.12
        width_scale = lerp(0.35, 1.35, sin(t_in * PI * 0.5))
        alpha_mult = lerp(0.5, 1.0, t_in)
    elif progress < 0.65:
        # 0.12s ~ 0.36s 稳定横扫斩杀期
        var t_mid: float = (progress - 0.12) / 0.53
        width_scale = lerp(1.35, 1.0, t_mid)
        alpha_mult = 1.0
    else:
        # 0.36s ~ 0.55s 柔和消散
        var t_out: float = (progress - 0.65) / 0.35
        width_scale = lerp(1.0, 0.06, t_out * t_out)
        alpha_mult = 1.0 - (t_out * t_out)

    _laser_container.modulate.a = _visual_opacity * alpha_mult

    var scale_vec := Vector2(1.0, max(0.01, width_scale))
    for i in range(_laser_visuals.size()):
        _laser_visuals[i].scale = scale_vec


func _process_wave_mode() -> void:
    if _wave_scale_finished:
        return

    if _elapsed >= WAVE_GROW_DURATION:
        _wave_scale_finished = true
        _sprite.scale = WAVE_END_SCALE
        _particles.scale = WAVE_END_SCALE
        _wave_collision.position = WAVE_BASE_COLLISION_POS * WAVE_END_SCALE
        _wave_collision.scale = Vector2.ONE * WAVE_END_SCALE.x
        return

    var grow_t: float = _elapsed / WAVE_GROW_DURATION
    var inv_t: float = 1.0 - grow_t
    var eased: float = 1.0 - inv_t * inv_t * inv_t
    var current_scale: Vector2 = WAVE_START_SCALE.linear_interpolate(WAVE_END_SCALE, eased)

    _sprite.scale = current_scale
    _particles.scale = current_scale
    _wave_collision.position = WAVE_BASE_COLLISION_POS * current_scale
    _wave_collision.scale = Vector2.ONE * current_scale.x


func set_sprite_material(_material: ShaderMaterial) -> void:
    pass


func stop() -> void:
    if _enable_stop_delay:
        return
    _disable_lasers()
    _particles.emitting = false
    .stop()


func _return_to_pool() -> void:
    _disable_lasers()
    _particles.emitting = false
    _sprite.scale = Vector2.ONE
    _wave_collision.position = WAVE_BASE_COLLISION_POS
    _wave_collision.scale = Vector2.ONE
    ._return_to_pool()
