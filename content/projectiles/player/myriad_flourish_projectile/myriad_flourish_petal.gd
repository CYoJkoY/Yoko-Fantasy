extends Node2D

var _lifetime: float = 0.45
var _elapsed: float = 0.0
var _main: Node = null
var _pool_id: int = 0
var _velocity: Vector2 = Vector2.ZERO
var _target: Node = null
var _damage: int = 1
var _player_index: int = 0
var _weapon_pos: int = -1
var _crit_chance: float = 0.05
var _crit_damage: float = 1.5
var _slow_percent: float = 35.0
var _applies_slow: bool = false

onready var _particles: CPUParticles2D = $"%Particles"


func _ready() -> void:
	visible = false
	set_physics_process(false)


func launch(
	start_pos: Vector2,
	initial_dir: Vector2,
	target_enemy: Node,
	damage: int,
	player_index: int,
	weapon_pos: int,
	crit_chance: float,
	crit_damage: float,
	slow_percent: float,
	applies_slow: bool,
	main: Node,
	pool_id: int
) -> void:
	_main = main
	_pool_id = pool_id
	_damage = damage
	_player_index = player_index
	_weapon_pos = weapon_pos
	_crit_chance = crit_chance
	_crit_damage = crit_damage
	_slow_percent = slow_percent
	_applies_slow = applies_slow
	_target = target_enemy
	_elapsed = 0.0

	global_position = start_pos
	_velocity = initial_dir.normalized() * rand_range(580.0, 780.0)
	rotation = _velocity.angle()
	scale = Vector2.ONE * 0.75
	modulate.a = 1.0

	_particles.emitting = true
	_particles.restart()
	visible = true
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	_elapsed += delta
	var progress = clamp(_elapsed / _lifetime, 0.0, 1.0)

	if is_instance_valid(_target) and _target is Enemy and not _target.dead:
		var to_target = (_target.global_position - global_position).normalized()
		_velocity = _velocity.linear_interpolate(to_target * 720.0, delta * 7.5)

		if global_position.distance_squared_to(_target.global_position) < 32.0 * 32.0:
			_hit_enemy(_target)
			return

	global_position += _velocity * delta
	rotation = _velocity.angle()

	if progress > 0.6:
		modulate.a = (1.0 - progress) / 0.4

	if _elapsed >= _lifetime:
		_finish()


func _hit_enemy(enemy: Enemy) -> void:
	if enemy.dead:
		_finish()
		return

	var dmg_args: TakeDamageArgs = Utils.ncl_create_custom_damage_args(_player_index, Color("#98fb10"))

	var final_damage: float = float(_damage)
	var was_crit: bool = Utils.get_chance_success(_crit_chance)
	if was_crit:
		final_damage *= _crit_damage

	var health_before: int = enemy.current_stats.health
	var damage_taken: Array = enemy.take_damage(int(final_damage), dmg_args)
	RunData.add_weapon_dmg_dealt(_weapon_pos, damage_taken[1], _player_index)
	Utils.fa_apply_direct_crit_kill_gold_rewards(
		_player_index,
		was_crit,
		health_before > 0 and damage_taken[1] >= health_before
	)

	if _applies_slow and enemy.has_method("add_decaying_speed") and enemy.has_method("get_base_speed_value_for_pct_based_decrease"):
		var base_spd = enemy.get_base_speed_value_for_pct_based_decrease()
		enemy.add_decaying_speed(int(base_spd * -abs(_slow_percent) / 100.0))

	_finish()


func _finish() -> void:
	set_physics_process(false)
	visible = false
	_particles.emitting = false
	if _main != null and is_instance_valid(_main):
		_main.add_node_to_pool(self, _pool_id)
