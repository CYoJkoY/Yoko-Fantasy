extends Node2D

const ShapeUtils = preload("res://mods-unpacked/Yoko-Fantasy/content/items/prism_tower/effects/prism_effect_shape_utils.gd")
const WARNING_TIME = 0.144
const DESCENT_TIME = 0.048
const STRIKE_TIME = 0.24
const FADE_TIME = 0.18
const TOTAL_TIME = WARNING_TIME + DESCENT_TIME + STRIKE_TIME + FADE_TIME
const LOCKED_TARGET_DAMAGE_EFFECT_SCALE = 0.30
const AREA_DAMAGE_EFFECT_SCALE = 0.40

onready var _seal_outer: Line2D = $Seal/Outer
onready var _seal_inner: Line2D = $Seal/Inner
onready var _seal_triangle_a: Line2D = $Seal/TriangleA
onready var _seal_triangle_b: Line2D = $Seal/TriangleB
onready var _seal_cross_a: Line2D = $Seal/CrossA
onready var _seal_cross_b: Line2D = $Seal/CrossB
onready var _seal_refraction_a: Line2D = $Seal/RefractionA
onready var _seal_refraction_b: Line2D = $Seal/RefractionB
onready var _sky_column: Line2D = $SkyColumn
onready var _aura_column: Line2D = $AuraColumn
onready var _inner_column: Line2D = $InnerColumn
onready var _core_column: Line2D = $CoreColumn
onready var _impact_ring: Line2D = $ImpactRing
onready var _afterglow_ring: Line2D = $AfterglowRing
onready var _shard_a: Line2D = $Shards/ShardA
onready var _shard_b: Line2D = $Shards/ShardB
onready var _shard_c: Line2D = $Shards/ShardC
onready var _shard_d: Line2D = $Shards/ShardD
onready var _shard_e: Line2D = $Shards/ShardE
onready var _judgement_edge_a: Line2D = $JudgementEdges/EdgeA
onready var _judgement_edge_b: Line2D = $JudgementEdges/EdgeB
onready var _soft_warning: Node2D = $SoftWarning
onready var _warning_glow: Sprite = $SoftWarning/Glow
onready var _warning_ring: Sprite = $SoftWarning/Ring
onready var _warning_star: Sprite = $SoftWarning/Star
onready var _soft_column: Node2D = $SoftColumn
onready var _outer_bloom: Sprite = $SoftColumn/OuterBloom
onready var _gold_bloom: Sprite = $SoftColumn/GoldBloom
onready var _core_bloom: Sprite = $SoftColumn/CoreBloom
onready var _light_curtain: Node2D = $LightCurtain
onready var _holy_rain_particles: CPUParticles2D = $HolyRainParticles
onready var _soft_impact: Node2D = $SoftImpact
onready var _ground_glow: Sprite = $SoftImpact/GroundGlow
onready var _soft_impact_ring: Sprite = $SoftImpact/ImpactRing
onready var _impact_star: Sprite = $SoftImpact/ImpactStar
onready var _falling_dust: CPUParticles2D = $FallingDust
onready var _impact_dust: CPUParticles2D = $ImpactDust
onready var _timer: Timer = $Timer

var _damage: int = 1
var _radius: float = 56.0
var _player_index: int = -1
var _tracking_key_hash: int = Keys.empty_hash
var _elapsed: float = 0.0
var _has_struck: bool = false
var _locked_target: Node = null
var _has_locked_target: bool = false
var _shards: Array = []
var _judgement_edges: Array = []
var _curtain_rays: Array = []
var _curtain_base_positions: Array = []
var _curtain_base_scales: Array = []
var _curtain_base_alphas: Array = []

func _ready() -> void:
	_shards = [_shard_a, _shard_b, _shard_c, _shard_d, _shard_e]
	_judgement_edges = [_judgement_edge_a, _judgement_edge_b]
	_curtain_rays = [
		$LightCurtain/RayA,
		$LightCurtain/RayB,
		$LightCurtain/RayC,
		$LightCurtain/RayD,
		$LightCurtain/RayE,
		$LightCurtain/RayF,
		$LightCurtain/RayG,
		$LightCurtain/RayH
	]
	reset()

func reset() -> void:
	hide()
	set_process(false)
	set_as_toplevel(true)
	position = Vector2.ZERO
	modulate.a = 1.0
	_elapsed = 0.0
	_has_struck = false
	_locked_target = null
	_has_locked_target = false
	$Seal.visible = true
	_sky_column.visible = false
	_aura_column.visible = false
	_inner_column.visible = false
	_core_column.visible = false
	_impact_ring.visible = false
	_afterglow_ring.visible = false
	$JudgementEdges.visible = false
	$JudgementEdges.modulate.a = 1.0
	_seal_refraction_a.modulate.a = 1.0
	_seal_refraction_b.modulate.a = 1.0
	for edge in _judgement_edges:
		edge.modulate.a = 1.0
		edge.scale = Vector2.ONE
	$Shards.visible = false
	_soft_warning.visible = false
	_soft_column.visible = false
	_light_curtain.visible = false
	_soft_impact.visible = false
	_holy_rain_particles.emitting = false
	_falling_dust.emitting = false
	_impact_dust.emitting = false

func start_column(
	target_pos: Vector2,
	damage: int,
	radius: float,
	player_index: int,
	tracking_key_hash: int,
	locked_target: Node = null,
	track_target: bool = false
) -> void:
	global_position = target_pos
	_damage = int(max(1, damage))
	_radius = radius
	_player_index = player_index
	_tracking_key_hash = tracking_key_hash
	_locked_target = locked_target
	_has_locked_target = track_target and _is_valid_enemy(locked_target)
	_build_seal(radius)
	_build_column(radius)
	_build_shards(radius)
	_build_judgement_edges(radius)
	_build_soft_light(radius)
	_timer.wait_time = TOTAL_TIME
	_timer.start()
	show()
	set_process(true)

func _process(delta: float) -> void:
	_elapsed += delta
	if _has_locked_target and _elapsed < WARNING_TIME + DESCENT_TIME and _is_valid_enemy(_locked_target):
		global_position = _locked_target.global_position
	if _elapsed < WARNING_TIME:
		_update_warning(_elapsed / WARNING_TIME)
	elif _elapsed < WARNING_TIME + DESCENT_TIME:
		_update_descent((_elapsed - WARNING_TIME) / DESCENT_TIME)
	elif _elapsed < WARNING_TIME + DESCENT_TIME + STRIKE_TIME:
		if !_has_struck:
			_strike()
		_update_strike((_elapsed - WARNING_TIME - DESCENT_TIME) / STRIKE_TIME)
	else:
		_update_fade((_elapsed - WARNING_TIME - DESCENT_TIME - STRIKE_TIME) / FADE_TIME)

func _update_warning(progress: float) -> void:
	var eased: float = sin(progress * PI * 0.5)
	if _has_locked_target:
		$Seal.visible = false
		_afterglow_ring.visible = false
		_soft_warning.visible = true
		_soft_warning.scale = Vector2.ONE * (1.14 - eased * 0.28)
		_soft_warning.rotation = eased * 0.24
		_warning_glow.modulate.a = 0.10 + eased * 0.22
		_warning_ring.modulate.a = 0.06 + eased * 0.18
		_warning_star.modulate.a = 0.0
		return

	$Seal.visible = true
	$Seal.scale = Vector2.ONE * (1.22 - eased * 0.34)
	$Seal.rotation = eased * 0.35
	$Seal.modulate.a = 0.35 + eased * 0.65
	_afterglow_ring.visible = true
	_afterglow_ring.scale = Vector2.ONE * (0.7 + eased * 0.35)
	_afterglow_ring.modulate.a = 0.2 + eased * 0.28
	_seal_refraction_a.modulate.a = eased * 0.80
	_seal_refraction_b.modulate.a = eased * 0.72

func _update_descent(progress: float) -> void:
	if _has_locked_target:
		$Seal.visible = false
		$JudgementEdges.visible = false
		_soft_warning.visible = true
		_soft_warning.scale = Vector2.ONE * (0.86 - progress * 0.12)
		_soft_warning.modulate.a = 1.0 - progress * 0.35
		_soft_column.visible = false
		_light_curtain.visible = true
		_update_light_curtain(progress, 1.0, -22.0 + progress * 22.0)
		if progress < 0.18 and !_holy_rain_particles.emitting:
			_emit_particles(_holy_rain_particles)
		return

	$Seal.visible = true
	$Seal.scale = Vector2.ONE * (0.88 - progress * 0.12)
	$Seal.modulate.a = 1.0
	_sky_column.visible = true
	_sky_column.modulate.a = progress
	_sky_column.scale.y = 0.2 + progress * 0.8
	$JudgementEdges.visible = true
	for i in range(_judgement_edges.size()):
		var edge: Line2D = _judgement_edges[i]
		edge.modulate.a = progress * (0.75 - float(i) * 0.14)
		edge.scale.y = 0.32 + progress * 0.68

func _strike() -> void:
	_has_struck = true
	if _has_locked_target and _is_valid_enemy(_locked_target):
		global_position = _locked_target.global_position
		_damage_locked_target()
	else:
		_damage_enemies()
	_sky_column.visible = false
	_aura_column.visible = true
	_inner_column.visible = true
	_core_column.visible = true
	_impact_ring.visible = true
	_afterglow_ring.visible = true
	if _has_locked_target:
		_sky_column.visible = false
		_aura_column.visible = false
		_inner_column.visible = false
		_core_column.visible = false
		_impact_ring.visible = false
		_afterglow_ring.visible = false
		$Seal.visible = false
		$JudgementEdges.visible = false
		$Shards.visible = false
		_soft_column.visible = false
		_light_curtain.visible = true
		_soft_impact.visible = true
		_emit_particles(_impact_dust)
	else:
		$JudgementEdges.visible = true
		$Shards.visible = true

func _update_strike(progress: float) -> void:
	var fade: float = 1.0 - progress
	if _has_locked_target:
		_soft_warning.visible = false
		_soft_column.visible = false
		_light_curtain.visible = true
		_update_light_curtain(progress, fade, progress * 16.0)
		_soft_impact.visible = true
		_ground_glow.scale = Vector2.ONE * (0.72 + progress * 1.18)
		_ground_glow.modulate.a = fade * 0.74
		_soft_impact_ring.scale = Vector2.ONE * (0.58 + progress * 1.12)
		_soft_impact_ring.modulate.a = fade * 0.72
		_impact_star.modulate.a = 0.0
		return

	$Seal.modulate.a = fade * 0.45
	_aura_column.modulate.a = fade * 0.85
	_inner_column.modulate.a = fade
	_core_column.modulate.a = max(0.0, 1.0 - progress * 1.4)
	_impact_ring.scale = Vector2.ONE * (0.55 + progress * 1.35)
	_impact_ring.modulate.a = fade
	_afterglow_ring.scale = Vector2.ONE * (0.85 + progress * 0.75)
	_afterglow_ring.modulate.a = 0.35 + fade * 0.25
	for edge in _judgement_edges:
		edge.modulate.a = fade * 0.58
		edge.scale.y = 1.0 + progress * 0.14
	$Shards.modulate.a = fade

func _update_fade(progress: float) -> void:
	var fade: float = max(0.0, 1.0 - progress)
	if _has_locked_target:
		_soft_warning.visible = false
		_soft_column.visible = false
		_light_curtain.visible = true
		_update_light_curtain(progress, fade * 0.20, 18.0 + progress * 10.0)
		_soft_impact.visible = true
		_ground_glow.scale = Vector2.ONE * (1.90 + progress * 0.30)
		_ground_glow.modulate.a = fade * 0.26
		_soft_impact_ring.visible = false
		_impact_star.visible = false
		return

	$Seal.visible = false
	_aura_column.modulate.a = fade * 0.20
	_inner_column.modulate.a = fade * 0.15
	_core_column.visible = false
	_impact_ring.visible = false
	$JudgementEdges.visible = false
	_afterglow_ring.scale = Vector2.ONE * (1.6 + progress * 0.4)
	_afterglow_ring.modulate.a = fade * 0.28
	$Shards.modulate.a = fade * 0.35

func _damage_enemies() -> void:
	var main: Main = Utils.get_scene_node()
	if main == null or main._entity_spawner == null:
		return

	var args: TakeDamageArgs = Utils.ncl_create_custom_damage_args(_player_index, Color("#fff2a8"))
	args.from = self
	args.base_effect_scale = AREA_DAMAGE_EFFECT_SCALE

	var enemies: Array = main._entity_spawner.get_all_enemies(false)
	for enemy in enemies:
		if !is_instance_valid(enemy) or !(enemy is Enemy) or enemy.dead:
			continue
		if enemy.global_position.distance_to(global_position) > _radius:
			continue

		var damage_taken: Array = enemy.take_damage(_damage, args)
		if _player_index >= 0 and _tracking_key_hash != Keys.empty_hash:
			RunData.add_tracked_value(_player_index, _tracking_key_hash, damage_taken[1])

func _damage_locked_target() -> void:
	var args: TakeDamageArgs = Utils.ncl_create_custom_damage_args(_player_index, Color("#fff2a8"))
	args.from = self
	args.base_effect_scale = LOCKED_TARGET_DAMAGE_EFFECT_SCALE

	var damage_taken: Array = _locked_target.take_damage(_damage, args)
	if _player_index >= 0 and _tracking_key_hash != Keys.empty_hash:
		RunData.add_tracked_value(_player_index, _tracking_key_hash, damage_taken[1])

func _is_valid_enemy(node: Node) -> bool:
	return is_instance_valid(node) and node is Enemy and !node.dead

func _build_seal(radius: float) -> void:
	ShapeUtils.set_circle_points(_seal_outer, radius, 36)
	_seal_outer.width = max(2.0, radius * 0.055)
	ShapeUtils.set_circle_points(_seal_inner, radius * 0.58, 30)
	_seal_inner.width = max(1.5, radius * 0.035)
	ShapeUtils.set_polygon_points(_seal_triangle_a, radius * 0.76, 3)
	_seal_triangle_a.width = max(1.4, radius * 0.035)
	ShapeUtils.set_polygon_points(_seal_triangle_b, radius * 0.76, 3, PI / 2.0)
	_seal_triangle_b.width = max(1.4, radius * 0.035)
	ShapeUtils.set_line_points(_seal_cross_a, Vector2(-radius * 0.82, 0), Vector2(radius * 0.82, 0))
	ShapeUtils.set_line_points(_seal_cross_b, Vector2(0, -radius * 0.82), Vector2(0, radius * 0.82))
	ShapeUtils.set_line_points(_seal_refraction_a, Vector2(-radius * 0.92, -radius * 0.28), Vector2(radius * 0.92, radius * 0.28))
	ShapeUtils.set_line_points(_seal_refraction_b, Vector2(-radius * 0.62, radius * 0.50), Vector2(radius * 0.62, -radius * 0.50))
	_seal_refraction_a.width = max(1.2, radius * 0.030)
	_seal_refraction_b.width = max(1.2, radius * 0.026)

func _build_column(radius: float) -> void:
	ShapeUtils.set_line_points(_sky_column, Vector2(0, -520), Vector2(0, 18))
	_sky_column.width = radius * 0.35
	ShapeUtils.set_line_points(_aura_column, Vector2(0, -440), Vector2(0, 36))
	_aura_column.width = radius * 1.58
	ShapeUtils.set_line_points(_inner_column, Vector2(0, -390), Vector2(0, 30))
	_inner_column.width = radius * 0.86
	ShapeUtils.set_line_points(_core_column, Vector2(0, -350), Vector2(0, 18))
	_core_column.width = radius * 0.28
	ShapeUtils.set_circle_points(_impact_ring, radius * 0.92, 36)
	_impact_ring.width = max(2.0, radius * 0.08)
	ShapeUtils.set_circle_points(_afterglow_ring, radius * 0.68, 36)
	_afterglow_ring.width = max(1.6, radius * 0.04)

func _build_shards(radius: float) -> void:
	for i in range(_shards.size()):
		var angle: float = TAU * float(i) / float(_shards.size()) + 0.18
		var start: Vector2 = Vector2(cos(angle), sin(angle)) * radius * 0.34
		var end: Vector2 = Vector2(cos(angle), sin(angle)) * radius * 1.25
		var shard: Line2D = _shards[i]
		ShapeUtils.set_line_points(shard, start, end)
		shard.width = max(1.0, radius * 0.045)

func _build_judgement_edges(radius: float) -> void:
	ShapeUtils.set_line_points(_judgement_edge_a, Vector2(-radius * 0.48, -540), Vector2(radius * 0.12, 24))
	_judgement_edge_a.width = max(1.4, radius * 0.035)
	ShapeUtils.set_line_points(_judgement_edge_b, Vector2(radius * 0.42, -500), Vector2(-radius * 0.10, 28))
	_judgement_edge_b.width = max(1.2, radius * 0.030)

func _build_soft_light(radius: float) -> void:
	_soft_warning.modulate.a = 1.0
	_warning_glow.scale = Vector2.ONE * max(1.1, radius / 23.0)
	_warning_ring.scale = Vector2.ONE * max(0.85, radius / 34.0)
	_warning_star.scale = Vector2.ONE * max(0.54, radius / 72.0)
	_warning_glow.modulate.a = 0.0
	_warning_ring.modulate.a = 0.0
	_warning_star.modulate.a = 0.0

	_soft_column.scale = Vector2.ONE
	_outer_bloom.scale = Vector2(max(0.82, radius / 26.0), 8.7)
	_gold_bloom.scale = Vector2(max(0.62, radius / 36.0), 8.0)
	_core_bloom.scale = Vector2(max(0.34, radius / 58.0), 7.2)
	_outer_bloom.modulate.a = 0.0
	_gold_bloom.modulate.a = 0.0
	_core_bloom.modulate.a = 0.0

	_soft_impact.scale = Vector2.ONE
	_ground_glow.scale = Vector2.ONE * max(1.1, radius / 20.0)
	_soft_impact_ring.scale = Vector2.ONE * max(0.78, radius / 36.0)
	_impact_star.scale = Vector2.ONE * max(0.56, radius / 62.0)
	_ground_glow.modulate.a = 0.0
	_soft_impact_ring.modulate.a = 0.0
	_impact_star.modulate.a = 0.0
	_soft_impact_ring.visible = true
	_impact_star.visible = true
	_core_bloom.visible = true

	_build_light_curtain(radius)
	_holy_rain_particles.position = Vector2(0, -250)
	_holy_rain_particles.emission_rect_extents = Vector2(max(20.0, radius * 0.60), 150)
	_falling_dust.position = Vector2(0, -210)
	_falling_dust.emission_rect_extents = Vector2(max(18.0, radius * 0.52), 220)
	_impact_dust.emission_sphere_radius = max(20.0, radius * 0.55)

func _build_light_curtain(radius: float) -> void:
	_curtain_base_positions = [
		Vector2(-radius * 0.34, -286),
		Vector2(-radius * 0.12, -250),
		Vector2(radius * 0.18, -272),
		Vector2(radius * 0.42, -232),
		Vector2(-radius * 0.48, -212),
		Vector2(radius * 0.02, -304),
		Vector2(radius * 0.30, -190),
		Vector2(-radius * 0.22, -176)
	]
	_curtain_base_scales = [
		Vector2(0.18, 3.4),
		Vector2(0.14, 4.7),
		Vector2(0.20, 3.0),
		Vector2(0.12, 2.6),
		Vector2(0.10, 2.2),
		Vector2(0.16, 5.2),
		Vector2(0.11, 1.8),
		Vector2(0.09, 1.6)
	]
	_curtain_base_alphas = [0.52, 0.72, 0.36, 0.42, 0.28, 0.86, 0.24, 0.20]
	for i in range(_curtain_rays.size()):
		var ray: Sprite = _curtain_rays[i]
		ray.position = _curtain_base_positions[i]
		ray.scale = _curtain_base_scales[i]
		ray.modulate.a = 0.0
		ray.visible = true

func _update_light_curtain(progress: float, alpha_mult: float, y_offset: float) -> void:
	for i in range(_curtain_rays.size()):
		var ray: Sprite = _curtain_rays[i]
		ray.position = _curtain_base_positions[i] + Vector2(0, y_offset * (0.85 + float(i % 3) * 0.14))
		ray.scale = _curtain_base_scales[i] * (0.82 + progress * 0.24)
		ray.modulate.a = _curtain_base_alphas[i] * alpha_mult

func _emit_particles(particles: CPUParticles2D) -> void:
	particles.emitting = false
	particles.emitting = true

func _on_Timer_timeout() -> void:
	Utils.get_scene_node().add_node_to_pool(self, get_meta("pool_id"))
	reset()
