extends Node2D

const FANTASY_PROJECTILE_VISUAL_UTILS = preload("res://mods-unpacked/Yoko-Fantasy/content/utils/projectile_visual_utils.gd")

const SECONDARY_DAMAGE = preload("res://mods-unpacked/Yoko-Fantasy/content/utils/secondary_damage.gd")

var _lifetime: float = 0.45
var _elapsed: float = 0.0
var _main: Node = null
var _pool_id: int = 0
var _velocity: Vector2 = Vector2.ZERO
var _target: Node = null
var _slow_percent: float = 35.0
var _applies_slow: bool = false
var _opacity: float = 1.0

var _secondary_damage: Reference

onready var _particles: CPUParticles2D = $"%Particles"


func _ready() -> void:
	visible = false
	set_physics_process(false)


func launch(
	start_pos: Vector2,
	initial_dir: Vector2,
	target_enemy: Node,
	damage: int,
	source: Hitbox,
	slow_percent: float,
	applies_slow: bool,
	main: Node,
	pool_id: int
) -> void:
	_main = main
	_pool_id = pool_id
	_opacity = FANTASY_PROJECTILE_VISUAL_UTILS.get_opacity()
	_secondary_damage = SECONDARY_DAMAGE.new(source, damage, Color("#98fb10"))
	_slow_percent = slow_percent
	_applies_slow = applies_slow
	_target = target_enemy
	_elapsed = 0.0

	global_position = start_pos
	_velocity = initial_dir.normalized() * rand_range(580.0, 780.0)
	rotation = _velocity.angle()
	scale = Vector2.ONE * 0.75
	modulate.a = _opacity

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
		modulate.a = ((1.0 - progress) / 0.4) * _opacity

	if _elapsed >= _lifetime:
		_finish()


func _hit_enemy(enemy: Enemy) -> void:
	if enemy.dead:
		_finish()
		return

	var damage_dealt: int = _secondary_damage.deal(enemy)

	if damage_dealt > 0 and not enemy._pending_die and _applies_slow:
		var base_spd = enemy.get_base_speed_value_for_pct_based_decrease()
		enemy.add_decaying_speed(int(base_spd * -abs(_slow_percent) / 100.0))

	_finish()


func _finish() -> void:
	set_physics_process(false)
	visible = false
	_particles.emitting = false
	if _main != null and is_instance_valid(_main):
		_main.add_node_to_pool(self, _pool_id)


func _exit_tree() -> void:
	_secondary_damage = null
