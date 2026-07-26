extends Node2D

enum SatelliteState {
    ORBIT,
    ATTACK,
    RETURN
}

const MotionStreakVisual = preload("res://mods-unpacked/Yoko-Fantasy/content/entities/pets/flying_blade/visuals/motion_streak_visual.gd")
const PierceStreakVisual = preload("res://mods-unpacked/Yoko-Fantasy/content/entities/pets/flying_blade/visuals/pierce_streak_visual.gd")
const GuardBladeOrbitVisual = preload("res://mods-unpacked/Yoko-Fantasy/content/entities/pets/flying_blade/visuals/guard_blade_orbit_visual.gd")
const FlyingBladeMotion = preload("res://mods-unpacked/Yoko-Fantasy/content/entities/pets/flying_blade/motion_math.gd")
const FORMATION_OVERLAP_SLOTS = 8
const COMBAT_ROLE = "satellite"

var owner_pet: Node = null
var combat_coordinator = null
var player_index: int = -1
var players_ref: Array = []
var weapon_stats: MeleeWeaponStats = null
var damage_tracking_key_hash: int = Keys.empty_hash

var orbit_radius: float
var orbit_speed: float
var orbit_y_scale: float = 0.46
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
var trail_core_width: float
var trail_color: Color
var trail_secondary_color: Color
var trail_core_color: Color
var guard_orbit_width: float
var guard_orbit_core_width: float
var guard_orbit_segment_width: float

var _state: int = SatelliteState.ORBIT
var _cooldown: float = 0.0
var _state_ticks: float = 0.0
var _target_scan_delay: float = 0.0
var _orbit_phase: float = rand_range(0.0, TAU)
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
var _trail_local_points: Array = []
var _body: Sprite = null
var _hitbox: Hitbox = null
var _hitbox_collision: CollisionShape2D = null
var _hitbox_shape: RectangleShape2D = null
var _motion_streak_visual = null
var _pierce_streak_visual = null
var _orbit_visual = null
var _vfx_pool = null
var _orbit_visual_position: Vector2 = Vector2.ZERO
var _orbit_visual_rotation: float = 0.0
var _orbit_visual_scale: Vector2 = Vector2.ONE
var _orbit_visual_modulate: Color = Color.white
var _orbit_visual_phase: float = 0.0
var _orbit_visual_radius: float = 0.0
var _orbit_visual_z_index: int = 2

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
    trail_core_width = tuning_data.trail_core_width
    trail_color = tuning_data.satellite_trail_color
    trail_secondary_color = tuning_data.satellite_trail_secondary_color
    trail_core_color = tuning_data.trail_core_color
    guard_orbit_width = tuning_data.satellite_guard_orbit_width
    guard_orbit_core_width = tuning_data.satellite_guard_orbit_core_width
    guard_orbit_segment_width = tuning_data.satellite_guard_orbit_segment_width

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
    _pierce_streak_visual.hide_visual()
    if _orbit_visual != null:
        _orbit_visual.hide_visual()
    visible = true

func shutdown() -> void:
    _unregister_from_coordinator()
    _free_orbit_visual()
    queue_free()

func _physics_process(delta: float) -> void:
    if !is_instance_valid(owner_pet) or owner_pet.dead:
        _disable_hitbox()
        visible = false
        return

    visible = true
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
    _position_hitbox(previous_position, global_position)
    if raw_progress >= 0.18 and !_attack_hitbox_armed:
        _attack_hitbox_armed = true
        _enable_hitbox()
    var redraw_visual: bool = _should_redraw_attack_visual()
    _update_attack_trail(redraw_visual)
    if redraw_visual:
        _update_attack_pierce(raw_progress)

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
    _update_attack_trail(_should_redraw_attack_visual())
    if global_position.distance_squared_to(_return_end) <= 100.0 * 100.0:
        _apply_orbit_body_visual(delta)
    else:
        _update_attack_body_visual(delta)

    if progress >= 1.0 or global_position.distance_squared_to(_return_end) <= 18.0 * 18.0:
        _state = SatelliteState.ORBIT
        _state_ticks = 0.0
        _velocity *= 0.12
        _trail_points.clear()

func _begin_attack(target: Node2D) -> void:
    _target = target
    if _attack_slot_active and is_instance_valid(combat_coordinator):
        combat_coordinator.claim_target(self, target, COMBAT_ROLE)
    _state = SatelliteState.ATTACK
    _state_ticks = 0.0
    _trail_points.clear()
    var target_position: Vector2 = target.global_position
    _attack_direction = global_position.direction_to(target_position)
    if _attack_direction.length_squared() <= 0.1:
        _attack_direction = Vector2.RIGHT
    var side: Vector2 = Vector2(-_attack_direction.y, _attack_direction.x) * (1.0 if randf() < 0.5 else -1.0)
    _attack_start = global_position
    _attack_end = FlyingBladeMotion.clamp_to_zone(target_position + _attack_direction * attack_distance)
    _attack_control = FlyingBladeMotion.clamp_to_zone(_attack_start - _attack_direction * 24.0 + side * max(8.0, hitbox_width * 0.42))
    _position_hitbox(_attack_start, _attack_start + _attack_direction * 4.0)
    _attack_hitbox_armed = false
    _disable_hitbox()

func _begin_return(apply_cooldown: bool = true) -> void:
    _release_attack_slot()
    _state = SatelliteState.RETURN
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
    _return_start = global_position
    _return_end = _get_orbit_position()
    var direction: Vector2 = _return_start.direction_to(_return_end)
    if direction.length_squared() <= 0.1:
        direction = _velocity.normalized()
    if direction.length_squared() <= 0.1:
        direction = Vector2.RIGHT
    var side: Vector2 = Vector2(-direction.y, direction.x)
    _return_control = FlyingBladeMotion.clamp_to_zone((_return_start + _return_end) * 0.5 + direction * orbit_radius * 0.18 + side * orbit_radius * 0.22)

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

    _pierce_streak_visual = PierceStreakVisual.new()
    _pierce_streak_visual.name = "PierceStreakVisual"
    _pierce_streak_visual.z_as_relative = false
    _pierce_streak_visual.z_index = 22
    _pierce_streak_visual.visible = false
    add_child(_pierce_streak_visual)

func _setup_orbit_visual() -> void:
    if is_instance_valid(_orbit_visual):
        return
    var parent: Node = get_parent()
    if parent == null:
        return
    _orbit_visual = GuardBladeOrbitVisual.new()
    _orbit_visual.name = "%sOrbitVisual" % name
    _orbit_visual.z_as_relative = false
    _orbit_visual.z_index = 1
    parent.add_child(_orbit_visual)

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
    var hitbox_args: Hitbox.HitboxArgs = Hitbox.HitboxArgs.new().set_from_weapon_stats(weapon_stats)
    _hitbox.projectiles_on_hit = []
    _hitbox.effect_scale = weapon_stats.effect_scale
    _hitbox.speed_percent_modifier = weapon_stats.speed_percent_modifier
    _hitbox.from = owner_pet
    _hitbox.damage_tracking_key_hash = damage_tracking_key_hash
    _hitbox.set_damage(weapon_stats.damage, hitbox_args)

func _enable_hitbox() -> void:
    if _hitbox_enabled:
        return
    _hitbox_enabled = true
    _hitbox.active = true
    _hitbox.ignored_objects.clear()
    _hitbox.enable()
    if is_instance_valid(combat_coordinator):
        combat_coordinator.report_hitbox_state(self, true)

func _disable_hitbox() -> void:
    if !_hitbox_enabled:
        return
    _hitbox_enabled = false
    _hitbox.active = false
    _hitbox.disable()
    _hitbox.ignored_objects.clear()
    if is_instance_valid(combat_coordinator):
        combat_coordinator.report_hitbox_state(self, false)

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
    if is_instance_valid(combat_coordinator):
        combat_coordinator.report_target_lost()
    var next_target: Node2D = _select_target()
    if _is_target_valid(next_target):
        if is_instance_valid(combat_coordinator):
            combat_coordinator.report_retarget_result(true)
        _begin_attack(next_target)
        return
    if is_instance_valid(combat_coordinator):
        combat_coordinator.report_retarget_result(false)
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
    return combat_coordinator.should_redraw_attack_visual(self)

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

func _calculate_orbit_visual() -> void:
    var distinct_count: int = _formation_count
    if distinct_count < 1:
        distinct_count = 1
    elif distinct_count > FORMATION_OVERLAP_SLOTS:
        distinct_count = FORMATION_OVERLAP_SLOTS
    var slot_count: int = distinct_count
    var lane: int = int(floor(float(_formation_index) / float(slot_count)))
    var slot_index: int = _formation_index % slot_count
    var slot_angle: float = float(slot_index) * TAU / float(slot_count)
    var phase: float = _get_shared_orbit_phase()
    var lane_phase: float = float(lane) * 0.73
    var angle: float = slot_angle + phase + lane_phase * 0.12
    var depth: float = sin(angle)
    var depth_pct: float = (depth + 1.0) * 0.5
    var radius: float = orbit_radius + float(lane) * max(3.0, guard_orbit_segment_width * 0.30)
    var local: Vector2 = Vector2(cos(angle) * radius, depth * radius * orbit_y_scale)
    var tangent: Vector2 = Vector2(-sin(angle) * radius, cos(angle) * radius * orbit_y_scale)
    if tangent.length_squared() <= 0.1:
        tangent = Vector2.RIGHT
    tangent = tangent.normalized()

    var pulse: float = 0.92 + sin(phase * 3.4 + slot_angle * 1.7 + lane_phase) * 0.08
    var guard_volume: float = clamp((guard_orbit_width + guard_orbit_core_width) / 3.3, 0.55, 1.45)
    var perspective: float = 0.78 + depth_pct * 0.34
    var crowd_scale: float = clamp(1.0 - max(0.0, float(_formation_count - 4)) * 0.025, 0.82, 1.0)
    var scale: Vector2 = Vector2(0.50 + guard_orbit_segment_width * 0.018, 0.64 + guard_orbit_segment_width * 0.025) * pulse * guard_volume * perspective * crowd_scale
    var color: Color = trail_color
    color.r = lerp(color.r, trail_core_color.r, depth_pct * 0.18)
    color.g = lerp(color.g, trail_core_color.g, depth_pct * 0.12)
    color.b = lerp(color.b, trail_core_color.b, depth_pct * 0.18)
    color.a = clamp(color.a * guard_volume * (1.08 + depth_pct * 0.76) + trail_core_color.a * (0.12 + depth_pct * 0.20), 0.18, 0.54)
    _orbit_visual_position = FlyingBladeMotion.clamp_to_zone(_get_player_position() + local + Vector2(0.0, -2.0))
    _orbit_visual_rotation = tangent.angle() - PI / 2.0
    _orbit_visual_scale = scale
    _orbit_visual_modulate = color
    _orbit_visual_phase = phase
    _orbit_visual_radius = radius
    _orbit_visual_z_index = 2

func _apply_orbit_body_visual(delta: float) -> void:
    var weight: float = 1.0 if delta <= 0.0 else min(1.0, delta * 10.0)
    rotation = lerp_angle(rotation, _orbit_visual_rotation, weight)
    _body.scale = _body.scale.linear_interpolate(_orbit_visual_scale, weight)
    _body.modulate = _body.modulate.linear_interpolate(_orbit_visual_modulate, weight)
    z_index = _orbit_visual_z_index
    if _formation_index == 0:
        _update_orbit_ring_visual()

func _update_attack_body_visual(delta: float) -> void:
    var weight: float = min(1.0, delta * 14.0)
    var attack_pulse: float = sin(min(_state_ticks / max(attack_ticks, 1.0), 1.0) * PI)
    _body.scale = _body.scale.linear_interpolate(Vector2(0.76 + attack_pulse * 0.08, 0.70), weight)
    _body.modulate = _body.modulate.linear_interpolate(Color(1.12, 1.02, 1.24, 0.96), weight)
    z_index = 6
    if _formation_index == 0:
        _hide_orbit_ring_visual()

func _update_attack_trail(redraw: bool = true) -> void:
    var sample_position: Vector2 = global_position
    if _trail_points.empty() or _trail_points[_trail_points.size() - 1].distance_squared_to(sample_position) >= 14.0 * 14.0:
        _trail_points.append(sample_position)
    while _trail_points.size() > 4:
        _trail_points.pop_front()
    if !redraw:
        return
    _trail_local_points.clear()
    for point in _trail_points:
        _trail_local_points.append(to_local(point))
    var attack_trail_color: Color = Color(trail_color.r * 0.78, trail_color.g * 0.66, trail_color.b * 0.94, min(0.34, trail_color.a * 1.42))
    var attack_secondary_color: Color = Color(trail_secondary_color.r * 0.76, trail_secondary_color.g * 0.84, trail_secondary_color.b, min(0.20, trail_secondary_color.a * 1.35))
    var attack_core_color: Color = Color(trail_core_color.r * 0.82, trail_core_color.g * 0.88, trail_core_color.b, min(0.28, trail_core_color.a * 1.08))
    var speed_ratio: float = clamp(_velocity.length() / max(260.0, orbit_radius * 8.0), 0.34, 1.0)
    _motion_streak_visual.configure(_trail_local_points, attack_trail_color, attack_secondary_color, attack_core_color, trail_width * 1.18, trail_aura_width * 1.22, trail_core_width, 0.82 + speed_ratio * 0.24)

func _update_attack_pierce(progress: float) -> void:
    var visibility: float = 0.48 + sin(progress * PI) * 0.34
    _pierce_streak_visual.configure(to_local(_attack_start), to_local(_attack_end), FlyingBladeMotion.to_local_direction(self, _attack_direction), progress, visibility, max(9.0, hitbox_width * 0.58), max(15.0, hitbox_width * 1.04), trail_core_width, trail_color, trail_secondary_color, trail_core_color, _state_ticks, _orbit_phase)

func _fade_attack_visuals(delta: float) -> void:
    if _state == SatelliteState.ORBIT:
        _motion_streak_visual.fade(delta)
    if _state != SatelliteState.ATTACK:
        _pierce_streak_visual.fade(delta)

func _face_direction(direction: Vector2) -> void:
    if direction.length_squared() <= 0.1:
        return
    rotation = lerp_angle(rotation, direction.angle() - PI / 2.0, 0.48)

func _update_orbit_ring_visual() -> void:
    if !is_instance_valid(_orbit_visual):
        _setup_orbit_visual()
    if !is_instance_valid(_orbit_visual):
        return
    var alpha_scale: float = clamp(1.0 / sqrt(float(max(_formation_count, 1))), 0.38, 1.0)
    var ring_color: Color = trail_color
    var ring_secondary_color: Color = trail_secondary_color
    var ring_core_color: Color = trail_core_color
    ring_color.a *= alpha_scale * 0.62
    ring_secondary_color.a *= alpha_scale * 0.58
    ring_core_color.a *= alpha_scale * 0.42
    _orbit_visual.global_position = _get_player_position() + Vector2(0.0, -2.0)
    _orbit_visual.configure(_orbit_visual_radius, orbit_y_scale, _orbit_visual_phase, ring_color, ring_secondary_color, ring_core_color, max(2.0, guard_orbit_segment_width * 0.55))

func _hide_orbit_ring_visual() -> void:
    if is_instance_valid(_orbit_visual):
        _orbit_visual.hide_visual()

func _free_orbit_visual() -> void:
    if is_instance_valid(_orbit_visual):
        _orbit_visual.queue_free()
    _orbit_visual = null

func set_formation(index: int, count: int) -> void:
    var old_index: int = _formation_index
    _formation_count = max(1, count)
    _formation_index = int(clamp(index, 0, _formation_count - 1))
    if old_index == 0 and _formation_index != 0:
        _free_orbit_visual()

func _get_shared_orbit_phase() -> float:
    if is_instance_valid(combat_coordinator):
        return combat_coordinator.get_orbit_phase(orbit_speed)
    return float(OS.get_ticks_msec()) * 0.001 * orbit_speed * 0.72

func _on_Hitbox_hit_something(thing_hit: Node, _damage_dealt: int) -> void:
    RunData.manage_life_steal(weapon_stats, player_index)
    if !_hitbox.ignored_objects.has(thing_hit):
        _hitbox.ignored_objects.push_back(thing_hit)
    if is_instance_valid(_vfx_pool) and thing_hit is Node2D:
        var direction: Vector2 = _attack_direction
        if direction.length_squared() <= 0.1:
            direction = Vector2.RIGHT
        _vfx_pool.emit_hit_flash(thing_hit.global_position, direction.normalized(), trail_core_color, max(10.0, hitbox_width * 0.85), 0.08, 24)
