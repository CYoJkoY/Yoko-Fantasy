extends Node2D

const TOTAL_DURATION: float = 0.42
const SUMMON_TIME: float = 0.05
const STRIKE_TIME: float = 0.18
const FADE_TIME: float = 0.19

onready var _ground_seal: Sprite = $GroundSeal
onready var _ground_bloom: Sprite = $GroundBloom
onready var _shockwave: Sprite = $Shockwave
onready var _impact_flare: Sprite = $ImpactFlare
onready var _pillar: Node2D = $Pillar
onready var _ray_left: Sprite = $Pillar/RayLeft
onready var _ray_right: Sprite = $Pillar/RayRight
onready var _holy_dust: CPUParticles2D = $HolyDust
onready var _falling_sparks: CPUParticles2D = $FallingSparks

var _elapsed: float = 0.0
var _active: bool = false
var _pool_id: int = -1
var _base_seal_scale: float = 0.50


func _ready() -> void:
	reset()


func reset() -> void:
	visible = false
	set_process(false)
	set_as_toplevel(true)
	_active = false
	_elapsed = 0.0
	modulate = Color.white
	modulate.a = 1.0

	if _ground_seal != null:
		_ground_seal.visible = false
		_ground_seal.scale = Vector2.ZERO
		_ground_seal.rotation = 0.0
		_ground_seal.modulate.a = 0.75

	if _ground_bloom != null:
		_ground_bloom.visible = false
		_ground_bloom.modulate.a = 0.0

	if _shockwave != null:
		_shockwave.visible = false
		_shockwave.scale = Vector2.ZERO
		_shockwave.modulate.a = 0.0

	if _impact_flare != null:
		_impact_flare.visible = false
		_impact_flare.scale = Vector2.ZERO
		_impact_flare.modulate.a = 0.0

	if _pillar != null:
		_pillar.visible = false
		_pillar.scale = Vector2(1.0, 0.0)
		_pillar.modulate.a = 0.85

	if _holy_dust != null:
		_holy_dust.emitting = false

	if _falling_sparks != null:
		_falling_sparks.emitting = false


func set_pool_id(pool_id: int) -> void:
	_pool_id = pool_id


func start_strike(target_pos: Vector2, _target_node: Node = null, scale_mult: float = 1.0, tint_color: Color = Color.white) -> void:
	reset()
	global_position = target_pos
	_base_seal_scale = 0.50 * max(0.8, scale_mult)
	_active = true
	_elapsed = 0.0
	modulate = tint_color
	modulate.a = FantasyProjectileVisualUtils.get_opacity()

	_ground_seal.visible = true
	_ground_seal.scale = Vector2.ONE * (_base_seal_scale * 0.3)
	_ground_seal.modulate.a = 0.5
	_ground_seal.rotation = rand_range(0.0, TAU)

	_ground_bloom.visible = true
	_ground_bloom.scale = Vector2.ONE * (1.0 * scale_mult)
	_ground_bloom.modulate.a = 0.3

	visible = true
	set_process(true)
	var main = Utils.get_scene_node()
	if main != null and is_instance_valid(main._fog_viewport):
		main._fog_viewport._on_spawn_explosion(self)


func _process(delta: float) -> void:
	if not _active:
		return

	_elapsed += delta

	if _elapsed < SUMMON_TIME:
		_process_summon(_elapsed / SUMMON_TIME)
	elif _elapsed < (SUMMON_TIME + STRIKE_TIME):
		_process_strike((_elapsed - SUMMON_TIME) / STRIKE_TIME)
	elif _elapsed < TOTAL_DURATION:
		_process_fade((_elapsed - SUMMON_TIME - STRIKE_TIME) / FADE_TIME)
	else:
		_finish()


func _process_summon(progress: float) -> void:
	var ease_p: float = sin(progress * PI * 0.5)
	_ground_seal.scale = Vector2.ONE * (_base_seal_scale * (0.3 + ease_p * 0.7))
	_ground_seal.rotation += ease_p * 0.15
	_ground_seal.modulate.a = 0.45 + ease_p * 0.30
	_ground_bloom.modulate.a = 0.25 + ease_p * 0.20


func _process_strike(progress: float) -> void:
	if not _pillar.visible:
		_pillar.visible = true
		_impact_flare.visible = true
		_shockwave.visible = true
		_holy_dust.emitting = true
		_holy_dust.restart()
		_falling_sparks.emitting = true
		_falling_sparks.restart()

	var strike_p: float = sin(progress * PI * 0.5)
	_pillar.scale.y = min(1.0, 0.4 + strike_p * 0.6)
	_pillar.scale.x = 1.0 + (1.0 - progress) * 0.25
	_pillar.modulate.a = 0.85

	_ground_seal.rotation += 0.03
	_ground_seal.scale = Vector2.ONE * (_base_seal_scale * (1.0 + sin(progress * PI) * 0.08))
	_ground_seal.modulate.a = 0.75

	if progress < 0.35:
		var flare_in = progress / 0.35
		_impact_flare.scale = Vector2.ONE * (0.35 + flare_in * 0.65)
		_impact_flare.modulate.a = 0.65 * flare_in
		_impact_flare.rotation = flare_in * 0.3
	else:
		var flare_out = (progress - 0.35) / 0.65
		_impact_flare.scale = Vector2.ONE * (1.0 + flare_out * 0.15)
		_impact_flare.modulate.a = 0.65 * (1.0 - flare_out)
		_impact_flare.rotation += 0.015

	_shockwave.scale = Vector2.ONE * (0.2 + strike_p * 0.85)
	_shockwave.modulate.a = max(0.0, 0.60 - progress * 0.8)

	_ray_left.position.y = -250.0 + sin(progress * 15.0) * 10.0
	_ray_right.position.y = -250.0 - sin(progress * 15.0) * 10.0


func _process_fade(progress: float) -> void:
	var fade: float = 1.0 - progress

	_pillar.scale.x = max(0.0, 1.0 - progress * 0.85)
	_pillar.modulate.a = 0.85 * fade * fade

	_ground_seal.modulate.a = fade * 0.55
	_ground_seal.rotation += 0.012
	_ground_bloom.modulate.a = fade * 0.20
	_shockwave.visible = false
	_impact_flare.visible = false


func _finish() -> void:
	_active = false
	set_process(false)
	visible = false
	if _holy_dust != null:
		_holy_dust.emitting = false
	if _falling_sparks != null:
		_falling_sparks.emitting = false

	var main = Utils.get_scene_node()
	if main != null and is_instance_valid(main) and _pool_id >= 0:
		main.add_node_to_pool(self, _pool_id)
	else:
		queue_free()
