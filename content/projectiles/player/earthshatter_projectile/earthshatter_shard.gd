extends Node2D

const SECONDARY_DAMAGE = preload("res://mods-unpacked/Yoko-Fantasy/content/utils/secondary_damage.gd")

const SHARD_TEXTURES = [
	preload("res://mods-unpacked/Yoko-Fantasy/content/projectiles/player/earthshatter_projectile/textures/earthshatter_shard_1.webp"),
	preload("res://mods-unpacked/Yoko-Fantasy/content/projectiles/player/earthshatter_projectile/textures/earthshatter_shard_2.webp"),
	preload("res://mods-unpacked/Yoko-Fantasy/content/projectiles/player/earthshatter_projectile/textures/earthshatter_shard_3.webp"),
	preload("res://mods-unpacked/Yoko-Fantasy/content/projectiles/player/earthshatter_projectile/textures/earthshatter_shard_4.webp")
]

var _lifetime: float = 0.38
var _elapsed: float = 0.0
var _main: Node = null
var _pool_id: int = 0
var _velocity: Vector2 = Vector2.ZERO
var _drag_coefficient: float = 3.5
var _angular_vel: float = 0.0
var _opacity: float = 1.0

var _secondary_damage: Reference

onready var _sprite: Sprite = $"%Sprite"
onready var _hitbox: Area2D = $"%Hitbox"


func _ready() -> void:
	visible = false
	set_physics_process(false)
	_hitbox.connect("area_entered", self, "_on_hitbox_area_entered")


func launch_shard(
	start_pos: Vector2,
	initial_dir: Vector2,
	damage: int,
	source: Hitbox,
	main: Node,
	pool_id: int
) -> void:
	_main = main
	_pool_id = pool_id
	_opacity = FantasyProjectileVisualUtils.get_opacity()
	_secondary_damage = SECONDARY_DAMAGE.new(source, damage, Color("#d89e52"))
	_elapsed = 0.0

	global_position = start_pos

	var speed: float = rand_range(900.0, 1350.0)
	_lifetime = rand_range(0.32, 0.42)
	_drag_coefficient = rand_range(2.8, 3.8)
	var scale_mult: float = rand_range(0.132, 0.192)

	_velocity = initial_dir.normalized() * speed
	rotation = rand_range(-PI, PI)
	_angular_vel = rand_range(-14.0, 14.0)

	var tex_idx: int = randi() % SHARD_TEXTURES.size()
	_sprite.texture = SHARD_TEXTURES[tex_idx]
	_sprite.scale = Vector2.ONE * scale_mult
	modulate.a = _opacity

	visible = true
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	_elapsed += delta
	var progress: float = clamp(_elapsed / _lifetime, 0.0, 1.0)

	global_position += _velocity * delta
	rotation += _angular_vel * delta

	_velocity = _velocity.linear_interpolate(Vector2.ZERO, clamp(delta * _drag_coefficient, 0.0, 1.0))

	if progress > 0.5:
		modulate.a = ((1.0 - progress) / 0.5) * _opacity

	if _elapsed >= _lifetime:
		_finish()


func _on_hitbox_area_entered(hurtbox: Area2D) -> void:
	if not is_physics_processing():
		return
	var unit = hurtbox.get_parent()
	if not (unit is Enemy) or unit.dead:
		return

	set_physics_process(false)
	visible = false
	call_deferred("_hit_enemy", unit)


func _hit_enemy(unit: Enemy) -> void:
	_secondary_damage.deal(unit)
	_return_to_pool()


func _finish() -> void:
	set_physics_process(false)
	visible = false
	call_deferred("_return_to_pool")


func _return_to_pool() -> void:
	if is_instance_valid(_main):
		_main.add_node_to_pool(self, _pool_id)


func _exit_tree() -> void:
	_secondary_damage = null
