extends Pet

enum BladeState {
	GUARD,
	AIM,
	WINDUP,
	SLASH,
	CHAIN,
	RETURN
}

const Z_MOTION_TRAIL = 16
const Z_SLASH_BODY = 22
const Z_SLASH_CORE = 23
const Z_HIT_FLASH = 24
const SlashRibbonVisual = preload("res://mods-unpacked/Yoko-Fantasy/content/entities/pets/flying_blade/visuals/slash_ribbon_visual.gd")
const MotionStreakVisual = preload("res://mods-unpacked/Yoko-Fantasy/content/entities/pets/flying_blade/visuals/motion_streak_visual.gd")
const GuardBladeSatellite = preload("res://mods-unpacked/Yoko-Fantasy/content/entities/pets/flying_blade/guard_blade_satellite.gd")
const FlyingBladeCombatCoordinator = preload("res://mods-unpacked/Yoko-Fantasy/content/entities/pets/flying_blade/combat_coordinator.gd")
const FlyingBladeMotion = preload("res://mods-unpacked/Yoko-Fantasy/content/entities/pets/flying_blade/motion_math.gd")

export(String) var damage_tracking_id = ""
export(Resource) var tuning = null

onready var _body: Sprite = $Animation/Offset/Body
onready var _hitbox: Hitbox = $Animation/Hitbox
onready var _hitbox_collision: CollisionShape2D = $Animation/Hitbox/Collision

var _hitbox_shape: RectangleShape2D = null
var _slash_ribbon_visual = null
var _motion_streak_visual = null
var _guard_satellite = null
var _combat_coordinator = null
var _vfx_pool = null
var _trail_wisps: Array = []
var _damage_tracking_id_hash: int = Keys.empty_hash
var _base_weapon_stats: MeleeWeaponStats = MeleeWeaponStats.new()
var _current_weapon_stats: MeleeWeaponStats = MeleeWeaponStats.new()

var _state: int = BladeState.GUARD
var _cooldown: float = 0.0
var _state_ticks: float = 0.0
var _target_refresh: float = 0.0
var _orbit_angle: float = rand_range(0.0, TAU)
var _guard_slot_offset: float = 0.0
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
var _trail_points: Array = []
var _attack_fragment_cursor: int = 0
var _attack_fragment_tick: float = 0.0
var _last_afterimage_position: Vector2 = Vector2.ZERO
var _guard_phase: float = rand_range(0.0, TAU)
var _attack_visuals_active: bool = false
var _attack_queued: bool = false
var _attack_slot_active: bool = false
var _attack_hitbox_enabled: bool = true
var _visual_level: int = FlyingBladeCombatCoordinator.VISUAL_FULL

func _ready() -> void:
	_guard_slot_offset = float(get_index() % 8) * TAU / 8.0
	_last_position = global_position
	_setup_combat_coordinator()
	_setup_blade_visuals()
	_setup_guard_satellite()

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
	_setup_guard_satellite()

func respawn() -> void:
	.respawn()
	_setup_combat_coordinator()
	_reset_runtime_state()
	_disable_attack_hitbox()
	_setup_guard_satellite()

func die(args: = Utils.default_die_args) -> void:
	_disable_attack_hitbox()
	_hide_attack_visuals()
	_free_guard_satellite()
	_unregister_from_combat_coordinator()
	.die(args)

func _exit_tree() -> void:
	_free_guard_satellite()
	_unregister_from_combat_coordinator()

func update_data(effect: PetEffect) -> void:
	.update_data(effect)
	_base_weapon_stats = effect.weapon_stats
	reload_data()
	_cooldown = _current_weapon_stats.cooldown * rand_range(0.25, 0.75)

func should_data_be_reload() -> bool:
	return true

func reload_data() -> void:
	var args: WeaponServiceInitStatsArgs = WeaponServiceInitStatsArgs.new()
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

func get_combat_coordinator():
	if !is_instance_valid(_combat_coordinator):
		_setup_combat_coordinator()
	return _combat_coordinator

func _physics_process(delta: float) -> void:
	if dead or _end_of_wave:
		return

	if !is_instance_valid(_combat_coordinator):
		_setup_combat_coordinator()
	var ticks: float = Utils.physics_one(delta)
	_cooldown -= ticks
	_target_refresh -= ticks
	_state_ticks += ticks
	_guard_phase += delta * tuning.guard_orbit_speed * 0.72
	_last_position = global_position

	match _state:
		BladeState.GUARD:
			_process_guard(delta)
		BladeState.AIM:
			_process_aim(delta)
		BladeState.WINDUP:
			_process_windup(delta)
		BladeState.SLASH:
			_process_slash(delta)
		BladeState.CHAIN:
			_process_chain(delta)
		BladeState.RETURN:
			_process_return(delta)

	_update_body_energy(delta)
	_attack_fragment_tick = max(0.0, _attack_fragment_tick - ticks)

func _integrate_forces(state: Physics2DDirectBodyState) -> void:
	if sleeping:
		return
	state.transform.origin = global_position
	state.linear_velocity = Vector2.ZERO

func update_animation(_movement: Vector2) -> void:
	pass

func _process_guard(delta: float) -> void:
	var guard_position: Vector2 = _get_guard_position(delta)
	_steer_toward(guard_position, tuning.guard_speed, 16.0, delta)
	_face_guard_orbit(guard_position, 0.18)
	if _attack_visuals_active:
		_hide_attack_visuals()

	if _cooldown > 0:
		return
	if _attack_queued or _attack_slot_active or _target_refresh > 0.0:
		return
	_enqueue_coordinated_attack()

func _process_aim(delta: float) -> void:
	if !_is_target_valid(_attack_target):
		_retarget_lost_attack()
		return

	_attack_center = _attack_target.global_position
	var raw_progress: float = min(_state_ticks / max(tuning.aim_ticks, 1.0), 1.0)
	var progress: float = FlyingBladeMotion.ease_in_out_cubic(raw_progress)
	var lead: Vector2 = _attack_direction * sin(raw_progress * PI) * -10.0
	var aim_position: Vector2 = FlyingBladeMotion.bezier2(_aim_start, _aim_control, _aim_end + lead, progress)
	_velocity = (aim_position - global_position) / max(delta, 0.001)
	global_position = FlyingBladeMotion.clamp_to_zone(aim_position)
	_attack_direction = global_position.direction_to(_attack_center)
	if _attack_direction == Vector2.ZERO:
		_attack_direction = (_aim_end - _aim_start).normalized()
	_face_direction(_attack_direction, 0.64)
	if _uses_motion_visual():
		_update_motion_trail(_should_redraw_attack_visual())
	else:
		_motion_streak_visual.hide_visual()

	if _state_ticks >= tuning.aim_ticks or global_position.distance_squared_to(_aim_end) <= 22.0 * 22.0:
		_begin_windup()

func _process_windup(delta: float) -> void:
	if !_is_target_valid(_attack_target):
		_retarget_lost_attack()
		return

	_attack_center = _attack_target.global_position
	_attack_direction = (_attack_center - global_position).normalized()
	if _attack_direction == Vector2.ZERO:
		_attack_direction = Vector2.RIGHT

	var side: Vector2 = Vector2(-_attack_direction.y, _attack_direction.x) * _curve_side
	var pullback: Vector2 = _attack_center - _attack_direction * tuning.approach_distance + side * tuning.curve_side_distance * 0.22
	var raw_progress: float = min(_state_ticks / max(tuning.windup_ticks, 1.0), 1.0)
	var pull_progress: float = FlyingBladeMotion.ease_in_out_cubic(raw_progress)
	var pulse: float = sin(raw_progress * PI)
	_steer_toward(FlyingBladeMotion.clamp_to_zone(pullback - _attack_direction * (12.0 + pull_progress * 24.0) + side * pulse * 8.0), tuning.return_speed, 37.4, delta)
	_refresh_attack_path(global_position)
	_face_direction(_attack_direction, 0.68)
	_animation.scale = Vector2(0.92 - pulse * 0.05, 1.10 + pull_progress * 0.12)
	_body.modulate = Color(1.35 + pull_progress * 0.4, 1.2 + pull_progress * 0.3, 1.6 + pull_progress * 0.5, 1.0)
	var redraw_visual: bool = _should_redraw_attack_visual()
	if raw_progress > 0.32 and _uses_motion_visual():
		_update_motion_trail(redraw_visual)
	if redraw_visual and _uses_slash_visual():
		_update_slash_visuals()

	if _state_ticks >= tuning.windup_ticks:
		_begin_slash()

func _process_slash(delta: float) -> void:
	var raw_progress: float = min(_state_ticks / max(tuning.slash_ticks, 1.0), 1.0)
	var progress: float = FlyingBladeMotion.ease_out_cubic(raw_progress)
	var next_position: Vector2 = FlyingBladeMotion.bezier2(_attack_start, _attack_control, _attack_end, progress)
	_velocity = (next_position - global_position) / max(delta, 0.001)
	global_position = FlyingBladeMotion.clamp_to_zone(next_position)
	_face_direction(FlyingBladeMotion.bezier2_tangent(_attack_start, _attack_control, _attack_end, progress), 0.86)
	_position_sweep_hitbox(_last_position, global_position)
	if _uses_motion_visual():
		_update_motion_trail(_should_redraw_attack_visual())
	else:
		_motion_streak_visual.hide_visual()
	_slash_ribbon_visual.hide_visual()
	if raw_progress > 0.10:
		_emit_attack_fragment(1.0)
	if raw_progress > 0.08:
		_emit_blade_afterimage()
	var stretch_factor: float = 1.0 + (1.0 - raw_progress) * 0.22
	_animation.scale = Vector2(0.86 / max(0.1, sqrt(stretch_factor)), 1.16 * stretch_factor)
	_body.modulate = Color(1.45, 1.30, 1.90, 1.0)

	if _state_ticks >= tuning.slash_ticks:
		_begin_chain()

func _process_chain(delta: float) -> void:
	_disable_attack_hitbox()
	_slash_ribbon_visual.hide_visual()
	_emit_attack_fragment(1.0)
	_emit_blade_afterimage()

	if _state_ticks < tuning.chain_ticks:
		var settle: float = sin(min(_state_ticks / max(tuning.chain_ticks, 1.0), 1.0) * PI)
		var drift_target: Vector2 = _attack_end + _attack_direction * 28.0
		_steer_toward(FlyingBladeMotion.clamp_to_zone(drift_target), tuning.return_speed, 11.0, delta)
		_face_direction(_velocity, 0.46)
		_animation.scale = _animation.scale.linear_interpolate(Vector2(1.0 + settle * 0.05, 1.0), min(1.0, delta * 10.0))
		return

	if _chain_count < tuning.max_chain_hits:
		var next_target: Node2D = _find_attack_target(_targets_hit_this_combo, global_position, tuning.chain_search_radius)
		if _is_target_valid(next_target):
			_allow_repeat_target = false
			_begin_aim(next_target, true)
			return
		if _is_target_valid(_attack_target):
			_allow_repeat_target = true
			_begin_aim(_attack_target, true)
			return

	_begin_return()

func _process_return(delta: float) -> void:
	_return_end = _get_guard_position(delta)
	var progress: float = FlyingBladeMotion.ease_out_cubic(min(_state_ticks / max(12.5, tuning.chain_ticks + 10.0), 1.0))
	var next_position: Vector2 = FlyingBladeMotion.bezier2(_return_start, _return_control, _return_end, progress)
	_velocity = (next_position - global_position) / max(delta, 0.001)
	global_position = FlyingBladeMotion.clamp_to_zone(next_position)
	_face_direction(_velocity, 0.48)
	if _uses_motion_visual():
		_update_motion_trail(_should_redraw_attack_visual())
	else:
		_motion_streak_visual.hide_visual()
	_slash_ribbon_visual.hide_visual()

	if progress >= 1.0 or global_position.distance_squared_to(_return_end) <= 24.0 * 24.0:
		_state = BladeState.GUARD
		_state_ticks = 0.0
		_velocity *= 0.12
		_animation.scale = Vector2(1.08, 0.94)
		_body.modulate = Color(1.35, 1.25, 1.65, 1.0)

func _begin_aim(target: Node2D, chaining: bool) -> void:
	_attack_target = target
	_attack_center = target.global_position
	var from_target: Vector2 = global_position.direction_to(_attack_center)
	if from_target == Vector2.ZERO:
		from_target = Vector2.RIGHT
	_attack_direction = from_target
	if chaining:
		_curve_side = -_curve_side
	elif !_allow_repeat_target:
		_curve_side = _choose_curve_side()
	var side: Vector2 = Vector2(-_attack_direction.y, _attack_direction.x) * _curve_side
	_aim_start = global_position
	_aim_end = FlyingBladeMotion.clamp_to_zone(_attack_center - _attack_direction * tuning.approach_distance + side * tuning.curve_side_distance * 0.30)
	if _aim_start.distance_squared_to(_aim_end) > tuning.aim_snap_distance * tuning.aim_snap_distance:
		_aim_end = _aim_start.linear_interpolate(_aim_end, tuning.aim_snap_distance / _aim_start.distance_to(_aim_end))
	_aim_control = FlyingBladeMotion.clamp_to_zone((_aim_start + _aim_end) * 0.5 + side * tuning.curve_side_distance * 0.60)
	if !chaining:
		_chain_count = 0
		_targets_hit_this_combo.clear()
		_trail_points.clear()
	if _attack_slot_active and is_instance_valid(_combat_coordinator):
		_combat_coordinator.claim_target(self, target, FlyingBladeCombatCoordinator.ROLE_MAIN)
	_last_afterimage_position = Vector2.ZERO
	_enable_motion_trail(_uses_motion_visual())
	_hide_slash_visuals()
	_disable_attack_hitbox()
	_state = BladeState.AIM
	_state_ticks = tuning.aim_ticks * 0.45 if chaining else 0.0

func _begin_windup() -> void:
	_state = BladeState.WINDUP
	_state_ticks = 0.0
	_disable_attack_hitbox()

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
	if !_allow_repeat_target:
		for target_hit in _targets_hit_this_combo:
			if is_instance_valid(target_hit):
				_hitbox.ignored_objects.push_back(target_hit)
	_allow_repeat_target = false
	_enable_attack_hitbox()
	_emit_attack_fragment(0.0)

	if is_instance_valid(_vfx_pool) and _uses_slash_visual():
		_vfx_pool.emit_slash_rift(_attack_start, _attack_control, _attack_end, _attack_direction, _curve_side, max(14.0, tuning.slash_width * 1.30), tuning.slash_color, 0.20)
	_slash_ribbon_visual.hide_visual()

func _begin_chain() -> void:
	_state = BladeState.CHAIN
	_state_ticks = 0.0
	_disable_attack_hitbox()

func _begin_return(apply_cooldown: bool = true) -> void:
	_release_attack_slot()
	_state = BladeState.RETURN
	_state_ticks = 0.0
	_return_start = global_position
	var return_direction: Vector2 = _velocity.normalized()
	if return_direction == Vector2.ZERO:
		return_direction = _attack_direction
	var return_side: Vector2 = Vector2(-return_direction.y, return_direction.x) * _curve_side
	_return_end = _get_guard_position(0.0)
	_return_control = FlyingBladeMotion.clamp_to_zone((global_position + _return_end) * 0.5 + return_direction * tuning.return_curve_distance * 0.45 + return_side * tuning.return_curve_distance)
	if apply_cooldown:
		_cooldown = _get_next_cooldown(_current_weapon_stats.cooldown)
	else:
		_cooldown = 0.0
		_target_refresh = _get_target_retry_ticks()
	_attack_target = null
	_disable_attack_hitbox()
	_animation.scale = Vector2(1, 1)

func _reset_runtime_state() -> void:
	_cancel_coordinated_attack()
	_state = BladeState.GUARD
	_state_ticks = 0.0
	_target_refresh = _get_initial_target_refresh()
	_attack_target = null
	_attack_direction = Vector2.RIGHT
	_curve_side = 1.0
	_chain_count = 0
	_allow_repeat_target = false
	_velocity = Vector2.ZERO
	_targets_hit_this_combo.clear()
	_animation.scale = Vector2(1, 1)
	_hide_attack_visuals()
	_body.modulate = Color.white
	if is_instance_valid(_guard_satellite):
		_guard_satellite.reset()

func _enqueue_coordinated_attack() -> void:
	if !is_instance_valid(_combat_coordinator):
		_setup_combat_coordinator()
	if !is_instance_valid(_combat_coordinator):
		_target_refresh = _get_target_retry_ticks()
		return
	_attack_queued = _combat_coordinator.enqueue_attack(self, FlyingBladeCombatCoordinator.ROLE_MAIN)
	if !_attack_queued:
		_target_refresh = _get_target_retry_ticks()

func get_coordinated_attack_target() -> Node2D:
	_attack_queued = false
	_targets_hit_this_combo.clear()
	return _find_attack_target(_targets_hit_this_combo, _get_player_position(), _get_attack_range())

func begin_coordinated_attack(target: Node2D) -> void:
	_attack_queued = false
	if !_is_target_valid(target):
		coordinated_attack_failed()
		return
	_attack_slot_active = true
	_attack_target = target
	_target_refresh = tuning.target_refresh_ticks
	_begin_aim(target, false)

func coordinated_attack_failed() -> void:
	_attack_queued = false
	_attack_slot_active = false
	_attack_target = null
	_target_refresh = _get_target_retry_ticks()
	if is_instance_valid(_combat_coordinator):
		_combat_coordinator.release_attack(self, FlyingBladeCombatCoordinator.ROLE_MAIN)

func _retarget_lost_attack() -> void:
	var next_target: Node2D = _find_attack_target(_targets_hit_this_combo, _get_player_position(), _get_attack_range())
	if _is_target_valid(next_target):
		_begin_aim(next_target, _chain_count > 0)
		return
	_begin_return(_chain_count > 0)

func _release_attack_slot() -> void:
	if !_attack_slot_active:
		return
	_attack_slot_active = false
	if is_instance_valid(_combat_coordinator):
		_combat_coordinator.release_attack(self, FlyingBladeCombatCoordinator.ROLE_MAIN)

func _cancel_coordinated_attack() -> void:
	_attack_queued = false
	_attack_slot_active = false
	if is_instance_valid(_combat_coordinator):
		_combat_coordinator.cancel_attack(self, FlyingBladeCombatCoordinator.ROLE_MAIN)

func _find_attack_target(excluded: Array, origin: Vector2, radius: float) -> Node2D:
	if !is_instance_valid(_combat_coordinator):
		_setup_combat_coordinator()
	if !is_instance_valid(_combat_coordinator):
		return null

	var player_position: Vector2 = _get_player_position()
	var min_range: float = _current_weapon_stats.min_range
	var target: Node2D = _combat_coordinator.select_main_target(
		self,
		excluded,
		origin,
		radius,
		min_range,
		player_position,
		_get_preferred_target_angle(),
		_chain_count,
		_attack_direction,
		tuning.target_origin_weight,
		tuning.target_player_weight,
		tuning.target_angle_weight,
		tuning.target_follow_through_weight
	)
	return target

func _is_target_valid(target: Node) -> bool:
	if !is_instance_valid(target):
		return false
	return !target.dead

func _get_attack_range() -> float:
	return float(_current_weapon_stats.max_range)

func _get_target_sensor_radius() -> float:
	return max(_get_attack_range(), tuning.chain_search_radius) + tuning.guard_radius + tuning.guard_wave_height + tuning.exit_distance + 120.0

func _setup_combat_coordinator() -> void:
	if player_index < 0 or player_index >= players_ref.size():
		return
	if is_instance_valid(_combat_coordinator):
		_combat_coordinator.configure_attack_limits(tuning.max_active_main_attacks, tuning.max_active_satellite_attacks, tuning.max_attack_dispatches_per_tick)
		_combat_coordinator.configure_visual_budgets(tuning.full_visual_count, tuning.reduced_visual_count, tuning.minimal_visual_count, tuning.crowded_reduced_visual_slots, tuning.crowded_minimal_visual_slots, tuning.satellite_idle_visible_count)
		_combat_coordinator.register_main(self, _get_target_sensor_radius())
		_vfx_pool = _combat_coordinator.get_vfx_pool()
		return
	var parent: Node = get_parent()
	if parent == null:
		return
	var coordinator_name: String = "FlyingBladeCombatCoordinatorP%s" % player_index
	var existing = parent.get_node_or_null(coordinator_name)
	if is_instance_valid(existing):
		_combat_coordinator = existing
	else:
		_combat_coordinator = FlyingBladeCombatCoordinator.new()
		_combat_coordinator.name = coordinator_name
		parent.add_child(_combat_coordinator)
		_combat_coordinator.setup(player_index, players_ref, _get_target_sensor_radius())
	_combat_coordinator.configure_attack_limits(tuning.max_active_main_attacks, tuning.max_active_satellite_attacks, tuning.max_attack_dispatches_per_tick)
	_combat_coordinator.configure_visual_budgets(tuning.full_visual_count, tuning.reduced_visual_count, tuning.minimal_visual_count, tuning.crowded_reduced_visual_slots, tuning.crowded_minimal_visual_slots, tuning.satellite_idle_visible_count)
	_combat_coordinator.register_main(self, _get_target_sensor_radius())
	_vfx_pool = _combat_coordinator.get_vfx_pool()

func _refresh_combat_coordinator_radius() -> void:
	if is_instance_valid(_combat_coordinator):
		_combat_coordinator.request_sensor_radius(self, _get_target_sensor_radius())

func _unregister_from_combat_coordinator() -> void:
	if is_instance_valid(_combat_coordinator):
		_combat_coordinator.unregister_main(self)
	_combat_coordinator = null
	_vfx_pool = null

func _apply_weapon_stats_to_hitbox() -> void:
	_current_weapon_stats.burning_data.from = self
	_refresh_combat_coordinator_radius()

	var hitbox_args: Hitbox.HitboxArgs = Hitbox.HitboxArgs.new().set_from_weapon_stats(_current_weapon_stats)
	_hitbox.projectiles_on_hit = []
	_hitbox.effect_scale = _current_weapon_stats.effect_scale
	_hitbox.set_damage(_current_weapon_stats.damage, hitbox_args)
	_hitbox.speed_percent_modifier = _current_weapon_stats.speed_percent_modifier
	_hitbox.from = self
	_hitbox.damage_tracking_key_hash = _damage_tracking_id_hash

func _enable_attack_hitbox() -> void:
	if _attack_hitbox_enabled:
		return
	_attack_hitbox_enabled = true
	_hitbox.active = true
	_hitbox.enable()

func _disable_attack_hitbox() -> void:
	if !_attack_hitbox_enabled:
		return
	_attack_hitbox_enabled = false
	_hitbox.disable()
	_hitbox.active = false
	_hitbox.ignored_objects.clear()

func _refresh_attack_path(start_position: Vector2) -> void:
	var side: Vector2 = Vector2(-_attack_direction.y, _attack_direction.x) * _curve_side
	_attack_start = start_position
	_attack_end = FlyingBladeMotion.clamp_to_zone(_attack_center + _attack_direction * tuning.exit_distance)
	_attack_control = FlyingBladeMotion.clamp_to_zone((_attack_start + _attack_end) * 0.5 + side * tuning.curve_side_distance)

func _position_sweep_hitbox(from_pos: Vector2, to_pos: Vector2) -> void:
	var movement: Vector2 = to_pos - from_pos
	if movement.length_squared() <= 1.0:
		movement = _attack_direction * 8.0

	var length: float = movement.length() + tuning.exit_distance * 0.55
	_hitbox.global_position = (from_pos + to_pos) * 0.5
	_hitbox.global_rotation = movement.angle()
	_hitbox_collision.position = Vector2.ZERO
	_hitbox_shape.extents = Vector2(max(24.0, length * 0.5), tuning.sweep_width)
	_hitbox.set_knockback(movement.normalized(), _current_weapon_stats.knockback, _current_weapon_stats.knockback_piercing)

func _get_guard_position(delta: float) -> Vector2:
	_orbit_angle += tuning.guard_orbit_speed * delta
	var angle: float = _orbit_angle + _guard_slot_offset
	var player_position: Vector2 = _get_player_position()
	var depth: float = sin(angle)
	var wave: float = sin(angle * 2.0 + _guard_phase * tuning.guard_wave_speed)
	var radius: float = tuning.guard_radius + wave * tuning.guard_wave_height * 0.26
	var offset: Vector2 = Vector2(cos(angle) * radius, depth * radius * 0.65)
	return FlyingBladeMotion.clamp_to_zone(player_position + offset)

func _get_player_position() -> Vector2:
	if player_index >= 0 and player_index < players_ref.size() and is_instance_valid(players_ref[player_index]):
		return players_ref[player_index].global_position
	return global_position

func _steer_toward(target_position: Vector2, max_speed: float, responsiveness: float, delta: float) -> void:
	var to_target: Vector2 = target_position - global_position
	var desired: Vector2 = Vector2.ZERO
	if to_target.length_squared() > 1.0:
		var speed: float = min(max_speed, max(160.0, to_target.length() * responsiveness))
		desired = to_target.normalized() * speed
	_velocity = _velocity.linear_interpolate(desired, clamp(responsiveness * delta, 0.0, 1.0))
	global_position = FlyingBladeMotion.clamp_to_zone(global_position + _velocity * delta)

func _face_direction(direction: Vector2, weight: float) -> void:
	if direction.length_squared() <= 1.0:
		return
	var target_rotation: float = direction.angle() + PI / 2.0
	_animation.rotation = lerp_angle(_animation.rotation, target_rotation, weight)

func _face_guard_orbit(guard_position: Vector2, weight: float) -> void:
	var player_position: Vector2 = _get_player_position()
	var side: float = clamp((guard_position.x - player_position.x) / max(tuning.guard_radius, 1.0), -1.0, 1.0)
	var target_rotation: float = PI + side * tuning.guard_tilt_strength
	_animation.rotation = lerp_angle(_animation.rotation, target_rotation, weight)

func _choose_curve_side() -> float:
	if randf() < 0.5:
		return -1.0
	return 1.0

func _get_next_cooldown(base_ticks: float) -> float:
	if !is_instance_valid(_combat_coordinator):
		return max(base_ticks, 1.0)
	return _combat_coordinator.get_next_cooldown(base_ticks, FlyingBladeCombatCoordinator.ROLE_MAIN)

func _get_target_retry_ticks() -> float:
	if !is_instance_valid(_combat_coordinator):
		return 1.0
	return _combat_coordinator.get_retry_ticks(FlyingBladeCombatCoordinator.ROLE_MAIN)

func _get_initial_target_refresh() -> float:
	if !is_instance_valid(_combat_coordinator):
		return rand_range(0.0, max(1.0, tuning.target_refresh_ticks))
	return _combat_coordinator.get_actor_scan_offset(self, tuning.target_refresh_ticks)

func _uses_motion_visual() -> bool:
	return _visual_level <= FlyingBladeCombatCoordinator.VISUAL_MINIMAL

func _uses_slash_visual() -> bool:
	return _visual_level <= FlyingBladeCombatCoordinator.VISUAL_MINIMAL

func set_visual_level(level: int) -> void:
	if level == _visual_level:
		return
	_visual_level = level
	if _visual_level > FlyingBladeCombatCoordinator.VISUAL_MINIMAL:
		if is_instance_valid(_motion_streak_visual):
			_motion_streak_visual.hide_visual()
		for wisp in _trail_wisps:
			wisp.visible = false
	if _visual_level >= FlyingBladeCombatCoordinator.VISUAL_ESSENTIAL:
		if is_instance_valid(_slash_ribbon_visual):
			_slash_ribbon_visual.hide_visual()

func _should_redraw_attack_visual() -> bool:
	if !is_instance_valid(_combat_coordinator):
		return true
	return _combat_coordinator.should_redraw_attack_visual(self, _visual_level)

func _setup_blade_visuals() -> void:
	_motion_streak_visual = MotionStreakVisual.new()
	_motion_streak_visual.name = "MotionStreakVisual"
	_motion_streak_visual.position = Vector2.ZERO
	_motion_streak_visual.z_as_relative = false
	_motion_streak_visual.z_index = Z_MOTION_TRAIL
	_motion_streak_visual.visible = false
	add_child(_motion_streak_visual)

	_slash_ribbon_visual = SlashRibbonVisual.new()
	_slash_ribbon_visual.name = "SlashRibbonVisual"
	_slash_ribbon_visual.position = Vector2.ZERO
	_slash_ribbon_visual.z_as_relative = false
	_slash_ribbon_visual.z_index = Z_SLASH_BODY
	_slash_ribbon_visual.visible = false
	add_child(_slash_ribbon_visual)

	for i in range(max(tuning.trail_max_points, 1)):
		var wisp_color: Color = tuning.trail_color if i % 2 == 0 else tuning.trail_secondary_color
		var wisp: Sprite = _make_blade_sprite("MotionWisp%s" % i, wisp_color, Z_MOTION_TRAIL, true)
		_trail_wisps.append(wisp)

func _setup_guard_satellite() -> void:
	if is_instance_valid(_guard_satellite):
		return
	if player_index < 0 or player_index >= players_ref.size():
		return
	if _damage_tracking_id_hash == Keys.empty_hash:
		return
	var parent: Node = get_parent()
	if parent == null:
		return
	_setup_combat_coordinator()

	_guard_satellite = GuardBladeSatellite.new()
	_guard_satellite.name = "%sGuardSatellite" % name
	parent.add_child(_guard_satellite)
	_guard_satellite.setup(_get_guard_satellite_config())

func _sync_guard_satellite_stats() -> void:
	if is_instance_valid(_guard_satellite):
		_guard_satellite.sync_weapon_stats(_current_weapon_stats)

func _free_guard_satellite() -> void:
	if is_instance_valid(_guard_satellite):
		_guard_satellite.shutdown()
	_guard_satellite = null

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
		"flip_v": _body.flip_v
	}

func _hide_attack_visuals() -> void:
	_enable_motion_trail(false)
	_hide_slash_visuals()
	_last_afterimage_position = Vector2.ZERO
	_attack_visuals_active = false

func _enable_motion_trail(p_visible: bool) -> void:
	if p_visible:
		_attack_visuals_active = true
		return
	_trail_points.clear()
	_motion_streak_visual.hide_visual()
	for wisp in _trail_wisps:
		wisp.visible = false

func _hide_slash_visuals() -> void:
	_slash_ribbon_visual.hide_visual()

func _update_motion_trail(redraw: bool = true) -> void:
	if !_uses_motion_visual():
		_motion_streak_visual.hide_visual()
		return
	var sample_position: Vector2 = _body.global_position
	if _trail_points.empty() or _trail_points[_trail_points.size() - 1].distance_squared_to(sample_position) >= tuning.trail_sample_min_distance * tuning.trail_sample_min_distance:
		_trail_points.append(sample_position)
	while _trail_points.size() > tuning.trail_max_points:
		_trail_points.pop_front()
	if !redraw:
		return

	var speed_ratio: float = clamp(_velocity.length() / max(tuning.return_speed, 1.0), 0.25, 1.0)
	var intensity: float = clamp(0.45 + speed_ratio * 0.75, 0.0, 1.0)
	var core_color: Color = tuning.trail_core_color
	if _state == BladeState.WINDUP or _state == BladeState.SLASH:
		core_color.a = 0.0
	var visual_level: int = _visual_level
	_motion_streak_visual.configure(_trail_points, tuning.trail_color, tuning.trail_secondary_color, core_color, tuning.trail_width, tuning.trail_aura_width, intensity, visual_level)

	var rotation: float = _animation.global_rotation
	var trail_volume: float = clamp(tuning.trail_width / 6.4, 0.55, 1.50)
	var aura_volume: float = clamp(tuning.trail_aura_width / 17.0, 0.55, 1.50)
	var core_bias: float = clamp(tuning.trail_core_width / 1.7, 0.55, 1.60)
	for i in range(_trail_wisps.size()):
		var wisp: Sprite = _trail_wisps[i]
		if visual_level != FlyingBladeCombatCoordinator.VISUAL_FULL:
			wisp.visible = false
			continue
		if i >= _trail_points.size():
			wisp.visible = false
			continue
		var pct: float = float(i) / float(max(_trail_points.size() - 1, 1))
		var alpha: float = tuning.trail_color.a * pct * pct * (0.48 + core_bias * 0.18)
		if alpha <= 0.02:
			wisp.visible = false
			continue
		wisp.global_position = _trail_points[i]
		wisp.global_rotation = rotation + sin(_guard_phase + float(i) * 0.7) * 0.06
		var length_scale: float = (0.72 + pct * 0.38) * trail_volume
		var thickness_scale: float = (0.88 + pct * 0.24) * aura_volume
		wisp.scale = Vector2(thickness_scale, length_scale)
		wisp.modulate = Color(tuning.trail_color.r, tuning.trail_color.g, tuning.trail_color.b, alpha)
		wisp.visible = true

func _update_slash_visuals() -> void:
	var progress: float = 0.35
	var visibility: float = 1.0
	if _state == BladeState.WINDUP:
		var windup_progress: float = min(_state_ticks / max(tuning.windup_ticks, 1.0), 1.0)
		progress = 0.10 + windup_progress * 0.20
		visibility = 0.18 + sin(windup_progress * PI) * 0.18
	elif _state == BladeState.SLASH:
		var slash_progress: float = min(_state_ticks / max(tuning.slash_ticks, 1.0), 1.0)
		progress = FlyingBladeMotion.ease_out_cubic(slash_progress)
		visibility = 0.34 + sin(slash_progress * PI) * 0.52

	_slash_ribbon_visual.configure(to_local(_attack_start), to_local(_attack_control), to_local(_attack_end), FlyingBladeMotion.to_local_direction(self, _attack_direction), _curve_side, progress, _state == BladeState.WINDUP, visibility, tuning.slash_width, tuning.slash_color, _state_ticks, _guard_phase, _visual_level)

func _emit_attack_fragment(extra_ticks: float) -> void:
	if !is_instance_valid(_vfx_pool) or _attack_fragment_tick > 0.0:
		return
	var visual_level: int = _visual_level
	if visual_level != FlyingBladeCombatCoordinator.VISUAL_FULL:
		return

	_attack_fragment_tick = max(0.25, tuning.attack_fragment_interval_ticks - extra_ticks * 0.20)
	_spawn_attack_fragment(false)
	if visual_level == FlyingBladeCombatCoordinator.VISUAL_FULL:
		_spawn_attack_fragment(true)

func _spawn_attack_fragment(secondary: bool) -> void:
	var cursor: int = _attack_fragment_cursor
	_attack_fragment_cursor = (_attack_fragment_cursor + 1) % 3
	var base_color: Color = tuning.attack_fragment_color
	if cursor % 3 == 1:
		base_color = tuning.attack_fragment_secondary_color
	elif cursor % 3 == 2:
		base_color = Color(tuning.attack_fragment_color.r, tuning.attack_fragment_color.g, tuning.attack_fragment_color.b, tuning.attack_fragment_color.a * 0.72)

	var side: Vector2 = Vector2(-_attack_direction.y, _attack_direction.x)
	var direction: Vector2 = _attack_direction
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	var center: Vector2 = _body.global_position - direction * rand_range(10.0, 34.0) + side * rand_range(-tuning.arc_radius * 0.34, tuning.arc_radius * 0.34)
	var length_scale: float = rand_range(0.58, 0.92)
	var thickness_scale: float = rand_range(0.24, 0.46)
	if secondary:
		direction = direction.linear_interpolate(side * _curve_side, 0.42).normalized()
		length_scale *= 0.74
		thickness_scale *= 0.82
		center += side * _curve_side * rand_range(10.0, 22.0)

	var global_side: Vector2 = Vector2(-direction.y, direction.x)
	var fragment_velocity: Vector2 = direction * rand_range(70.0, 130.0) + global_side * _curve_side * rand_range(-34.0, 42.0)
	var fragment_color: Color = Color(base_color.r, base_color.g, base_color.b, base_color.a * rand_range(0.72, 1.16))
	var fragment_length: float = tuning.attack_fragment_width * 8.0 * length_scale
	var fragment_width: float = max(1.2, tuning.attack_fragment_width * thickness_scale)
	_vfx_pool.emit_fragment(center, direction.rotated(rand_range(-0.16, 0.16)), fragment_color, tuning.attack_fragment_lifetime, fragment_length, fragment_width, fragment_velocity, _curve_side * (2.2 + float(cursor % 3) * 0.35), Z_SLASH_CORE + 1)

func _emit_blade_afterimage() -> void:
	if !is_instance_valid(_vfx_pool):
		return
	var visual_level: int = _visual_level
	if visual_level != FlyingBladeCombatCoordinator.VISUAL_FULL:
		return
	var current_position: Vector2 = _body.global_position
	if _last_afterimage_position != Vector2.ZERO and _last_afterimage_position.distance_squared_to(current_position) < tuning.blade_afterimage_min_distance * tuning.blade_afterimage_min_distance:
		return
	_last_afterimage_position = current_position
	var color: Color = Color(tuning.trail_core_color.r, tuning.trail_core_color.g, tuning.trail_core_color.b, tuning.blade_afterimage_alpha)
	_vfx_pool.emit_afterimage(_body.texture, _body.centered, _body.offset, _body.flip_h, _body.flip_v, _body.global_position, _animation.global_rotation, _animation.scale, color, tuning.blade_afterimage_lifetime, 8)

func _show_hit_flash(hit_position: Vector2) -> void:
	if !is_instance_valid(_vfx_pool) and is_instance_valid(_combat_coordinator):
		_vfx_pool = _combat_coordinator.get_vfx_pool()
	if !is_instance_valid(_vfx_pool):
		return
	var visual_level: int = _visual_level
	if visual_level >= FlyingBladeCombatCoordinator.VISUAL_ESSENTIAL:
		return
	var direction: Vector2 = _attack_direction
	if direction.length_squared() <= 0.1:
		direction = Vector2.RIGHT
	var color: Color = Color(tuning.trail_core_color.r, tuning.trail_core_color.g, tuning.trail_core_color.b, min(0.85, tuning.hit_flash_alpha))
	_vfx_pool.emit_hit_flash(hit_position, direction.rotated(_curve_side * 0.18), color, 22.0, 0.08, Z_HIT_FLASH)

func _update_body_energy(delta: float) -> void:
	if _state == BladeState.GUARD or _state == BladeState.RETURN:
		if tuning.guard_breathe_scale <= 0.0:
			_body.modulate = _body.modulate.linear_interpolate(Color.white, min(1.0, delta * 8.0))
			_animation.scale = _animation.scale.linear_interpolate(Vector2(1, 1), min(1.0, delta * 8.0))
			return
		var pulse: float = sin(_guard_phase * 3.2) * tuning.guard_breathe_scale
		var target_modulate: Color = Color(1.15 + pulse * 0.8, 1.05 + pulse * 0.45, 1.35 + pulse * 1.1, 1.0)
		var target_scale: Vector2 = Vector2(1.0 + pulse * 0.45, 1.0 + pulse * 0.45)
		_body.modulate = _body.modulate.linear_interpolate(target_modulate, min(1.0, delta * 6.0))
		_animation.scale = _animation.scale.linear_interpolate(target_scale, min(1.0, delta * 6.0))

func _get_preferred_target_angle() -> float:
	return _orbit_angle + _guard_slot_offset + float(_chain_count) * 0.95

func _make_blade_sprite(sprite_name: String, color: Color, z: int, top_level: bool) -> Sprite:
	var sprite_node: Sprite = Sprite.new()
	sprite_node.name = sprite_name
	sprite_node.texture = _body.texture
	sprite_node.centered = _body.centered
	sprite_node.offset = _body.offset
	sprite_node.flip_h = _body.flip_h
	sprite_node.flip_v = _body.flip_v
	var add_mat: CanvasItemMaterial = CanvasItemMaterial.new()
	add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	sprite_node.material = add_mat
	sprite_node.set_as_toplevel(top_level)
	sprite_node.z_as_relative = !top_level
	sprite_node.z_index = z
	sprite_node.modulate = color
	sprite_node.visible = false
	add_child(sprite_node)
	return sprite_node

func _on_Hitbox_hit_something(thing_hit: Node, _damage_dealt: int) -> void:
	RunData.manage_life_steal(_current_weapon_stats, player_index)
	if !_hitbox.ignored_objects.has(thing_hit):
		_hitbox.ignored_objects.push_back(thing_hit)
	if !_targets_hit_this_combo.has(thing_hit):
		_targets_hit_this_combo.push_back(thing_hit)
	_body.modulate = Color(1.45, 1.28, 1.95, 1.0)
	if thing_hit is Node2D:
		_show_hit_flash(thing_hit.global_position)
	_flash_timer.start()

func _on_FlashTimer_timeout() -> void:
	if sprite.material == flash_mat:
		sprite.material = _non_flash_material
	_body.modulate = Color.white
