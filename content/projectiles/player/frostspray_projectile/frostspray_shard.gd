extends Node2D

const SHARD_TEXTURES = [
	preload("res://mods-unpacked/Yoko-Fantasy/content/projectiles/player/frostspray_projectile/shards/frost_shard_1.webp"),
	preload("res://mods-unpacked/Yoko-Fantasy/content/projectiles/player/frostspray_projectile/shards/frost_shard_2.webp"),
	preload("res://mods-unpacked/Yoko-Fantasy/content/projectiles/player/frostspray_projectile/shards/frost_shard_3.webp"),
	preload("res://mods-unpacked/Yoko-Fantasy/content/projectiles/player/frostspray_projectile/shards/frost_shard_4.webp"),
	preload("res://mods-unpacked/Yoko-Fantasy/content/projectiles/player/frostspray_projectile/shards/frost_shard_5.webp"),
	preload("res://mods-unpacked/Yoko-Fantasy/content/projectiles/player/frostspray_projectile/shards/frost_shard_6.webp"),
	preload("res://mods-unpacked/Yoko-Fantasy/content/projectiles/player/frostspray_projectile/shards/frost_shard_7.webp"),
	preload("res://mods-unpacked/Yoko-Fantasy/content/projectiles/player/frostspray_projectile/shards/frost_shard_8.webp"),
	preload("res://mods-unpacked/Yoko-Fantasy/content/projectiles/player/frostspray_projectile/shards/frost_shard_9.webp"),
	preload("res://mods-unpacked/Yoko-Fantasy/content/projectiles/player/frostspray_projectile/shards/frost_shard_10.webp"),
	preload("res://mods-unpacked/Yoko-Fantasy/content/projectiles/player/frostspray_projectile/shards/frost_shard_11.webp")
]

var _lifetime: float = 0.32
var _elapsed: float = 0.0
var _main: Node = null
var _pool_id: int = 0
var _velocity: Vector2 = Vector2.ZERO
var _drag_coefficient: float = 3.6
var _drift_angular_vel: float = 0.0
var _damage: int = 1
var _player_index: int = 0
var _weapon_pos: int = -1
var _crit_chance: float = 0.05
var _crit_damage: float = 1.5

onready var _sprite: Sprite = $"%Sprite"
onready var _particles: CPUParticles2D = $"%Particles"
onready var _hitbox: Area2D = $"%Hitbox"


func _ready() -> void:
	visible = false
	set_physics_process(false)
	_hitbox.connect("area_entered", self, "_on_hitbox_area_entered")


func launch_advanced(
	start_pos: Vector2,
	initial_dir: Vector2,
	damage: int,
	player_index: int,
	weapon_pos: int,
	crit_chance: float,
	crit_damage: float,
	depth_tier: int,
	main: Node,
	pool_id: int
) -> void:
	_main = main
	_pool_id = pool_id
	_damage = max(1, damage)
	_player_index = player_index
	_weapon_pos = weapon_pos
	_crit_chance = crit_chance
	_crit_damage = crit_damage
	_elapsed = 0.0

	global_position = start_pos

	var speed: float
	var scale_mult: float
	if depth_tier == 0:
		speed = rand_range(1450.0, 1750.0)
		_lifetime = rand_range(0.36, 0.44)
		_drag_coefficient = 2.4
		scale_mult = rand_range(1.0, 1.25)
	elif depth_tier == 1:
		speed = rand_range(1100.0, 1350.0)
		_lifetime = rand_range(0.28, 0.34)
		_drag_coefficient = 3.8
		scale_mult = rand_range(0.85, 1.05)
	else:
		speed = rand_range(800.0, 1050.0)
		_lifetime = rand_range(0.20, 0.26)
		_drag_coefficient = 5.2
		scale_mult = rand_range(0.7, 0.9)

	_velocity = initial_dir.normalized() * speed
	rotation = _velocity.angle()
	_drift_angular_vel = rand_range(-1.5, 1.5)

	var tex_idx: int = randi() % SHARD_TEXTURES.size()
	_sprite.texture = SHARD_TEXTURES[tex_idx]
	_sprite.rotation = 0.0
	_sprite.scale = Vector2.ONE * scale_mult
	modulate.a = 1.0

	_particles.emitting = true
	_particles.restart()
	visible = true
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	_elapsed += delta
	var progress: float = clamp(_elapsed / _lifetime, 0.0, 1.0)

	if abs(_drift_angular_vel) > 0.01:
		_velocity = _velocity.rotated(_drift_angular_vel * delta)

	global_position += _velocity * delta
	if _velocity.length_squared() > 10.0:
		rotation = _velocity.angle()

	_velocity = _velocity.linear_interpolate(Vector2.ZERO, delta * _drag_coefficient)

	if progress > 0.45:
		modulate.a = (1.0 - progress) / 0.55

	if _elapsed >= _lifetime:
		_finish()


func _on_hitbox_area_entered(hurtbox: Area2D) -> void:
	if not visible or not is_physics_processing():
		return
	var unit = hurtbox.get_parent()
	if unit == null or not (unit is Enemy) or unit.dead:
		return

	var was_crit: bool = Utils.get_chance_success(_crit_chance)
	var final_damage: float = float(_damage)
	if was_crit:
		final_damage *= _crit_damage

	var dmg_args: TakeDamageArgs = Utils.ncl_create_custom_damage_args(_player_index, Color("#88ddff"))
	var health_before: int = unit.current_stats.health
	var damage_taken: Array = unit.take_damage(int(final_damage), dmg_args)
	RunData.add_weapon_dmg_dealt(_weapon_pos, damage_taken[1], _player_index)

	Utils.fa_apply_direct_crit_kill_gold_rewards(
		_player_index,
		was_crit,
		health_before > 0 and damage_taken[1] >= health_before
	)

	set_physics_process(false)
	visible = false
	_particles.emitting = false
	call_deferred("_finish")


func _finish() -> void:
	set_physics_process(false)
	visible = false
	_particles.emitting = false
	if _main != null and is_instance_valid(_main):
		_main.add_node_to_pool(self, _pool_id)
