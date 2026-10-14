extends "res://projectiles/player_explosion.gd"

const DURATION: float = 0.78
const DAMAGE_DURATION: float = 0.06

onready var _ground: Node2D = $Ground
onready var _seal: Sprite = $Ground/Seal
onready var _wave: Sprite = $Ground/Shockwave
onready var _echo: Sprite = $Ground/EchoRing
onready var _bloom: Sprite = $Ground/Bloom
onready var _radiance: Sprite = $Ground/Radiance
onready var _sparks: CPUParticles2D = $Sparks
onready var _dust: CPUParticles2D = $Ground/Dust

var _elapsed: float = 0.0
var _damage_elapsed: float = 0.0
var _active: bool = false


func _ready() -> void:
	set_process(false)
	set_physics_process(false)


func start_explosion() -> void:
	var ground_parent: Node2D = Utils.get_scene_node().get_node("TileMap")
	var world_transform: Transform2D = global_transform
	get_parent().remove_child(self)
	ground_parent.add_child(self)
	global_transform = world_transform
	_elapsed = 0.0
	_damage_elapsed = 0.0
	_active = true
	_hitbox.from = self
	_hitbox.enable()
	_hitbox.player_attack_id = -1
	visible = true
	modulate = Color(1.0, 1.0, 1.0, ProgressData.settings.explosion_opacity)
	_ground.rotation = 0.0
	_seal.rotation = rand_range(-0.12, 0.12)
	_sparks.emitting = false
	_dust.emitting = false
	if ProgressData.settings.visual_effects:
		_sparks.restart()
		_sparks.emitting = true
		_dust.restart()
		_dust.emitting = true
	_update_visuals()
	set_process(true)
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	if not _active:
		return
	if not sound_played:
		._physics_process(delta)
		set_physics_process(true)
		return
	_damage_elapsed += delta
	if _damage_elapsed >= DAMAGE_DURATION:
		_hitbox.disable()
		set_physics_process(false)


func _process(delta: float) -> void:
	if not _active:
		return
	_elapsed += delta
	_update_visuals()
	_seal.rotation += delta * 0.09
	if _elapsed >= DURATION:
		_active = false
		_sparks.emitting = false
		_dust.emitting = false
		set_process(false)
		set_physics_process(false)
		end_explosion()


func _update_visuals() -> void:
	var p: float = clamp(_elapsed / DURATION, 0.0, 1.0)
	var reveal: float = min(1.0, _elapsed / 0.045)
	var fade: float = pow(1.0 - clamp((_elapsed - 0.18) / 0.60, 0.0, 1.0), 1.5)
	_seal.material.set_shader_param("progress", p)
	_seal.modulate.a = (0.45 + reveal * 0.55) * fade
	_seal.scale = Vector2.ONE * (0.82 + reveal * 0.06 + sin(p * PI) * 0.025)
	var wave_p: float = clamp(_elapsed / 0.26, 0.0, 1.0)
	_wave.scale = Vector2.ONE * lerp(0.45, 1.46, 1.0 - pow(1.0 - wave_p, 2.0))
	_wave.modulate.a = pow(1.0 - wave_p, 1.3) * 0.92
	var echo_p: float = clamp((_elapsed - 0.055) / 0.34, 0.0, 1.0)
	_echo.scale = Vector2.ONE * lerp(0.55, 1.62, 1.0 - pow(1.0 - echo_p, 2.0))
	_echo.modulate.a = sin(echo_p * PI) * (1.0 - echo_p) * 0.55
	_bloom.scale = Vector2.ONE * (1.25 + wave_p * 0.55)
	_bloom.modulate.a = pow(1.0 - p, 2.0) * (0.65 + reveal * 0.25)
	var light_p: float = clamp(_elapsed / 0.30, 0.0, 1.0)
	_radiance.scale = Vector2.ONE * (0.65 + light_p * 0.5)
	_radiance.rotation = _seal.rotation
	_radiance.modulate.a = pow(1.0 - light_p, 2.0) * 0.75
	_sprite.scale = Vector2(1.0, 0.75) * (0.65 + wave_p * 0.75)
	_sprite.modulate.a = pow(max(0.0, 1.0 - _elapsed / 0.19), 1.5)
