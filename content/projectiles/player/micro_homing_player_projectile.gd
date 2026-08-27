extends PlayerProjectile

const HOMING_REACQUIRE_INTERVAL_MIN: float = 0.08
const HOMING_REACQUIRE_INTERVAL_MAX: float = 0.12
const HOMING_MIN_SPEED_SQ: float = 2500.0
const HOMING_ARRIVAL_RADIUS_SQ: float = 256.0
const HOMING_RELEASE_RANGE_MULT: float = 1.25

var _homing_target: Node = null
var _homing_reacquire_time: float = 0.0


func shoot_ex(
	p_from: Node,
	pos: Vector2,
	p_velocity: Vector2,
	p_rotation: float,
	p_weapon_stats,
	damage_tracking_key: int,
	effects: Array,
	hitbox_args: Hitbox.HitboxArgs,
	knockback_direction: Vector2
) -> void:
	_reset_micro_homing()
	.shoot_ex(p_from, pos, p_velocity, p_rotation, p_weapon_stats, damage_tracking_key, effects, hitbox_args, knockback_direction)


func _process_micro_homing(
	delta: float,
	turn_rate: float,
	max_range: float,
	acquire_fov_deg: float,
	release_fov_deg: float
) -> void:
	if velocity.length_squared() < HOMING_MIN_SPEED_SQ:
		return

	if not _is_valid_homing_target(max_range, release_fov_deg):
		_homing_target = null
		_homing_reacquire_time -= delta
		if _homing_reacquire_time > 0.0:
			return
		_homing_target = _find_best_homing_target(max_range, acquire_fov_deg)
		_homing_reacquire_time = rand_range(HOMING_REACQUIRE_INTERVAL_MIN, HOMING_REACQUIRE_INTERVAL_MAX)
		if _homing_target == null:
			return

	var to_target: Vector2 = _homing_target.global_position - global_position
	if to_target.length_squared() <= HOMING_ARRIVAL_RADIUS_SQ:
		return
	var angle_diff: float = wrapf(to_target.angle() - velocity.angle(), -PI, PI)
	var max_step: float = turn_rate * delta
	velocity = velocity.rotated(clamp(angle_diff, -max_step, max_step))
	rotation = velocity.angle()


func _is_valid_homing_target(max_range: float, release_fov_deg: float) -> bool:
	if not is_instance_valid(_homing_target):
		return false
	if "dead" in _homing_target and _homing_target.dead:
		return false

	var to_target: Vector2 = _homing_target.global_position - global_position
	var distance_squared: float = to_target.length_squared()
	var release_range: float = max_range * HOMING_RELEASE_RANGE_MULT
	if distance_squared > release_range * release_range:
		return false
	if distance_squared <= HOMING_ARRIVAL_RADIUS_SQ:
		return true
	return abs(velocity.angle_to(to_target)) <= deg2rad(release_fov_deg)


func _find_best_homing_target(max_range: float, acquire_fov_deg: float) -> Node:
	var main = Utils.get_scene_node()
	if main == null or main._entity_spawner == null:
		return null

	var current_direction: Vector2 = velocity.normalized()
	var min_fov_dot: float = cos(deg2rad(acquire_fov_deg))
	var best_target: Node = null
	var min_distance_squared: float = max_range * max_range
	for enemy in main._entity_spawner.get_all_enemies(false):
		if not is_instance_valid(enemy) or not (enemy is Enemy) or enemy.dead:
			continue
		var to_enemy: Vector2 = enemy.global_position - global_position
		var distance_squared: float = to_enemy.length_squared()
		if distance_squared > min_distance_squared or distance_squared <= HOMING_ARRIVAL_RADIUS_SQ:
			continue
		if current_direction.dot(to_enemy / sqrt(distance_squared)) < min_fov_dot:
			continue
		min_distance_squared = distance_squared
		best_target = enemy

	return best_target


func _reset_micro_homing() -> void:
	_homing_target = null
	_homing_reacquire_time = 0.0


func _return_to_pool() -> void:
	._return_to_pool()
	_reset_micro_homing()
