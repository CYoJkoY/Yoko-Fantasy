extends Pet
# Flying Blade Pet — orbiting guardian that slashes enemies and spawns
# guard-blade satellites. Coordinator is shared per-player via player metadata.

enum BladeState { GUARD, AIM, WINDUP, SLASH, CHAIN, RETURN }

const FlyingBladeMotion = preload("res://mods-unpacked/Yoko-Fantasy/content/entities/pets/flying_blade/motion_math.gd")
const CombatCoordinator = preload("res://mods-unpacked/Yoko-Fantasy/content/entities/pets/flying_blade/combat_coordinator.gd")
const GuardBladeSatellite = preload("res://mods-unpacked/Yoko-Fantasy/content/entities/pets/flying_blade/guard_blade_satellite.gd")
const _COORD_META_KEY := "_yoko_flying_blade_coordinator"
const _TARGET_REFRESH_INTERVAL := 0.15
const _Z_TRAIL := 16
const _Z_SLASH_CORE := 23

export(String) var damage_tracking_id := ""
export(Resource) var tuning: Resource = null

onready var _body: Sprite = $Animation/Offset/Body
onready var _shadow: Sprite = $Animation/Offset/Shadow
onready var _hitbox: Hitbox = $Animation/Hitbox
onready var _hitbox_collision: CollisionShape2D = $Animation/Hitbox/Collision

var _hitbox_shape: RectangleShape2D
var _base_weapon_stats := MeleeWeaponStats.new()
var _current_weapon_stats := MeleeWeaponStats.new()
var _damage_tracking_id_hash: int = Keys.empty_hash
var _guard_satellite: Node2D = null
var _combat_coordinator: CombatCoordinator = null
var _trail_line: Line2D
var _fragment_particles: Particles2D
var _afterimage_particles: Particles2D
var _state: int = BladeState.GUARD
var _state_ticks: float = 0.0
var _cooldown: float = 0.0
var _orbit_angle: float = rand_range(0.0, TAU)
var _guard_slot_offset: float = 0.0
var _guard_phase: float = rand_range(0.0, TAU)
var _velocity: Vector2 = Vector2.ZERO
var _last_position: Vector2 = Vector2.ZERO
var _attack_target: Node2D = null
var _attack_start: Vector2 = Vector2.ZERO
var _attack_control: Vector2 = Vector2.ZERO
var _attack_end: Vector2 = Vector2.ZERO
var _attack_center: Vector2 = Vector2.ZERO
var _attack_direction: Vector2 = Vector2.RIGHT
var _aim_start: Vector2 = Vector2.ZERO
var _aim_control: Vector2 = Vector2.ZERO
var _aim_end: Vector2 = Vector2.ZERO
var _return_start: Vector2 = Vector2.ZERO
var _return_control: Vector2 = Vector2.ZERO
var _return_end: Vector2 = Vector2.ZERO
var _curve_side: float = 1.0
var _chain_count: int = 0
var _allow_repeat_target: bool = false
var _targets_hit_this_combo: Array = []
var _attack_slot_active: bool = false
var _attack_queued: bool = false
var _attack_hitbox_enabled: bool = true
var _target_refresh_timer: float = 0.0

func _ready() -> void:
    _setup_visuals()
    _setup_combat_coordinator()
    _guard_slot_offset = float(get_index() % 8) * (TAU / 8.0)
    _last_position = global_position
    _cooldown = rand_range(0.0, 1.0)
    _hitbox_shape = _hitbox_collision.shape as RectangleShape2D
    _apply_weapon_stats_to_hitbox()

func init(zone_min_pos: Vector2, zone_max_pos: Vector2, p_players_ref: Array = [], entity_spawner_ref = null) -> void:
    .init(zone_min_pos, zone_max_pos, p_players_ref, entity_spawner_ref)
    _damage_tracking_id_hash = Keys.generate_hash(damage_tracking_id)
    _hitbox.from = self
    _hitbox.damage_tracking_key_hash = _damage_tracking_id_hash
    _hitbox_collision.shape = _hitbox_collision.shape.duplicate()
    _hitbox_shape = _hitbox_collision.shape as RectangleShape2D
    _hitbox.set_as_toplevel(true)
    _setup_combat_coordinator()
    _reset_runtime_state()
    _disable_attack_hitbox()
    _apply_weapon_stats_to_hitbox()

func update_data(effect: PetEffect) -> void:
    .update_data(effect)
    _base_weapon_stats = effect.weapon_stats
    reload_data()

func reload_data() -> void:
    var args := WeaponServiceInitStatsArgs.new()
    _current_weapon_stats = WeaponService.init_melee_pet_stats(_base_weapon_stats, player_index, args)
    _apply_weapon_stats_to_hitbox()
    _setup_guard_satellite()
    _sync_guard_satellite_stats()

func set_current_stats(stats: Array) -> void:
    _current_weapon_stats = stats[0]
    _apply_weapon_stats_to_hitbox()
    _sync_guard_satellite_stats()

func get_stats() -> Array:
    return [_current_weapon_stats]

func _apply_weapon_stats_to_hitbox() -> void:
    _current_weapon_stats.burning_data.from = self
    var hitbox_args := Hitbox.HitboxArgs.new().set_from_weapon_stats(_current_weapon_stats)
    _hitbox.projectiles_on_hit = []
    _hitbox.effect_scale = _current_weapon_stats.effect_scale
    _hitbox.speed_percent_modifier = _current_weapon_stats.speed_percent_modifier
    _hitbox.from = self
    _hitbox.damage_tracking_key_hash = _damage_tracking_id_hash
    _hitbox.set_damage(_current_weapon_stats.damage, hitbox_args)
    if _combat_coordinator:
        _combat_coordinator.request_sensor_radius(_get_target_sensor_radius())

func _setup_visuals() -> void:
    _trail_line = Line2D.new()
    _trail_line.name = "TrailLine"
    _trail_line.width = tuning.trail_line_width
    _trail_line.set_as_toplevel(true)
    _trail_line.global_position = Vector2.ZERO
    var grad := Gradient.new()
    grad.colors = [tuning.trail_gradient_top, tuning.trail_gradient_bottom]
    grad.offsets = [0.0, 1.0]
    _trail_line.gradient = grad
    _trail_line.z_index = _Z_TRAIL
    var tc := Curve.new()
    tc.add_point(Vector2(0, 0))
    tc.add_point(Vector2(0.4, 0.6))
    tc.add_point(Vector2(0.8, 1.0))
    tc.add_point(Vector2(1, 1))
    _trail_line.width_curve = tc
    _trail_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
    _trail_line.end_cap_mode = Line2D.LINE_CAP_ROUND
    add_child(_trail_line)
    _fragment_particles = _make_particles(tuning.fragment_particle_amount, tuning.fragment_particle_lifetime, Color(0.8, 0.6, 1.0, 0.6), 2.0, tuning.fragment_particle_speed, 0.8, 0.8, _Z_SLASH_CORE + 1)
    add_child(_fragment_particles)
    _afterimage_particles = _make_particles(tuning.afterimage_amount, tuning.afterimage_lifetime, Color(0.9, 0.8, 1.0, 0.3), 3.0, 0.0, 1.0, 1.0, 8)
    add_child(_afterimage_particles)

func _make_particles(amount: int, lifetime: float, color: Color, scale: float, velocity: float, damping: float, explosiveness: float, z: int) -> Particles2D:
    var p := Particles2D.new()
    p.amount = amount
    p.lifetime = lifetime
    p.one_shot = true
    p.explosiveness = explosiveness
    p.emitting = false
    p.z_index = z
    var mat := ParticlesMaterial.new()
    mat.color = color
    mat.scale = scale
    mat.initial_velocity = velocity
    mat.damping = damping
    mat.gravity = Vector3.ZERO
    mat.flag_disable_z = true
    p.process_material = mat
    return p

func _setup_combat_coordinator() -> void:
    var player := _get_player_node()
    if not player:
        return
    var coord = player.get_meta(_COORD_META_KEY, null)
    if not coord or not is_instance_valid(coord):
        coord = CombatCoordinator.new()
        coord.setup(player_index, players_ref, _get_target_sensor_radius())
        coord.configure_attack_limits(tuning.max_active_main_attacks, tuning.max_active_satellite_attacks, tuning.max_attack_dispatches_per_tick)
        player.set_meta(_COORD_META_KEY, coord)
    _combat_coordinator = coord
    _combat_coordinator.request_sensor_radius(_get_target_sensor_radius())

func _get_player_node() -> Node:
    if player_index >= 0 and player_index < players_ref.size() and is_instance_valid(players_ref[player_index]):
        return players_ref[player_index]
    return null

func _physics_process(delta: float) -> void:
    if dead or _end_of_wave:
        return
    _target_refresh_timer -= delta
    if _target_refresh_timer <= 0.0:
        if _combat_coordinator:
            _combat_coordinator.refresh_targets()
            if not _combat_coordinator._main_queue.empty() or not _combat_coordinator._satellite_queue.empty():
                _combat_coordinator.dispatch_attacks()
        _target_refresh_timer = _TARGET_REFRESH_INTERVAL
    var ticks := Utils.physics_one(delta)
    _cooldown -= ticks
    _state_ticks += ticks
    _guard_phase += delta * tuning.guard_orbit_speed * 0.72
    _last_position = global_position
    match _state:
        BladeState.GUARD: _process_guard(delta)
        BladeState.AIM: _process_aim(delta)
        BladeState.WINDUP: _process_windup(delta)
        BladeState.SLASH: _process_slash(delta)
        BladeState.CHAIN: _process_chain(delta)
        BladeState.RETURN: _process_return(delta)
    _update_trail()
    _update_shadow()

func _process_guard(delta: float) -> void:
    var guard_pos := _get_guard_position(delta)
    _steer_toward(guard_pos, tuning.guard_speed, 16.0, delta)
    _face_guard_orbit(guard_pos, 0.18)
    if _cooldown <= 0.0 and not _attack_queued and not _attack_slot_active:
        _enqueue_coordinated_attack()

func _process_aim(delta: float) -> void:
    if not _is_target_valid(_attack_target):
        _retarget_lost_attack()
        return
    _attack_center = _attack_target.global_position
    var raw := min(_state_ticks / max(tuning.aim_ticks, 1.0), 1.0)
    var progress := FlyingBladeMotion.ease_in_out_cubic(raw)
    var lead := _attack_direction * sin(raw * PI) * -10.0
    var aim_pos := FlyingBladeMotion.bezier2(_aim_start, _aim_control, _aim_end + lead, progress)
    _velocity = (aim_pos - global_position) / max(delta, 0.001)
    global_position = FlyingBladeMotion.clamp_to_zone(aim_pos)
    _attack_direction = global_position.direction_to(_attack_center)
    if _attack_direction == Vector2.ZERO:
        _attack_direction = (_aim_end - _aim_start).normalized()
    _face_direction(_attack_direction, 0.58)
    if _state_ticks >= tuning.aim_ticks or global_position.distance_squared_to(_aim_end) <= 484.0:
        _state = BladeState.WINDUP
        _state_ticks = 0.0

func _process_windup(delta: float) -> void:
    if not _is_target_valid(_attack_target):
        _retarget_lost_attack()
        return
    _attack_center = _attack_target.global_position
    _attack_direction = (_attack_center - global_position).normalized()
    if _attack_direction == Vector2.ZERO:
        _attack_direction = Vector2.RIGHT
    var side := Vector2(-_attack_direction.y, _attack_direction.x) * _curve_side
    var raw := min(_state_ticks / max(tuning.windup_ticks, 1.0), 1.0)
    var pull := FlyingBladeMotion.ease_in_out_cubic(raw)
    var pulse := sin(raw * PI)
    var pullback: Vector2 = _attack_center - _attack_direction * tuning.approach_distance + side * tuning.curve_side_distance * 0.22
    _steer_toward(FlyingBladeMotion.clamp_to_zone(pullback - _attack_direction * (12.0 + pull * 24.0) + side * pulse * 8.0), tuning.return_speed, 34.0, delta)
    _refresh_attack_path(global_position)
    _face_direction(_attack_direction, 0.62)
    _animation.scale = Vector2(1.0 + pulse * 0.07 + pull * 0.06, 1.0 - pulse * 0.04)
    if _state_ticks >= tuning.windup_ticks:
        _begin_slash()

func _process_slash(delta: float) -> void:
    var raw := min(_state_ticks / max(tuning.slash_ticks, 1.0), 1.0)
    var progress := FlyingBladeMotion.ease_out_cubic(raw)
    var next_pos := FlyingBladeMotion.bezier2(_attack_start, _attack_control, _attack_end, progress)
    _velocity = (next_pos - global_position) / max(delta, 0.001)
    global_position = FlyingBladeMotion.clamp_to_zone(next_pos)
    _face_direction(FlyingBladeMotion.bezier2_tangent(_attack_start, _attack_control, _attack_end, progress), 0.78)
    _position_sweep_hitbox(_last_position, global_position)
    if raw > 0.25 and raw < 0.75 and int(raw * 8) % 2 == 0:
        _emit_attack_fragment()
    if raw > 0.15 and raw < 0.85 and int(raw * 6) % 2 == 0:
        _emit_blade_afterimage()
    var squash := sin(raw * PI)
    _animation.scale = Vector2(1.04 + squash * 0.10, 0.96 + squash * 0.03)
    if _state_ticks >= tuning.slash_ticks:
        _state = BladeState.CHAIN
        _state_ticks = 0.0
        _disable_attack_hitbox()

func _process_chain(delta: float) -> void:
    if _state_ticks < 0.2:
        _emit_attack_fragment()
        _emit_blade_afterimage()
    if _state_ticks < tuning.chain_ticks:
        var settle := sin(min(_state_ticks / max(tuning.chain_ticks, 1.0), 1.0) * PI)
        var drift := _attack_end + _attack_direction * 28.0
        _steer_toward(FlyingBladeMotion.clamp_to_zone(drift), tuning.return_speed, 10.0, delta)
        _face_direction(_velocity, 0.42)
        _animation.scale = _animation.scale.linear_interpolate(Vector2(1.0 + settle * 0.05, 1.0), min(1.0, delta * 10.0))
        return
    if _chain_count < tuning.max_chain_hits:
        var next_target := _find_attack_target(_targets_hit_this_combo, global_position, tuning.chain_search_radius)
        if _is_target_valid(next_target):
            _allow_repeat_target = false
            _begin_aim(next_target, true)
            return
        if _is_target_valid(_attack_target):
            _allow_repeat_target = true
            _curve_side *= -1.0
            _begin_aim(_attack_target, true)
            return
    _begin_return()

func _process_return(delta: float) -> void:
    _return_end = _get_guard_position(delta)
    var progress := FlyingBladeMotion.ease_out_cubic(min(_state_ticks / max(10.0, tuning.chain_ticks + 8.0), 1.0))
    var next_pos := FlyingBladeMotion.bezier2(_return_start, _return_control, _return_end, progress)
    _velocity = (next_pos - global_position) / max(delta, 0.001)
    global_position = FlyingBladeMotion.clamp_to_zone(next_pos)
    _face_direction(_velocity, 0.44)
    if progress >= 1.0 or global_position.distance_squared_to(_return_end) <= 576.0:
        _state = BladeState.GUARD
        _state_ticks = 0.0
        _velocity *= 0.16
        _animation.scale = Vector2.ONE
        _trail_line.clear_points()

func _reset_runtime_state() -> void:
    _state = BladeState.GUARD
    _state_ticks = 0.0
    _cooldown = rand_range(0.0, 1.0)
    _attack_target = null
    _attack_direction = Vector2.RIGHT
    _curve_side = 1.0
    _chain_count = 0
    _allow_repeat_target = false
    _targets_hit_this_combo.clear()
    _trail_line.clear_points()
    _velocity = Vector2.ZERO
    _animation.scale = Vector2.ONE
    _animation.rotation = 0
    _attack_slot_active = false
    _attack_queued = false
    _attack_hitbox_enabled = true
    _disable_attack_hitbox()

func _begin_aim(target: Node2D, chaining: bool) -> void:
    _attack_target = target
    _attack_center = target.global_position
    var from_target := global_position.direction_to(_attack_center)
    if from_target == Vector2.ZERO:
        from_target = Vector2.RIGHT
    _attack_direction = from_target
    if not _allow_repeat_target:
        _curve_side = 1.0 if randf() < 0.5 else -1.0
    var side := Vector2(-_attack_direction.y, _attack_direction.x) * _curve_side
    _aim_start = global_position
    _aim_end = FlyingBladeMotion.clamp_to_zone(_attack_center - _attack_direction * tuning.approach_distance + side * tuning.curve_side_distance * 0.30)
    if _aim_start.distance_squared_to(_aim_end) > tuning.aim_snap_distance * tuning.aim_snap_distance:
        _aim_end = _aim_start.linear_interpolate(_aim_end, tuning.aim_snap_distance / _aim_start.distance_to(_aim_end))
    _aim_control = FlyingBladeMotion.clamp_to_zone((_aim_start + _aim_end) * 0.5 + side * tuning.curve_side_distance * 0.60)
    if not chaining:
        _chain_count = 0
        _targets_hit_this_combo.clear()
        _trail_line.clear_points()
    else:
        _trail_line.clear_points()
        _trail_line.add_point(global_position)
    _state = BladeState.AIM
    _state_ticks = 0.0

func _begin_slash() -> void:
    _state = BladeState.SLASH
    _state_ticks = 0.0
    _attack_center = _attack_target.global_position if _is_target_valid(_attack_target) else _attack_center
    _attack_direction = global_position.direction_to(_attack_center)
    if _attack_direction == Vector2.ZERO:
        _attack_direction = Vector2.RIGHT
    _refresh_attack_path(global_position)
    _chain_count += 1
    _hitbox.ignored_objects.clear()
    for t in _targets_hit_this_combo:
        if is_instance_valid(t):
            _hitbox.ignored_objects.push_back(t)
    _allow_repeat_target = false
    _enable_attack_hitbox()

func _begin_return(apply_cooldown: bool = true) -> void:
    _release_attack_slot()
    _state = BladeState.RETURN
    _state_ticks = 0.0
    _trail_line.clear_points()
    _return_start = global_position
    var return_dir := _velocity.normalized() if _velocity.length_squared() > 0.01 else _attack_direction
    var return_side := Vector2(-return_dir.y, return_dir.x) * _curve_side
    _return_end = _get_guard_position(0.0)
    _return_control = FlyingBladeMotion.clamp_to_zone(
        (global_position + _return_end) * 0.5 + return_dir * tuning.return_curve_distance * 0.45 + return_side * tuning.return_curve_distance
    )
    if apply_cooldown:
        _cooldown = _combat_coordinator.get_next_cooldown(_current_weapon_stats.cooldown, CombatCoordinator.ROLE_MAIN) if _combat_coordinator else rand_range(1.0, 2.0)
    else:
        _cooldown = 0.0
    _attack_target = null
    _disable_attack_hitbox()
    _animation.scale = Vector2.ONE

func _enqueue_coordinated_attack() -> void:
    if _combat_coordinator:
        _attack_queued = _combat_coordinator.enqueue_attack(self, CombatCoordinator.ROLE_MAIN)

func get_coordinated_attack_target() -> Node2D:
    _attack_queued = false
    _targets_hit_this_combo.clear()
    return _find_attack_target(_targets_hit_this_combo, _get_player_position(), _get_attack_range())

func begin_coordinated_attack(target: Node2D) -> void:
    _attack_queued = false
    if not _is_target_valid(target):
        coordinated_attack_failed()
        return
    _attack_slot_active = true
    _attack_target = target
    _begin_aim(target, false)

func coordinated_attack_failed() -> void:
    _attack_queued = false
    _attack_slot_active = false
    _attack_target = null

func _release_attack_slot() -> void:
    if _attack_slot_active:
        _attack_slot_active = false
        if _combat_coordinator:
            _combat_coordinator.release_attack(self, CombatCoordinator.ROLE_MAIN)

func _retarget_lost_attack() -> void:
    var next_target := _find_attack_target(_targets_hit_this_combo, _get_player_position(), _get_attack_range())
    if _is_target_valid(next_target):
        _begin_aim(next_target, _chain_count > 0)
    else:
        _begin_return(_chain_count > 0)

func _find_attack_target(excluded: Array, origin: Vector2, radius: float) -> Node2D:
    if not _combat_coordinator:
        return null
    var best: Node2D = null
    var best_score := INF
    var radius_sq := radius * radius
    var min_dist_sq := _current_weapon_stats.min_range * _current_weapon_stats.min_range
    for target in _combat_coordinator.get_targets():
        if not _is_target_valid(target) or excluded.has(target):
            continue
        var dist_sq := origin.distance_squared_to(target.global_position)
        if dist_sq < min_dist_sq or dist_sq > radius_sq:
            continue
        if dist_sq < best_score:
            best_score = dist_sq
            best = target
    return best

func _is_target_valid(target: Node) -> bool:
    return is_instance_valid(target) and not target.dead

func _get_attack_range() -> float:
    return float(_current_weapon_stats.max_range)

func _get_target_sensor_radius() -> float:
    return max(_get_attack_range(), tuning.chain_search_radius) + tuning.guard_radius + 200.0

func _get_guard_position(delta: float) -> Vector2:
    _orbit_angle += tuning.guard_orbit_speed * delta
    var angle := _orbit_angle + _guard_slot_offset
    var depth := sin(angle)
    var wave := sin(angle * 2.0 + _guard_phase * tuning.guard_wave_speed)
    var radius: float = tuning.guard_radius + wave * tuning.guard_wave_height * 0.26
    var offset := Vector2(cos(angle) * radius, depth * radius * 0.46)
    return FlyingBladeMotion.clamp_to_zone(_get_player_position() + offset)

func _get_player_position() -> Vector2:
    var player := _get_player_node()
    return player.global_position if player else global_position

func _steer_toward(target_pos: Vector2, max_speed: float, responsiveness: float, delta: float) -> void:
    var to_target := target_pos - global_position
    var desired := Vector2.ZERO
    if to_target.length_squared() > 1.0:
        var speed := min(max_speed, max(160.0, to_target.length() * responsiveness))
        desired = to_target.normalized() * speed
    _velocity = _velocity.linear_interpolate(desired, clamp(responsiveness * delta, 0.0, 1.0))
    global_position = FlyingBladeMotion.clamp_to_zone(global_position + _velocity * delta)

func _face_direction(direction: Vector2, weight: float) -> void:
    if direction.length_squared() <= 0.1:
        return
    _animation.rotation = lerp_angle(_animation.rotation, direction.angle() + PI / 2.0, weight)

func _face_guard_orbit(guard_pos: Vector2, weight: float) -> void:
    var side := clamp((guard_pos.x - _get_player_position().x) / max(tuning.guard_radius, 1.0), -1.0, 1.0)
    _animation.rotation = lerp_angle(_animation.rotation, PI + side * tuning.guard_tilt_strength, weight)

func _refresh_attack_path(start_pos: Vector2) -> void:
    var side := Vector2(-_attack_direction.y, _attack_direction.x) * _curve_side
    _attack_start = start_pos
    _attack_end = FlyingBladeMotion.clamp_to_zone(_attack_center + _attack_direction * tuning.exit_distance)
    _attack_control = FlyingBladeMotion.clamp_to_zone(
        (_attack_start + _attack_end) * 0.5 + side * tuning.curve_side_distance
    )

func _position_sweep_hitbox(from_pos: Vector2, to_pos: Vector2) -> void:
    var movement := to_pos - from_pos
    if movement.length_squared() <= 1.0:
        movement = _attack_direction * 8.0
    var length: float = movement.length() + tuning.exit_distance * 0.55
    _hitbox.global_position = (from_pos + to_pos) * 0.5
    _hitbox.global_rotation = movement.angle()
    _hitbox_collision.position = Vector2.ZERO
    _hitbox_shape.extents = Vector2(max(24.0, length * 0.5), tuning.sweep_width)
    _hitbox.set_knockback(movement.normalized(), _current_weapon_stats.knockback, _current_weapon_stats.knockback_piercing)

func _enable_attack_hitbox() -> void:
    if not _attack_hitbox_enabled:
        _attack_hitbox_enabled = true
        _hitbox.active = true
        _hitbox.enable()

func _disable_attack_hitbox() -> void:
    if _attack_hitbox_enabled:
        _attack_hitbox_enabled = false
        _hitbox.disable()
        _hitbox.active = false
        _hitbox.ignored_objects.clear()

func _update_trail() -> void:
    _trail_line.visible = (_state == BladeState.SLASH) or (_state == BladeState.CHAIN)
    if not _trail_line.visible:
        return
    var pos := global_position
    var n := _trail_line.get_point_count()
    var sample_sq: int = tuning.trail_sample_min_distance * tuning.trail_sample_min_distance
    if n == 0 or _trail_line.get_point_position(n - 1).distance_squared_to(pos) > sample_sq:
        _trail_line.add_point(pos)
    while _trail_line.get_point_count() > tuning.trail_max_points:
        _trail_line.remove_point(0)

func _update_shadow() -> void:
    var attacking: bool = (_state == BladeState.SLASH) or (_state == BladeState.CHAIN)
    _shadow.visible = attacking

func _emit_attack_fragment() -> void:
    if _fragment_particles.emitting:
        return
    _fragment_particles.global_position = global_position
    _fragment_particles.process_material.color = Color(0.8, 0.6, 1.0, 0.8)
    _fragment_particles.emitting = true

func _emit_blade_afterimage() -> void:
    if _afterimage_particles.emitting:
        return
    _afterimage_particles.global_position = _body.global_position
    _afterimage_particles.emitting = true

func _show_hit_flash(hit_pos: Vector2) -> void:
    _fragment_particles.global_position = hit_pos
    _fragment_particles.process_material.color = Color(1.0, 1.0, 1.0, 0.9)
    _fragment_particles.emitting = true

func _on_Hitbox_hit_something(thing_hit: Node, _damage_dealt: int) -> void:
    RunData.manage_life_steal(_current_weapon_stats, player_index)
    if not _hitbox.ignored_objects.has(thing_hit):
        _hitbox.ignored_objects.push_back(thing_hit)
    if not _targets_hit_this_combo.has(thing_hit):
        _targets_hit_this_combo.push_back(thing_hit)
    if thing_hit is Node2D:
        _show_hit_flash(thing_hit.global_position)
    _emit_attack_fragment()

func _setup_guard_satellite() -> void:
    if is_instance_valid(_guard_satellite):
        _guard_satellite.shutdown()
        _guard_satellite = null
    var player := _get_player_node()
    if not player or _damage_tracking_id_hash == Keys.empty_hash:
        return
    _setup_combat_coordinator()
    if not is_instance_valid(_combat_coordinator):
        return
    _guard_satellite = GuardBladeSatellite.new()
    _guard_satellite.name = "%sGuardSatellite" % name
    get_parent().add_child(_guard_satellite)
    _guard_satellite.setup(_get_guard_satellite_config())

func _sync_guard_satellite_stats() -> void:
    if is_instance_valid(_guard_satellite):
        _guard_satellite.sync_weapon_stats(_current_weapon_stats)

func _get_guard_satellite_config() -> Dictionary:
    return {
        "owner": self,
        "coordinator": _combat_coordinator,
        "player_index": player_index,
        "players_ref": players_ref,
        "weapon_stats": _current_weapon_stats,
        "damage_tracking_key_hash": _damage_tracking_id_hash,
        "tuning": tuning,
        "texture": _body.texture,
        "centered": _body.centered,
        "offset": _body.offset,
        "flip_h": _body.flip_h,
        "flip_v": _body.flip_v,
    }

func _free_guard_satellite() -> void:
    if is_instance_valid(_guard_satellite):
        _guard_satellite.shutdown()
        _guard_satellite = null

func _unregister_from_coordinator() -> void:
    _combat_coordinator = null
