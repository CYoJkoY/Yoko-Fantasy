extends "res://weapons/ranged/ranged_weapon.gd"

var _time: float = 0.0

onready var _cast_particles: CPUParticles2D = $Sprite/CastParticles


func shoot() -> void:
	.shoot()
	_cast_particles.modulate.a = FantasyProjectileVisualUtils.get_opacity()
	_cast_particles.restart()
	_cast_particles.emitting = true


func _process(delta: float) -> void:
	_time += delta
	sprite.offset.y = sin(_time * 4.0) * 2.5
	sprite.rotation = sin(_time * 2.5) * 0.04
