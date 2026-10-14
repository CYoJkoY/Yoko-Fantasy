extends "res://mods-unpacked/Yoko-Fantasy/content/weapons/ranged/shared/floating_spell_weapon.gd"

onready var _cast_particles: CPUParticles2D = $Sprite/CastParticles


func shoot() -> void:
	.shoot()
	_cast_particles.modulate.a = FantasyProjectileVisualUtils.get_opacity()
	_cast_particles.restart()
	_cast_particles.emitting = true


func _process(_delta: float) -> void:
	_cast_particles.position = muzzle.position
