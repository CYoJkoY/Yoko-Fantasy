extends Node2D

enum SatelliteState {
    ORBIT,
    ATTACK,
    RETURN
}

const MotionStreakVisual = preload("res://mods-unpacked/Yoko-Fantasy/content/entities/pets/flying_blade/visuals/motion_streak_visual.gd")
const FlyingBladeMotion = preload("res://mods-unpacked/Yoko-Fantasy/content/entities/pets/flying_blade/motion_math.gd")
const FlyingBladeCombatCoordinator = preload("res://mods-unpacked/Yoko-Fantasy/content/entities/pets/flying_blade/combat_coordinator.gd")
const COMBAT_ROLE = "satellite"

var owner_pet: Node = null
var combat_coordinator = null
var player_index: int = -1
var players_ref: Array = []
var weapon_stats: MeleeWeaponStats = null
var damage_tracking_key_hash: int = Keys.empty_hash

var orbit_radius: float
var orbit_speed: float
var attack_range: float
var attack_cooldown_ticks: float
var attack_ticks: float
var return_ticks: float
var attack_distance: float
var hitbox_length: float
var hitbox_width: float
var knockback: float
var trail_width: float
var trail_aura_width: float
var trail_color: Color
var trail_secondary_color: Color
var trail_core_color: Color

var _state: int = SatelliteState.ORBIT
var _cooldown: float = 0.0
var _state_ticks: float = 0.0
var _target_scan_delay: float = 0.0
var _formation_index: int = 0
var _formation_count: int = 1
var _attack_start: Vector2 = Vector2.ZERO
var _attack_control: Vector2 = Vector2.ZERO
var _attack_end: Vector2 = Vector2.ZERO
var _attack_hitbox_armed: bool = false
var _hitbox_enabled: bool = false
var _attack_queued: bool = false
var _attack_slot_active: bool = false
var _return_start: Vector2 = Vector2.ZERO
var _return_control: Vector2 = Vector2.ZERO
var _return_end: Vector2 = Vector2.ZERO
var _attack_direction: Vector2 = Vector2.RIGHT
var _velocity: Vector2 = Vector2.ZERO
var _target: Node2D = null
var _trail_points: Array = []
var _body: Sprite = null
var _hitbox: Hitbox = null
var _hitbox_collision: CollisionShape2D = null
var _hitbox_shape: RectangleShape2D = null
var _motion_streak_visual = null
var _vfx_pool = null
var _orbit_visual_position: Vector2 = Vector2.ZERO
var _orbit_visual_rotation: float = 0.0
var _orbit_visual_scale: Vector2 = Vector2.ONE
var _orbit_visual_modulate: Color = Color.white
var _orbit_visual_z_index: int = 2
var _visual_level: int = FlyingBladeCombatCoordinator.VISUAL_FULL
var _idle_body_visible: bool = true

func setup(config: Dictionary) -> void:
    owner_pet = config["owner"]
    combat_coordinator = config["coordinator"]
    player_index = config["player_index"]
    players_ref = config["players_ref"]
    weapon_stats = config["weapon_stats"]
    damage_tracking_key_hash = config["damage_tracking_key_hash"]
    var tuning_data = config["tuning"]
    orbit_radius = tuning_data.guard_radius
    orbit_speed = tuning_data.guard_orbit_speed
    attack_range = tuning_data.satellite_attack_range
    attack_cooldown_ticks = tuning_data.satellite_attack_cooldown_ticks
    attack_ticks = tuning_data.satellite_attack_ticks
    return_ticks = tuning_data.satellite_return_ticks
    attack_distance = tuning_data.satellite_attack_distance
    hitbox_length = tuning_data.satellite_hitbox_length
    hitbox_width = tuning_data.satellite_hitbox_width
    knockback = tuning_data.satellite_knockback
    trail_width = tuning_data.trail_width
    trail_aura_width = tuning_data.trail_aura_width
    trail_color = tuning_data.satellite_trail_color
    trail_secondary_color = tuning_data.satellite_trail_secondary_color
    trail_core_color = tuning_data.trail_core_color

    _setup_visual(config["texture"], config["centered"], config["offset"], config["flip_h"], config["flip_v"])
    _setup_hitbox()
    _apply_weapon_stats()
    _register_with_coordinator()
    if is_instance_valid(combat_coordinator):
        _vfx_pool = combat_coordinator.get_vfx_pool()
    _cooldown = _get_next_cooldown(attack_cooldown_ticks)
    _target_scan_delay = _get_scan_offset()
    global_position = _get_orbit_position()

func sync_weapon_stats(stats: MeleeWeaponStats) -> void:
    weapon_stats = stats
    _apply_weapon_stats()

func reset() -> void:
    _cancel_coordinated_attack()
    _state = SatelliteState.ORBIT
    _state_ticks = 0.0
    _target = null
    _attack_hitbox_armed = false
    _trail_points.clear()
    _disable_hitbox()
    _motion_streak_visual.hide_visual()
    _body.visible = true
    _refresh_visibility()

func shutdown() -> void:
    _unregister_from_coordinator()
    queue_free()

func _physics_process(delta: float) -> void:
    if !is_instance_valid(owner_pet) or owner_pet.dead:
        _disable_hitbox()
        visible = false
        return

    var ticks: float = Utils.physics_one(delta)
    _cooldown -= ticks
    _state_ticks += ticks
    _target_scan_delay = max(0.0, _target_scan_delay - ticks)

    match _state:
        SatelliteState.ORBIT:
            _process_orbit(delta)
        SatelliteState.ATTACK:
            _process_attack(delta)
        SatelliteState.RETURN:
            _process_return(delta)

    _fade_attack_visuals(delta)

func _process_orbit(delta: float) -> void:
    _calculate_orbit_visual()
    var previous_position: Vector2 = global_position
    var follow_weight: float = min(1.0, delta * 10.0)
    global_position = global_position.linear_interpolate(_orbit_visual_position, follow_weight)
    _velocity = (global_position - previous_position) / max(delta, 0.001)
    _apply_orbit_body_visual(delta)

    if _cooldown > 0.0:
        return
    if _target_scan_delay > 0.0:
        return
    if _attack_queued or _attack_slot_active:
        return
    _enqueue_coordinated_attack()

func _process_attack(delta: float) -> void:
    if !_is_target_valid(_target):
        _retarget_lost_attack()
        return

    var raw_progress: float = min(_state_ticks / max(attack_ticks, 1.0), 1.0)
    var progress: float = FlyingBladeMotion.ease_out_cubic(raw_progress)
    var next_position: Vector2 = FlyingBladeMotion.bezier2(_attack_start, _attack_control, _attack_end, progress)
    var previous_position: Vector2 = global_position
    global_position = FlyingBladeMotion.clamp_to_zone(next_position)
    _velocity = (global_position - previous_position) / max(delta, 0.001)
    _attack_direction = previous_position.direction_to(global_position)
    if _attack_direction.length_squared() <= 0.1:
        _attack_direction = previous_position.direction_to(_target.global_position)
    if _attack_direction.length_squared() <= 0.1:
        _attack_direction = Vector2.RIGHT
    _face_direction(_attack_direction)
    _update_attack_body_visual(delta)
    var stretch: float = 1.0 + (1.0 - raw_progress) * 0.28
    _body.scale = Vector2(0.66 / max(0.1, sqrt(stretch)), 0.88 * stretch)
    _body.modulate = Color(1.35, 1.22, 1.75, 0.98)

    _position_hitbox(previous_position, global_position)
    if raw_progress >= 0.15 and !_attack_hitbox_armed:
        _attack_hitbox_armed = true
        _enable_hitbox()
    var redraw_visual: bool = _should_redraw_attack_visual()
    if _uses_motion_visual():
        _update_attack_trail(redraw_visual)
    else:
        _motion_streak_visual.hide_visual()

    if _state_ticks >= attack_ticks:
        _begin_return()

func _process_return(delta: float) -> void:
    _calculate_orbit_visual()
    _return_end = _orbit_visual_position
    var progress: float = FlyingBladeMotion.ease_out_cubic(min(_state_ticks / max(return_ticks, 1.0), 1.0))
    var next_position: Vector2 = FlyingBladeMotion.bezier2(_return_start, _return_control, _return_end, progress)
    var previous_position: Vector2 = global_position
    global_position = FlyingBladeMotion.clamp_to_zone(next_position)
    _velocity = (global_position - previous_position) / max(delta, 0.001)
    var direction: Vector2 = previous_position.direction_to(global_position)
    if direction.length_squared() > 0.1:
        _face_direction(direction)
    if global_position.distance_squared_to(_return_end) <= 100.0 * 100.0:
        _apply_orbit_body_visual(delta)
    else:
        _update_attack_body_visual(delta)

    if progress >= 1.0 or global_position.distance_squared_to(_return_end) <= 18.0 * 18.0:
        _state = SatelliteState.ORBIT
        _state_ticks = 0.0
        _velocity *= 0.12
        _trail_points.clear()
        _motion_streak_visual.hide_visual()
        _body.scale = Vector2(0.80, 0.66)
        _body.modulate = Color(1.25, 1.15, 1.50, 0.92)
        _refresh_visibility()

func _begin_attack(target: Node2D) -> void:
    _target = target
    if _attack_slot_active and is_instance_valid(combat_coordinator):
        combat_coordinator.claim_target(self, target, COMBAT_ROLE)
    _state = SatelliteState.ATTACK
    _refresh_visibility()
    _state_ticks = 0.0
    var target_position: Vector2 = target.global_position

    var fan_angle: float = float(_formation_index) * (TAU * 0.382)
    var target_offset: Vector2 = Vector2(cos(fan_angle) * 38.0, sin(fan_angle) * 28.0)
    var strike_target: Vector2 = target_position + target_offset

    _attack_direction = global_position.direction_to(strike_target)
    if _attack_direction.length_squared() <= 0.1:
        _attack_direction = Vector2.RIGHT
    _attack_direction = _attack_direction.normalized()

    var perp: Vector2 = Vector2(-_attack_direction.y, _attack_direction.x)
    var curve_sign: float = 1.0 if (_formation_index % 2 == 0) else -1.0
    var flank_offset: float = (16.0 + float(_formation_index % 5) * 5.0) * curve_sign

    _attack_start = global_position
    _attack_end = FlyingBladeMotion.clamp_to_zone(strike_target + _attack_direction * (attack_distance + float(_formation_index % 4) * 14.0))
    _attack_control = FlyingBladeMotion.clamp_to_zone((_attack_start + strike_target) * 0.5 + perp * flank_offset)
    _position_hitbox(_attack_start, _attack_start + _attack_direction * 4.0)
    _attack_hitbox_armed = false
    _disable_hitbox()

    _trail_points.clear()
    _trail_points.append(_attack_start - _attack_direction * 10.0)
    _trail_points.append(_attack_start)

func _begin_return(apply_cooldown: bool = true) -> void:
    _release_attack_slot()
    _state = SatelliteState.RETURN
    _refresh_visibility()
    _state_ticks = 0.0
    _target_scan_delay = 0.0
    if apply_cooldown:
        _cooldown = _get_next_cooldown(attack_cooldown_ticks)
    else:
        _cooldown = 0.0
        _target_scan_delay = _get_retry_ticks()
    _target = null
    _attack_hitbox_armed = false
    _disable_hitbox()
    _trail_points.clear()
    _return_start = global_position
    _return_end = _get_orbit_position()
    var return_dir: Vector2 = _return_start.direction_to(_return_end)
    if return_dir.length_squared() <= 0.1:
        return_dir = _velocity.normalized()
    if return_dir.length_squared() <= 0.1:
        return_dir = Vector2.RIGHT
    return_dir = return_dir.normalized()

    var return_perp: Vector2 = Vector2(-return_dir.y, return_dir.x)
    var return_side_sign: float = 1.0 if (_formation_index % 2 == 0) else -1.0
    var lateral_spread: float = orbit_radius * (0.32 + float(_formation_index % 4) * 0.10) * return_side_sign
    var forward_push: float = orbit_radius * 0.14

    _return_control = FlyingBladeMotion.clamp_to_zone((_return_start + _return_end) * 0.5 + return_perp * lateral_spread + return_dir * forward_push)

func _setup_visual(texture: Texture, centered: bool, offset: Vector2, flip_h: bool, flip_v: bool) -> void:
    _body = Sprite.new()
    _body.name = "Body"
    _body.texture = texture
    _body.centered = centered
    _body.offset = offset
    _body.flip_h = flip_h
    _body.flip_v = flip_v
    _body.scale = Vector2(0.72, 0.72)
    _body.modulate = Color(1.08, 1.0, 1.24, 0.86)
    z_as_relative = false
    add_child(_body)

    _motion_streak_visual = MotionStreakVisual.new()
    _motion_streak_visual.name = "MotionStreakVisual"
    _motion_streak_visual.z_as_relative = false
    _motion_streak_visual.z_index = 18
    _motion_streak_visual.visible = false
    add_child(_motion_streak_visual)

func _setup_hitbox() -> void:
    _hitbox = Hitbox.new()
    _hitbox.name = "Hitbox"
    _hitbox.collision_layer = Utils.PET_PROJECTILES_BIT
    _hitbox.collision_mask = 0
    _hitbox.from = owner_pet
    _hitbox.damage_tracking_key_hash = damage_tracking_key_hash
    _hitbox.active = false
    _hitbox.set_as_toplevel(true)

    _hitbox_collision = CollisionShape2D.new()
    _hitbox_collision.name = "Collision"
    _hitbox_shape = RectangleShape2D.new()
    _hitbox_shape.extents = Vector2(hitbox_length * 0.5, hitbox_width * 0.5)
    _hitbox_collision.shape = _hitbox_shape
    _hitbox_collision.disabled = true
    _hitbox.add_child(_hitbox_collision)
    add_child(_hitbox)
    _hitbox.connect("hit_something", self, "_on_Hitbox_hit_something")

func _apply_weapon_stats() -> void:
    weapon_stats.burning_data.from = owner_pet
    var hitbox_args = Hitbox.HitboxArgs.new().set_from_weapon_stats(weapon_stats)
    var satellite_damage: int = int(max(1, int(round(float(weapon_stats.damage) * 0.50))))
    _hitbox.projectiles_on_hit = []
    _hitbox.effect_scale = weapon_stats.effect_scale
    _hitbox.speed_percent_modifier = weapon_stats.speed_percent_modifier
    _hitbox.from = owner_pet
    _hitbox.damage_tracking_key_hash = damage_tracking_key_hash
    _hitbox.set_damage(satellite_damage, hitbox_args)

func _enable_hitbox() -> void:
    if _hitbox_enabled:
        return
    _hitbox_enabled = true
    _hitbox.active = true
    _hitbox.ignored_objects.clear()
    _hitbox.enable()

func _disable_hitbox() -> void:
    if !_hitbox_enabled:
        return
    _hitbox_enabled = false
    _hitbox.active = false
    _hitbox.disable()
    _hitbox.ignored_objects.clear()

func _position_hitbox(from_position: Vector2, to_position: Vector2) -> void:
    var movement: Vector2 = to_position - from_position
    if movement.length_squared() <= 1.0:
        movement = _attack_direction * hitbox_length
    var length: float = max(hitbox_length, movement.length())
    _hitbox_shape.extents = Vector2(length * 0.5, hitbox_width * 0.5)
    _hitbox.global_position = (from_position + to_position) * 0.5
    _hitbox.global_rotation = movement.angle()
    _hitbox.set_knockback(movement.normalized(), knockback, 0.0)

func _select_target() -> Node2D:
    if !is_instance_valid(combat_coordinator):
        _register_with_coordinator()
    if !is_instance_valid(combat_coordinator):
        return null
    return combat_coordinator.select_nearest_target(self, global_position, attack_range)

func _enqueue_coordinated_attack() -> void:
    if !is_instance_valid(combat_coordinator):
        _register_with_coordinator()
    if !is_instance_valid(combat_coordinator):
        _target_scan_delay = _get_retry_ticks()
        return
    _attack_queued = combat_coordinator.enqueue_attack(self, COMBAT_ROLE)
    if !_attack_queued:
        _target_scan_delay = _get_retry_ticks()

func get_coordinated_attack_target() -> Node2D:
    _attack_queued = false
    return _select_target()

func begin_coordinated_attack(target: Node2D) -> void:
    _attack_queued = false
    if !_is_target_valid(target):
        coordinated_attack_failed()
        return
    _attack_slot_active = true
    _target_scan_delay = 6.0
    _begin_attack(target)

func coordinated_attack_failed() -> void:
    _attack_queued = false
    _attack_slot_active = false
    _target = null
    _target_scan_delay = _get_retry_ticks()
    if is_instance_valid(combat_coordinator):
        combat_coordinator.release_attack(self, COMBAT_ROLE)

func _retarget_lost_attack() -> void:
    var next_target: Node2D = _select_target()
    if _is_target_valid(next_target):
        _begin_attack(next_target)
        return
    _begin_return(_attack_hitbox_armed)

func _release_attack_slot() -> void:
    if !_attack_slot_active:
        return
    _attack_slot_active = false
    if is_instance_valid(combat_coordinator):
        combat_coordinator.release_attack(self, COMBAT_ROLE)

func _cancel_coordinated_attack() -> void:
    _attack_queued = false
    _attack_slot_active = false
    if is_instance_valid(combat_coordinator):
        combat_coordinator.cancel_attack(self, COMBAT_ROLE)

func _register_with_coordinator() -> void:
    if !is_instance_valid(combat_coordinator):
        if is_instance_valid(owner_pet):
            combat_coordinator = owner_pet.get_combat_coordinator()
    if !is_instance_valid(combat_coordinator):
        return
    combat_coordinator.register_satellite(self)
    combat_coordinator.request_sensor_radius(self, attack_range + orbit_radius + 80.0)

func _unregister_from_coordinator() -> void:
    if is_instance_valid(combat_coordinator):
        combat_coordinator.unregister_satellite(self)
    combat_coordinator = null
    _vfx_pool = null

func _get_next_cooldown(base_ticks: float) -> float:
    if !is_instance_valid(combat_coordinator):
        return rand_range(max(1.0, base_ticks * 0.72), max(1.0, base_ticks * 1.28))
    return combat_coordinator.get_next_cooldown(base_ticks, COMBAT_ROLE)

func _get_retry_ticks() -> float:
    if !is_instance_valid(combat_coordinator):
        return 2.0
    return combat_coordinator.get_retry_ticks(COMBAT_ROLE)

func _get_scan_offset() -> float:
    if !is_instance_valid(combat_coordinator):
        return rand_range(0.0, 6.0)
    return combat_coordinator.get_actor_scan_offset(self, 6.0)

func _should_redraw_attack_visual() -> bool:
    if !is_instance_valid(combat_coordinator):
        return true
    return combat_coordinator.should_redraw_attack_visual(self, _visual_level)

func _is_target_valid(target: Node) -> bool:
    if !is_instance_valid(target):
        return false
    if not (target is Node2D):
        return false
    if target.dead:
        return false
    return true

func _get_orbit_position() -> Vector2:
    _calculate_orbit_visual()
    return _orbit_visual_position

func _get_player_position() -> Vector2:
    if player_index >= 0 and player_index < players_ref.size() and is_instance_valid(players_ref[player_index]):
        return players_ref[player_index].global_position
    if is_instance_valid(owner_pet):
        return owner_pet.global_position
    return global_position

func _uses_motion_visual() -> bool:
    return _visual_level <= FlyingBladeCombatCoordinator.VISUAL_MINIMAL

func set_visual_level(level: int) -> void:
    if level == _visual_level:
        return
    _visual_level = level
    if _visual_level > FlyingBladeCombatCoordinator.VISUAL_MINIMAL:
        _motion_streak_visual.hide_visual()

func set_idle_body_visible(p_visible: bool) -> void:
    _idle_body_visible = p_visible
    _refresh_visibility()

func _refresh_visibility() -> void:
    visible = _state != SatelliteState.ORBIT or _idle_body_visible

func _calculate_orbit_visual() -> void:
    var count: int = int(max(1, _formation_count))
    var phase: float = _get_shared_orbit_phase()
    var final_radius: float = 140.0
    var final_y_scale: float = 0.68
    var current_angle: float = 0.0
    var orbit_dir_sign: float = 1.0
    var base_scale: Vector2 = Vector2(0.72, 0.76)
    var ring_is_outer: bool = false

    if count <= 6:
        var slot_angle: float = float(_formation_index) * TAU / float(count)
        orbit_dir_sign = 1.0
        current_angle = slot_angle + phase * 0.75
        final_radius = orbit_radius * 1.12 + sin(phase * 2.8 + float(_formation_index) * 1.1) * 6.0
        final_y_scale = 0.66
        base_scale = Vector2(0.72, 0.76)
    elif _formation_index < 8:
        var slot_angle: float = float(_formation_index) * TAU / 8.0
        orbit_dir_sign = -1.0
        current_angle = slot_angle - phase * 0.40
        var breath: float = sin(phase * 1.6)
        final_radius = 138.0 - breath * 12.0 + sin(phase * 2.5 + float(_formation_index) * 0.8) * 4.0
        final_y_scale = 0.68
        base_scale = Vector2(0.68, 0.72)
    else:
        ring_is_outer = true
        var outer_total: int = int(max(1, count - 8))
        var outer_index: int = _formation_index - 8
        var slot_angle: float = float(outer_index) * TAU / float(outer_total)
        orbit_dir_sign = 1.0
        current_angle = slot_angle + phase * 0.28
        var tier: int = outer_index % 3
        var tier_stagger: float = float(tier) * 24.0
        var breath: float = sin(phase * 1.6)
        final_radius = 224.0 + breath * 14.0 + tier_stagger + sin(phase * 2.0 + float(outer_index) * 0.6) * 5.0
        final_y_scale = 0.72
        base_scale = Vector2(0.72, 0.76)

    var depth: float = sin(current_angle)
    var depth_pct: float = (depth + 1.0) * 0.5
    var local_offset: Vector2 = Vector2(cos(current_angle) * final_radius, depth * final_radius * final_y_scale)
    var tier_float: float = float((_formation_index - 8) % 3 - 1) * 3.5 if ring_is_outer else 0.0
    var float_bob: float = sin(phase * 3.8 + float(_formation_index) * 1.3) * 5.0 + tier_float
    local_offset.y += float_bob

    var tangent: Vector2 = Vector2(-sin(current_angle) * final_radius, cos(current_angle) * final_radius * final_y_scale) * orbit_dir_sign
    if tangent.length_squared() <= 0.1:
        tangent = Vector2.RIGHT
    tangent = tangent.normalized()

    var bank_roll: float = -sin(current_angle) * orbit_dir_sign * 0.14
    var pitch_tilt: float = sin(phase * 4.2 + float(_formation_index) * 0.9) * 0.06
    var heading_angle: float = tangent.angle() - PI / 2.0 + bank_roll + pitch_tilt

    var pulse: float = 0.95 + sin(phase * 3.2 + float(_formation_index) * 0.5) * 0.05
    var scale: Vector2 = base_scale * pulse * (0.90 + depth_pct * 0.20)

    var slot_fraction: float = float(_formation_index) * TAU / max(1.0, float(count))
    var wave_phase: float = sin(phase * 1.8 - slot_fraction)
    var wave_boost: float = clamp(wave_phase, 0.0, 1.0) * 0.24

    var color: Color = trail_color
    color.r = lerp(color.r, trail_core_color.r, depth_pct * 0.18 + wave_boost)
    color.g = lerp(color.g, trail_core_color.g, depth_pct * 0.18 + wave_boost)
    color.b = lerp(color.b, trail_core_color.b, depth_pct * 0.18 + wave_boost)
    color.a = clamp(color.a * (0.82 + depth_pct * 0.18 + wave_boost * 0.6), 0.22, 0.88)
    scale = scale * (1.0 + wave_boost * 0.08)

    _orbit_visual_position = FlyingBladeMotion.clamp_to_zone(_get_player_position() + local_offset)
    _orbit_visual_rotation = heading_angle
    _orbit_visual_scale = scale
    _orbit_visual_modulate = color
    if ring_is_outer:
        _orbit_visual_z_index = 1 if depth < 0 else 5
    else:
        _orbit_visual_z_index = 2 if depth < 0 else 4

func _apply_orbit_body_visual(delta: float) -> void:
    var weight: float = 1.0 if delta <= 0.0 else min(1.0, delta * 10.0)
    rotation = lerp_angle(rotation, _orbit_visual_rotation, weight)
    _body.scale = _body.scale.linear_interpolate(_orbit_visual_scale, weight)
    _body.modulate = _body.modulate.linear_interpolate(_orbit_visual_modulate, weight)
    z_index = _orbit_visual_z_index

func _update_attack_body_visual(delta: float) -> void:
    var weight: float = min(1.0, delta * 14.0)
    var attack_pulse: float = sin(min(_state_ticks / max(attack_ticks, 1.0), 1.0) * PI)
    _body.scale = _body.scale.linear_interpolate(Vector2(0.76 + attack_pulse * 0.08, 0.70), weight)
    _body.modulate = _body.modulate.linear_interpolate(Color(1.12, 1.02, 1.24, 0.96), weight)
    z_index = 6

func _update_attack_trail(redraw: bool = true) -> void:
    var sample_position: Vector2 = global_position
    if _trail_points.empty() or _trail_points[_trail_points.size() - 1].distance_squared_to(sample_position) >= 8.0 * 8.0:
        _trail_points.append(sample_position)
    while _trail_points.size() > 5:
        _trail_points.pop_front()
    if !redraw:
        return
    var attack_trail_color: Color = Color(trail_color.r * 0.78, trail_color.g * 0.66, trail_color.b * 0.94, min(0.34, trail_color.a * 1.42))
    var attack_secondary_color: Color = Color(trail_secondary_color.r * 0.76, trail_secondary_color.g * 0.84, trail_secondary_color.b, min(0.20, trail_secondary_color.a * 1.35))
    var attack_core_color: Color = Color(trail_core_color.r * 0.82, trail_core_color.g * 0.88, trail_core_color.b, min(0.28, trail_core_color.a * 1.08))
    var speed_ratio: float = clamp(_velocity.length() / max(260.0, orbit_radius * 8.0), 0.34, 1.0)
    _motion_streak_visual.configure(_trail_points, attack_trail_color, attack_secondary_color, attack_core_color, trail_width * 1.18, trail_aura_width * 1.22, 0.82 + speed_ratio * 0.24, _visual_level)

func _fade_attack_visuals(delta: float) -> void:
    if _state != SatelliteState.ATTACK:
        _motion_streak_visual.fade(delta)

func _face_direction(direction: Vector2) -> void:
    if direction.length_squared() <= 0.1:
        return
    rotation = lerp_angle(rotation, direction.angle() - PI / 2.0, 0.48)

func set_formation(index: int, count: int) -> void:
    _formation_count = max(1, count) as int
    _formation_index = int(clamp(index, 0, _formation_count - 1))

func _get_shared_orbit_phase() -> float:
    if is_instance_valid(combat_coordinator):
        return combat_coordinator.get_orbit_phase(orbit_speed)
    return float(OS.get_ticks_msec()) * 0.001 * orbit_speed * 0.72

func _on_Hitbox_hit_something(thing_hit: Node, _damage_dealt: int) -> void:
    RunData.manage_life_steal(weapon_stats, player_index)
    if !_hitbox.ignored_objects.has(thing_hit):
        _hitbox.ignored_objects.push_back(thing_hit)
    if !is_instance_valid(_vfx_pool) and is_instance_valid(combat_coordinator):
        _vfx_pool = combat_coordinator.get_vfx_pool()
    if is_instance_valid(_vfx_pool) and thing_hit is Node2D and _visual_level < FlyingBladeCombatCoordinator.VISUAL_ESSENTIAL:
        var direction: Vector2 = _attack_direction
        if direction.length_squared() <= 0.1:
            direction = Vector2.RIGHT
        var hit_pos: Vector2 = thing_hit.global_position
        var hit_dir: Vector2 = direction.normalized()
        _vfx_pool.emit_hit_flash(hit_pos, hit_dir, trail_core_color, 18.0, 0.08, 24)
