extends Node2D

var _lifetime: float = 0.25
var _elapsed: float = 0.0
var _main: Node = null
var _pool_id: int = 0

onready var _ring_sprite: Sprite = $"%RingSprite"
onready var _splash_sprite: Sprite = $"%SplashSprite"
onready var _sparkle_particles: CPUParticles2D = $"%SparkleParticles"


func _ready() -> void:
	visible = false
	set_process(false)


func play(at_position: Vector2, main: Node, pool_id: int) -> void:
	_main = main
	_pool_id = pool_id
	_elapsed = 0.0
	global_position = at_position
	visible = true

	_ring_sprite.scale = Vector2.ONE * 0.2
	_ring_sprite.modulate.a = 1.0
	_ring_sprite.rotation = rand_range(0, TAU)

	_splash_sprite.scale = Vector2.ONE * 0.4
	_splash_sprite.modulate.a = 1.0
	_splash_sprite.rotation = rand_range(0, TAU)

	_sparkle_particles.emitting = true
	_sparkle_particles.restart()

	set_process(true)


func _process(delta: float) -> void:
	_elapsed += delta
	var progress = clamp(_elapsed / _lifetime, 0.0, 1.0)
	var ease_out = 1.0 - pow(1.0 - progress, 2)

	_ring_sprite.scale = Vector2.ONE * (0.2 + 1.5 * ease_out)
	_ring_sprite.modulate.a = (1.0 - progress) * 0.95

	_splash_sprite.scale = Vector2.ONE * (0.4 + 0.9 * ease_out)
	_splash_sprite.modulate.a = (1.0 - progress)
	_splash_sprite.rotation += delta * 4.0

	if _elapsed >= _lifetime:
		_finish()


func _finish() -> void:
	visible = false
	_sparkle_particles.emitting = false
	set_process(false)
	if _main != null and is_instance_valid(_main):
		_main.add_node_to_pool(self, _pool_id)
