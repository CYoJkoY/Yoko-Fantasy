extends Node2D

var _lifetime: float = 0.25
var _elapsed: float = 0.0
var _main: Node = null
var _pool_id: int = 0

onready var _sprite: Sprite = $Sprite
onready var _particles: CPUParticles2D = $CPUParticles2D

func play(at_position: Vector2, main: Node, pool_id: int) -> void:
	_main = main
	_pool_id = pool_id
	_elapsed = 0.0
	global_position = at_position
	visible = true
	_sprite.rotation = 0.0
	_sprite.scale = Vector2.ONE * 0.8
	_sprite.modulate.a = 1.0
	_particles.emitting = true
	_particles.restart()

func _process(delta: float) -> void:
	_elapsed += delta
	var progress = clamp(_elapsed / _lifetime, 0.0, 1.0)

	_sprite.scale = Vector2.ONE * (0.8 + 1.2 * progress)
	_sprite.modulate.a = 1.0 - progress
	_sprite.rotation += 8.0 * delta

	if _elapsed >= _lifetime:
		visible = false
		_particles.emitting = false
		_main.add_node_to_pool(self, _pool_id)
