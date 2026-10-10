extends "res://projectiles/player_explosion.gd"

const LIFETIME: float = 0.36
const DAMAGE_DURATION: float = 0.06
const BASE_RADIUS: float = 147.34
const DAMAGE_NUMBER_COLOR: Color = Color("f5e6be")

onready var _ring: Sprite = $Ring
onready var _echo_ring: Sprite = $EchoRing
onready var _halo: Sprite = $Halo
onready var _flash: Sprite = $Flash

var _elapsed: float = 0.0
var _damage_elapsed: float = 0.0
var _active: bool = false
var _opacity: float = 1.0
var _visual_rotation: float = 0.0


func _ready() -> void:
	set_process(false)
	set_physics_process(false)
	visible = false


func start_explosion() -> void:
	_elapsed = 0.0
	_damage_elapsed = 0.0
	_active = true
	_opacity = ProgressData.settings.explosion_opacity if ProgressData.settings.visual_effects else 0.0
	visible = _opacity > 0.0
	if visible:
		_visual_rotation = rand_range(-PI, PI)
		_ring.material.set_shader_param("arc_phase", _visual_rotation)
		_echo_ring.material.set_shader_param("arc_phase", _visual_rotation + 2.1)
	_hitbox.from = self
	_hitbox.player_attack_id = -1
	_hitbox.enable()
	_explosion_smoke.emitting = false
	sound_played = true
	if visible:
		_update_visuals()
	set_process(true)
	set_physics_process(true)


func set_tint(tint: Color) -> void:
	if visible:
		_ring.material.set_shader_param("tint_color", tint)
	_hitbox.set_meta("fantasy_damage_color", DAMAGE_NUMBER_COLOR)


func _physics_process(delta: float) -> void:
	if not _active:
		return
	_damage_elapsed += delta
	if _damage_elapsed >= DAMAGE_DURATION:
		_hitbox.disable()
		set_physics_process(false)


func _process(delta: float) -> void:
	if not _active:
		return
	_elapsed += delta
	if visible:
		_update_visuals()
	if _elapsed >= LIFETIME and _damage_elapsed >= DAMAGE_DURATION:
		_active = false
		visible = false
		set_process(false)
		set_physics_process(false)
		end_explosion()


func _update_visuals() -> void:
	var progress: float = clamp(_elapsed / LIFETIME, 0.0, 1.0)
	var travel: float = 0.64 * (1.0 - exp(-6.0 * progress)) + 0.46 * progress
	_ring.scale = Vector2.ONE * (BASE_RADIUS / 106.0) * (0.22 + travel)
	_ring.rotation = _visual_rotation + 0.08 * progress
	_ring.modulate.a = _opacity * pow(1.0 - progress, 0.7)
	_ring.material.set_shader_param("progress", progress)
	var echo_time: float = max(0.0, _elapsed - 0.035)
	var echo_progress: float = clamp(echo_time / (LIFETIME - 0.035), 0.0, 1.0)
	var echo_travel: float = 0.5 * (1.0 - exp(-5.0 * echo_progress)) + 0.4 * echo_progress
	_echo_ring.scale = Vector2.ONE * (BASE_RADIUS / 106.0) * (0.18 + echo_travel)
	_echo_ring.rotation = _visual_rotation + 0.65 - 0.06 * echo_progress
	_echo_ring.modulate.a = _opacity * 0.42 * smoothstep(0.0, 0.018, echo_time) * pow(1.0 - echo_progress, 1.1)
	_echo_ring.material.set_shader_param("progress", echo_progress)
	_halo.scale = Vector2.ONE * (BASE_RADIUS / 82.0) * (0.22 + 0.95 * travel)
	_halo.modulate.a = _opacity * 0.42 * pow(1.0 - progress, 3.0)
	var strike: float = clamp(_elapsed / 0.16, 0.0, 1.0)
	var flash_travel: float = 1.5 * (1.0 - exp(-4.0 * strike)) + 0.45 * strike
	_flash.scale = Vector2(1.06, 0.94) * (0.7 + flash_travel)
	_flash.rotation = _visual_rotation * 0.1 + 0.08 * strike
	_flash.modulate.a = _opacity * (1.0 - smoothstep(0.015, 0.16, _elapsed))
