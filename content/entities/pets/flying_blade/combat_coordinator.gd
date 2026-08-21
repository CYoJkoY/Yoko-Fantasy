extends Node2D

const FlyingBladeTargetSensor = preload("res://mods-unpacked/Yoko-Fantasy/content/entities/pets/flying_blade/target_sensor.gd")
const FlyingBladeVfxPool = preload("res://mods-unpacked/Yoko-Fantasy/content/entities/pets/flying_blade/vfx_pool.gd")

const ROLE_MAIN = "main"
const ROLE_SATELLITE = "satellite"
const VISUAL_FULL = 0
const VISUAL_REDUCED = 1
const VISUAL_MINIMAL = 2
const VISUAL_ESSENTIAL = 3
const TARGET_CACHE_REFRESH_TICKS = 30.0
const REGISTRY_PRUNE_TICKS = 30.0
const CLAIM_PRUNE_TICKS = 6.0
const MAIN_CLAIM_WEIGHT = 0.65
const SATELLITE_CLAIM_WEIGHT = 0.95

var player_index: int = -1
var players_ref: Array = []

var _target_sensor = null
var _vfx_pool = null
var _sensor_radius: float = 0.0
var _radius_requests: Dictionary = {}
var _main_swords: Array = []
var _satellites: Array = []
var _target_cache: Array = []
var _target_cache_ticks: float = 0.0
var _registry_prune_ticks: float = REGISTRY_PRUNE_TICKS
var _claim_prune_ticks: float = CLAIM_PRUNE_TICKS
var _time_ticks: float = 0.0
var _actor_claims: Dictionary = {}
var _target_claims: Dictionary = {}
var _last_target_count: int = 0

var _main_attack_queue: Array = []
var _satellite_attack_queue: Array = []
var _queued_actors: Dictionary = {}
var _active_main_attacks: Dictionary = {}
var _active_satellite_attacks: Dictionary = {}
var _active_hitboxes: Dictionary = {}
var _next_dispatch_role: int = 0
var _max_active_main_attacks: int = 0
var _max_active_satellite_attacks: int = 0
var _max_dispatches_per_tick: int = 2
var _visual_frame: int = 0
var _debug_metrics_enabled: bool = false
var _main_visual_levels: Dictionary = {}
var _satellite_visual_levels: Dictionary = {}
var _satellite_idle_visibility: Dictionary = {}
var _full_visual_count: int = 4
var _reduced_visual_count: int = 8
var _minimal_visual_count: int = 16
var _crowded_reduced_visual_slots: int = 3
var _crowded_minimal_visual_slots: int = 3
var _satellite_idle_visible_count: int = 8

var _debug_selection_attempts: int = 0
var _debug_candidate_evaluations: int = 0
var _debug_selection_failures: int = 0
var _debug_dispatches: int = 0
var _debug_lost_targets: int = 0
var _debug_retarget_successes: int = 0
var _debug_retarget_failures: int = 0
var _debug_visual_redraws: int = 0
var _debug_visual_skips: int = 0

func setup(p_player_index: int, p_players_ref: Array, radius: float) -> void:
	player_index = p_player_index
	players_ref = p_players_ref
	_setup_target_sensor()
	_setup_vfx_pool()
	_sensor_radius = max(radius, 96.0)
	if is_instance_valid(_target_sensor):
		_target_sensor.set_radius(_sensor_radius)
	_update_sensor_position()
	_refresh_target_cache()
	_target_cache_ticks = TARGET_CACHE_REFRESH_TICKS

func configure_attack_limits(max_main: int, max_satellite: int, dispatches_per_tick: int) -> void:
	# Zero keeps concurrency gameplay-neutral: every ready sword may attack.
	_max_active_main_attacks = max(0, max_main)
	_max_active_satellite_attacks = max(0, max_satellite)
	_max_dispatches_per_tick = max(1, dispatches_per_tick)

func configure_visual_budgets(full_count: int, reduced_count: int, minimal_count: int, crowded_reduced_slots: int, crowded_minimal_slots: int, satellite_idle_count: int) -> void:
	var next_full: int = int(max(1, full_count))
	var next_reduced: int = int(max(next_full, reduced_count))
	var next_minimal: int = int(max(next_reduced, minimal_count))
	var next_crowded_reduced: int = int(max(0, crowded_reduced_slots))
	var next_crowded_minimal: int = int(max(0, crowded_minimal_slots))
	var next_satellite_idle: int = int(max(1, satellite_idle_count))
	if next_full == _full_visual_count and next_reduced == _reduced_visual_count and next_minimal == _minimal_visual_count and next_crowded_reduced == _crowded_reduced_visual_slots and next_crowded_minimal == _crowded_minimal_visual_slots and next_satellite_idle == _satellite_idle_visible_count:
		return
	_full_visual_count = next_full
	_reduced_visual_count = next_reduced
	_minimal_visual_count = next_minimal
	_crowded_reduced_visual_slots = next_crowded_reduced
	_crowded_minimal_visual_slots = next_crowded_minimal
	_satellite_idle_visible_count = next_satellite_idle
	_refresh_visual_policy()

func register_main(sword: Node, radius: float) -> void:
	if !_main_swords.has(sword):
		_main_swords.push_back(sword)
	_refresh_visual_policy()
	request_sensor_radius(sword, radius)

func unregister_main(sword: Node) -> void:
	cancel_attack(sword, ROLE_MAIN)
	_main_swords.erase(sword)
	_clear_radius_request(sword)
	_refresh_visual_policy()
	_try_shutdown_when_empty()

func register_satellite(satellite: Node) -> void:
	if !_satellites.has(satellite):
		_satellites.push_back(satellite)
	_refresh_visual_policy()
	_refresh_satellite_formation()

func unregister_satellite(satellite: Node) -> void:
	cancel_attack(satellite, ROLE_SATELLITE)
	_satellites.erase(satellite)
	_clear_radius_request(satellite)
	_refresh_satellite_formation()
	_refresh_visual_policy()
	_try_shutdown_when_empty()

func request_sensor_radius(owner: Node, radius: float) -> void:
	_radius_requests[owner.get_instance_id()] = {
		"owner": owner,
		"radius": radius
	}
	_recalculate_sensor_radius()

func get_main_count() -> int:
	return _main_swords.size()

func get_satellite_count() -> int:
	return _satellites.size()

func get_visual_lod() -> int:
	var count: int = get_main_count()
	if get_satellite_count() > count:
		count = get_satellite_count()
	if count <= _full_visual_count:
		return VISUAL_FULL
	if count <= _reduced_visual_count:
		return VISUAL_REDUCED
	if count <= _minimal_visual_count:
		return VISUAL_MINIMAL
	return VISUAL_ESSENTIAL

func get_actor_visual_level(actor: Node, role: String) -> int:
	if !is_instance_valid(actor):
		return VISUAL_ESSENTIAL
	var levels: Dictionary = _satellite_visual_levels if role == ROLE_SATELLITE else _main_visual_levels
	return int(levels.get(actor.get_instance_id(), get_visual_lod()))

func is_satellite_idle_body_visible(satellite: Node) -> bool:
	if !is_instance_valid(satellite):
		return false
	return bool(_satellite_idle_visibility.get(satellite.get_instance_id(), true))

func get_vfx_pool():
	_setup_vfx_pool()
	return _vfx_pool

func get_actor_scan_offset(actor: Node, period_ticks: float) -> float:
	var period: float = max(period_ticks, 1.0)
	var instance_id: int = actor.get_instance_id()
	var bucket: int = instance_id % 997
	return (float(bucket % 100) / 100.0) * period

func get_retry_ticks(role: String) -> float:
	return 2.0 if role == ROLE_SATELLITE else 1.5

func get_next_cooldown(base_ticks: float, role: String) -> float:
	var base: float = max(base_ticks, 1.0)
	var count: int = get_satellite_count() if role == ROLE_SATELLITE else get_main_count()
	var capped_count: int = count
	if capped_count < 1:
		capped_count = 1
	elif capped_count > 6:
		capped_count = 6
	var max_rand: float = min(float(capped_count) * base / 5.0, float(capped_count) * 5.0)
	return rand_range(max(1.0, base - max_rand), base + max_rand)

func enqueue_attack(actor: Node, role: String) -> bool:
	if !is_instance_valid(actor):
		return false
	var actor_id: int = actor.get_instance_id()
	if _queued_actors.has(actor_id) or _get_active_attacks(role).has(actor_id):
		return true
	_get_attack_queue(role).push_back(actor)
	_queued_actors[actor_id] = role
	return true

func release_attack(actor: Node, role: String) -> void:
	var actor_id: int = actor.get_instance_id()
	_get_active_attacks(role).erase(actor_id)
	_active_hitboxes.erase(actor_id)
	_release_actor_claim(actor_id)

func cancel_attack(actor: Node, role: String) -> void:
	var actor_id: int = actor.get_instance_id()
	_queued_actors.erase(actor_id)
	_get_active_attacks(role).erase(actor_id)
	_get_attack_queue(role).erase(actor)
	_active_hitboxes.erase(actor_id)
	_release_actor_claim(actor_id)

func claim_target(actor: Node, target: Node, role: String) -> void:
	if !is_instance_valid(actor) or !_is_target_valid(target):
		return
	var actor_id: int = actor.get_instance_id()
	var target_id: int = target.get_instance_id()
	if _actor_claims.has(actor_id):
		var current: Dictionary = _actor_claims[actor_id]
		if current["target_id"] == target_id and current["role"] == role:
			return
		_release_actor_claim(actor_id)

	_actor_claims[actor_id] = {
		"actor": actor,
		"target": target,
		"target_id": target_id,
		"role": role
	}
	_increment_target_claim(target, target_id, role)

func report_target_lost() -> void:
	if _debug_metrics_enabled:
		_debug_lost_targets += 1

func report_retarget_result(success: bool) -> void:
	if !_debug_metrics_enabled:
		return
	if success:
		_debug_retarget_successes += 1
	else:
		_debug_retarget_failures += 1

func report_hitbox_state(actor: Node, active: bool) -> void:
	if !is_instance_valid(actor):
		return
	var actor_id: int = actor.get_instance_id()
	if active:
		_active_hitboxes[actor_id] = actor
	else:
		_active_hitboxes.erase(actor_id)

func should_redraw_attack_visual(actor: Node, role: String = ROLE_MAIN) -> bool:
	var visual_level: int = get_actor_visual_level(actor, role)
	if visual_level >= VISUAL_ESSENTIAL:
		if _debug_metrics_enabled:
			_debug_visual_skips += 1
		return false
	if visual_level < VISUAL_MINIMAL:
		if _debug_metrics_enabled:
			_debug_visual_redraws += 1
		return true
	var actor_bucket: int = actor.get_instance_id() % 2
	if (_visual_frame + actor_bucket) % 2 == 0:
		if _debug_metrics_enabled:
			_debug_visual_redraws += 1
		return true
	if _debug_metrics_enabled:
		_debug_visual_skips += 1
	return false

func select_main_target(actor: Node, excluded: Array, origin: Vector2, radius: float, min_range: float, player_position: Vector2, preferred_angle: float, chain_count: int, attack_direction: Vector2, origin_weight: float, player_weight: float, angle_weight: float, follow_weight: float) -> Node2D:
	var targets: Array = _target_cache
	_last_target_count = targets.size()
	if _debug_metrics_enabled:
		_debug_selection_attempts += 1
		_debug_candidate_evaluations += targets.size()
	var best_target: Node2D = null
	var best_score: float = Utils.LARGE_NUMBER
	var radius_sq: float = radius * radius
	var min_dist_sq: float = min_range * min_range
	var spread_factor: float = clamp(float(_last_target_count - 5) / 18.0, 0.0, 1.0)

	var origin_is_player: bool = origin.distance_squared_to(player_position) <= 0.01
	for target in targets:
		if !_is_target_valid(target) or excluded.has(target):
			continue
		var target_position: Vector2 = target.global_position
		var dist_from_origin: float = origin.distance_squared_to(target_position)
		if dist_from_origin < min_dist_sq or dist_from_origin > radius_sq:
			continue
		var player_dist: float = dist_from_origin if origin_is_player else player_position.distance_squared_to(target_position)
		var angle_penalty: float = 0.0
		if spread_factor > 0.0 and angle_weight != 0.0:
			angle_penalty = _get_target_angle_penalty(player_position, target_position, preferred_angle, radius, angle_weight) * spread_factor
		var follow_penalty: float = 0.0
		if chain_count > 0:
			follow_penalty = _get_follow_through_penalty(origin, target_position, attack_direction, radius, follow_weight) * max(spread_factor, 0.45)
		var score: float = dist_from_origin * origin_weight + player_dist * player_weight + angle_penalty + follow_penalty
		score += _get_claim_penalty(actor, target, radius_sq, ROLE_MAIN)
		if score < best_score:
			best_score = score
			best_target = target

	if best_target == null and _debug_metrics_enabled:
		_debug_selection_failures += 1
	return best_target

func select_nearest_target(actor: Node, origin: Vector2, radius: float, min_range: float = 0.0) -> Node2D:
	var targets: Array = _target_cache
	_last_target_count = targets.size()
	if _debug_metrics_enabled:
		_debug_selection_attempts += 1
		_debug_candidate_evaluations += targets.size()
	var best_target: Node2D = null
	var best_score: float = Utils.LARGE_NUMBER
	var radius_sq: float = radius * radius
	var min_dist_sq: float = min_range * min_range

	for target in targets:
		if !_is_target_valid(target):
			continue
		var distance: float = origin.distance_squared_to(target.global_position)
		if distance < min_dist_sq or distance > radius_sq:
			continue
		var score: float = distance + _get_claim_penalty(actor, target, radius_sq, ROLE_SATELLITE)
		if score < best_score:
			best_score = score
			best_target = target

	if best_target == null and _debug_metrics_enabled:
		_debug_selection_failures += 1
	return best_target

func get_orbit_phase(orbit_speed: float) -> float:
	return (_time_ticks / 60.0) * orbit_speed * 0.72

func get_debug_snapshot() -> Dictionary:
	return {
		"main_swords": _main_swords.size(),
		"satellites": _satellites.size(),
		"targets": _last_target_count,
		"sensor_radius": _sensor_radius,
		"queued_main": _main_attack_queue.size(),
		"queued_satellites": _satellite_attack_queue.size(),
		"active_main": _active_main_attacks.size(),
		"active_satellites": _active_satellite_attacks.size(),
		"main_attack_limit": _get_active_attack_limit(ROLE_MAIN),
		"satellite_attack_limit": _get_active_attack_limit(ROLE_SATELLITE),
		"claimed_actors": _actor_claims.size(),
		"claimed_targets": _target_claims.size(),
		"active_hitboxes": _active_hitboxes.size(),
		"visual_lod": get_visual_lod(),
		"vfx_budget": _get_vfx_budget(),
		"metrics_enabled": _debug_metrics_enabled,
		"selection_attempts": _debug_selection_attempts,
		"candidate_evaluations": _debug_candidate_evaluations,
		"selection_failures": _debug_selection_failures,
		"dispatches": _debug_dispatches,
		"lost_targets": _debug_lost_targets,
		"retarget_successes": _debug_retarget_successes,
		"retarget_failures": _debug_retarget_failures,
		"visual_redraws": _debug_visual_redraws,
		"visual_skips": _debug_visual_skips
	}

func set_debug_metrics_enabled(enabled: bool) -> void:
	_debug_metrics_enabled = enabled
	reset_debug_counters()

func reset_debug_counters() -> void:
	_debug_selection_attempts = 0
	_debug_candidate_evaluations = 0
	_debug_selection_failures = 0
	_debug_dispatches = 0
	_debug_lost_targets = 0
	_debug_retarget_successes = 0
	_debug_retarget_failures = 0
	_debug_visual_redraws = 0
	_debug_visual_skips = 0

func shutdown() -> void:
	if is_instance_valid(_target_sensor):
		_target_sensor.shutdown()
	_target_sensor = null
	_vfx_pool = null
	_target_cache.clear()
	_main_swords.clear()
	_satellites.clear()
	_radius_requests.clear()
	_actor_claims.clear()
	_target_claims.clear()
	_main_attack_queue.clear()
	_satellite_attack_queue.clear()
	_queued_actors.clear()
	_active_main_attacks.clear()
	_active_satellite_attacks.clear()
	_active_hitboxes.clear()
	_main_visual_levels.clear()
	_satellite_visual_levels.clear()
	_satellite_idle_visibility.clear()
	queue_free()

func _physics_process(delta: float) -> void:
	var ticks: float = Utils.physics_one(delta)
	_time_ticks += ticks
	_target_cache_ticks -= ticks
	_registry_prune_ticks -= ticks
	_claim_prune_ticks -= ticks
	_visual_frame += 1
	_update_sensor_position()

	if _target_cache_ticks <= 0.0:
		_refresh_target_cache()
		_target_cache_ticks = TARGET_CACHE_REFRESH_TICKS
	if _claim_prune_ticks <= 0.0:
		_prune_target_claims()
		_claim_prune_ticks = CLAIM_PRUNE_TICKS
	if _registry_prune_ticks <= 0.0:
		_prune_registries()
		_registry_prune_ticks = REGISTRY_PRUNE_TICKS

	for _i in range(_max_dispatches_per_tick):
		if !_dispatch_next_attack():
			break

func _dispatch_next_attack() -> bool:
	for _attempt in range(2):
		var role: String = ROLE_MAIN if _next_dispatch_role == 0 else ROLE_SATELLITE
		_next_dispatch_role = 1 - _next_dispatch_role
		if _dispatch_role(role):
			return true
	return false

func _dispatch_role(role: String) -> bool:
	var active: Dictionary = _get_active_attacks(role)
	var max_active: int = _get_active_attack_limit(role)
	if active.size() >= max_active:
		return false

	var queue: Array = _get_attack_queue(role)
	while !queue.empty():
		var actor = queue.pop_front()
		if !is_instance_valid(actor):
			continue
		var actor_id: int = actor.get_instance_id()
		_queued_actors.erase(actor_id)
		var target: Node2D = actor.get_coordinated_attack_target()
		if !_is_target_valid(target):
			actor.coordinated_attack_failed()
			return true
		active[actor_id] = actor
		claim_target(actor, target, role)
		if _debug_metrics_enabled:
			_debug_dispatches += 1
		actor.begin_coordinated_attack(target)
		return true
	return false

func _get_attack_queue(role: String) -> Array:
	return _satellite_attack_queue if role == ROLE_SATELLITE else _main_attack_queue

func _get_active_attacks(role: String) -> Dictionary:
	return _active_satellite_attacks if role == ROLE_SATELLITE else _active_main_attacks

func _get_active_attack_limit(role: String) -> int:
	var actor_count: int = _satellites.size() if role == ROLE_SATELLITE else _main_swords.size()
	var configured_limit: int = _max_active_satellite_attacks if role == ROLE_SATELLITE else _max_active_main_attacks
	if configured_limit <= 0:
		return actor_count
	if configured_limit < actor_count:
		return configured_limit
	return actor_count

func _setup_target_sensor() -> void:
	if is_instance_valid(_target_sensor):
		return
	_target_sensor = FlyingBladeTargetSensor.new()
	_target_sensor.name = "SharedTargetSensor"
	add_child(_target_sensor)
	_target_sensor.setup(Utils.ENEMIES_BIT)

func _setup_vfx_pool() -> void:
	if is_instance_valid(_vfx_pool):
		return
	_vfx_pool = FlyingBladeVfxPool.new()
	_vfx_pool.name = "FlyingBladeVfxPool"
	add_child(_vfx_pool)
	_update_vfx_capacity()

func _update_vfx_capacity() -> void:
	if is_instance_valid(_vfx_pool):
		_vfx_pool.ensure_capacity(_get_vfx_budget())

func _update_sensor_position() -> void:
	global_position = _get_player_position()

func _get_player_position() -> Vector2:
	if player_index >= 0 and player_index < players_ref.size() and is_instance_valid(players_ref[player_index]):
		return players_ref[player_index].global_position
	return global_position

func _refresh_target_cache() -> void:
	if !is_instance_valid(_target_sensor):
		_target_cache.clear()
		_last_target_count = 0
		return
	_target_cache = _target_sensor.get_targets()
	_last_target_count = _target_cache.size()

func _increment_target_claim(target: Node, target_id: int, role: String) -> void:
	var data: Dictionary = {
		"target": target,
		"main_count": 0,
		"satellite_count": 0
	}
	if _target_claims.has(target_id):
		data = _target_claims[target_id]
	if role == ROLE_SATELLITE:
		data["satellite_count"] = int(data["satellite_count"]) + 1
	else:
		data["main_count"] = int(data["main_count"]) + 1
	_target_claims[target_id] = data

func _release_actor_claim(actor_id: int) -> void:
	if !_actor_claims.has(actor_id):
		return
	var claim: Dictionary = _actor_claims[actor_id]
	_actor_claims.erase(actor_id)
	var target_id: int = int(claim["target_id"])
	if !_target_claims.has(target_id):
		return
	var data: Dictionary = _target_claims[target_id]
	if claim["role"] == ROLE_SATELLITE:
		var satellite_count: int = int(data["satellite_count"]) - 1
		data["satellite_count"] = satellite_count if satellite_count > 0 else 0
	else:
		var main_count: int = int(data["main_count"]) - 1
		data["main_count"] = main_count if main_count > 0 else 0
	if int(data["main_count"]) <= 0 and int(data["satellite_count"]) <= 0:
		_target_claims.erase(target_id)
	else:
		_target_claims[target_id] = data

func _prune_target_claims() -> void:
	var stale_actor_ids: Array = []
	for actor_id in _actor_claims:
		var claim: Dictionary = _actor_claims[actor_id]
		if !is_instance_valid(claim["actor"]) or !_is_target_valid(claim["target"]):
			stale_actor_ids.push_back(actor_id)
	for actor_id in stale_actor_ids:
		_release_actor_claim(int(actor_id))

func _get_claim_penalty(actor: Node, target: Node, radius_sq: float, role: String) -> float:
	var target_id: int = target.get_instance_id()
	if !_target_claims.has(target_id):
		return 0.0
	var data: Dictionary = _target_claims[target_id]
	var weighted_claims: float = float(data["main_count"]) * MAIN_CLAIM_WEIGHT + float(data["satellite_count"]) * SATELLITE_CLAIM_WEIGHT
	var actor_id: int = actor.get_instance_id()
	if _actor_claims.has(actor_id):
		var own_claim: Dictionary = _actor_claims[actor_id]
		if own_claim["target_id"] == target_id:
			weighted_claims -= SATELLITE_CLAIM_WEIGHT if own_claim["role"] == ROLE_SATELLITE else MAIN_CLAIM_WEIGHT
	if weighted_claims <= 0.0:
		return 0.0
	var role_scale: float = 0.42 if role == ROLE_MAIN else 0.62
	return radius_sq * weighted_claims * role_scale

func _get_target_angle_penalty(player_position: Vector2, target_position: Vector2, preferred_angle: float, radius: float, angle_weight: float) -> float:
	var direction: Vector2 = player_position.direction_to(target_position)
	if direction == Vector2.ZERO:
		return 0.0
	var diff: float = atan2(sin(direction.angle() - preferred_angle), cos(direction.angle() - preferred_angle))
	return abs(diff) * radius * radius * angle_weight

func _get_follow_through_penalty(origin: Vector2, target_position: Vector2, attack_direction: Vector2, radius: float, follow_weight: float) -> float:
	if attack_direction.length_squared() <= 0.1:
		return 0.0
	var from_blade: Vector2 = origin.direction_to(target_position)
	if from_blade == Vector2.ZERO:
		return 0.0
	var alignment: float = clamp(attack_direction.normalized().dot(from_blade), -1.0, 1.0)
	return (1.0 - alignment) * radius * radius * follow_weight

func _clear_radius_request(owner: Node) -> void:
	_radius_requests.erase(owner.get_instance_id())
	_recalculate_sensor_radius()

func _recalculate_sensor_radius() -> void:
	var max_radius: float = 96.0
	var stale: Array = []
	for key in _radius_requests:
		var data: Dictionary = _radius_requests[key]
		if !is_instance_valid(data["owner"]):
			stale.push_back(key)
			continue
		max_radius = max(max_radius, data["radius"])
	for key in stale:
		_radius_requests.erase(key)
	_sensor_radius = max_radius
	if is_instance_valid(_target_sensor):
		_target_sensor.set_radius(_sensor_radius)

func _refresh_satellite_formation() -> void:
	var count: int = _satellites.size()
	for i in range(count):
		var satellite = _satellites[i]
		if is_instance_valid(satellite):
			satellite.set_formation(i, count)

func _refresh_visual_policy() -> void:
	_main_visual_levels.clear()
	_satellite_visual_levels.clear()
	_satellite_idle_visibility.clear()
	_assign_visual_levels(_main_swords, ROLE_MAIN)
	_assign_visual_levels(_satellites, ROLE_SATELLITE)
	for i in range(_satellites.size()):
		var satellite = _satellites[i]
		if is_instance_valid(satellite):
			_satellite_idle_visibility[satellite.get_instance_id()] = i < _satellite_idle_visible_count
	_update_vfx_capacity()

func _assign_visual_levels(actors: Array, role: String) -> void:
	var global_level: int = get_visual_lod()
	var levels: Dictionary = _satellite_visual_levels if role == ROLE_SATELLITE else _main_visual_levels
	for i in range(actors.size()):
		var actor = actors[i]
		if !is_instance_valid(actor):
			continue
		var level: int = global_level
		if global_level == VISUAL_MINIMAL and i < _crowded_reduced_visual_slots:
			level = VISUAL_REDUCED
		elif global_level == VISUAL_ESSENTIAL:
			if i < _crowded_reduced_visual_slots:
				level = VISUAL_REDUCED
			elif i < _crowded_reduced_visual_slots + _crowded_minimal_visual_slots:
				level = VISUAL_MINIMAL
		levels[actor.get_instance_id()] = level

func _get_vfx_budget() -> int:
	var count: int = int(max(_main_swords.size(), _satellites.size()))
	if count <= _full_visual_count:
		return int(max(1, count))
	if count <= _reduced_visual_count:
		return int(min(count, 6))
	return int(max(1, _crowded_reduced_visual_slots + _crowded_minimal_visual_slots))

func _prune_registries() -> void:
	for i in range(_main_swords.size() - 1, -1, -1):
		if !is_instance_valid(_main_swords[i]):
			_main_swords.remove(i)
	for i in range(_satellites.size() - 1, -1, -1):
		if !is_instance_valid(_satellites[i]):
			_satellites.remove(i)
	_prune_attack_state(_main_attack_queue, _active_main_attacks)
	_prune_attack_state(_satellite_attack_queue, _active_satellite_attacks)
	_queued_actors.clear()
	for actor in _main_attack_queue:
		if is_instance_valid(actor):
			_queued_actors[actor.get_instance_id()] = ROLE_MAIN
	for actor in _satellite_attack_queue:
		if is_instance_valid(actor):
			_queued_actors[actor.get_instance_id()] = ROLE_SATELLITE
	_refresh_satellite_formation()
	_refresh_visual_policy()

func _prune_attack_state(queue: Array, active: Dictionary) -> void:
	for i in range(queue.size() - 1, -1, -1):
		var actor = queue[i]
		if !is_instance_valid(actor):
			queue.remove(i)
	var stale: Array = []
	for key in active:
		if !is_instance_valid(active[key]):
			stale.push_back(key)
	for key in stale:
		active.erase(key)
		_queued_actors.erase(key)
		_active_hitboxes.erase(key)
		_release_actor_claim(int(key))

func _try_shutdown_when_empty() -> void:
	if _main_swords.empty() and _satellites.empty():
		shutdown()

func _is_target_valid(target: Node) -> bool:
	if !is_instance_valid(target):
		return false
	if not (target is Node2D):
		return false
	return !target.dead
