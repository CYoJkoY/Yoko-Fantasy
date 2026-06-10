extends Node2D

const ShapeUtils = preload("res://mods-unpacked/Yoko-Fantasy/content/items/prism_tower/effects/prism_effect_shape_utils.gd")
const DURATION = 0.26

var PRISM_COLORS: Array = [
	Color("#ff4b4b"),
	Color("#ffd85a"),
	Color("#42f0c6"),
	Color("#58e6ff"),
	Color("#b66cff")
]

onready var _aura_ring: Line2D = $AuraRing
onready var _core_ring: Line2D = $CoreRing
onready var _prism: Line2D = $Prism
onready var _burst_a: Line2D = $Bursts/BurstA
onready var _burst_b: Line2D = $Bursts/BurstB
onready var _burst_c: Line2D = $Bursts/BurstC
onready var _burst_d: Line2D = $Bursts/BurstD
onready var _burst_e: Line2D = $Bursts/BurstE
onready var _soft_flash: Node2D = $SoftFlash
onready var _glow: Sprite = $SoftFlash/Glow
onready var _ring: Sprite = $SoftFlash/Ring
onready var _star: Sprite = $SoftFlash/Star
onready var _prism_dust: CPUParticles2D = $PrismDust
onready var _gold_dust: CPUParticles2D = $GoldDust
onready var _timer: Timer = $Timer

var _bursts: Array = []
var _duration: float = DURATION

func _ready() -> void:
	_bursts = [_burst_a, _burst_b, _burst_c, _burst_d, _burst_e]
	reset()

func reset() -> void:
	hide()
	set_process(false)
	set_as_toplevel(true)
	position = Vector2.ZERO
	modulate.a = 1.0
	_soft_flash.visible = false
	_prism_dust.emitting = false
	_gold_dust.emitting = false
	$Bursts.modulate.a = 1.0
	_aura_ring.visible = false
	_core_ring.visible = false
	_prism.visible = false
	$Bursts.visible = false
	ShapeUtils.set_circle_points(_aura_ring, 0.0, 12)
	ShapeUtils.set_circle_points(_core_ring, 0.0, 12)
	ShapeUtils.set_polygon_points(_prism, 0.0, 3)
	for burst in _bursts:
		ShapeUtils.set_line_points(burst, Vector2.ZERO, Vector2.ZERO)

func start_burst(pos: Vector2, radius: float) -> void:
	global_position = pos
	_build_burst(radius)
	_emit_particles(_prism_dust)
	_emit_particles(_gold_dust)
	_timer.wait_time = _duration
	_timer.start()
	show()
	set_process(true)

func _process(_delta: float) -> void:
	var progress: float = 1.0
	if _timer.time_left > 0.0:
		progress = 1.0 - (_timer.time_left / _duration)

	var fade: float = max(0.0, 1.0 - progress)
	_soft_flash.visible = true
	_soft_flash.scale = Vector2.ONE * (0.74 + progress * 1.12)
	_glow.modulate.a = fade * 0.62
	_ring.scale = Vector2.ONE * (0.72 + progress * 0.72)
	_ring.modulate.a = fade * 0.68
	_star.scale = Vector2.ONE * (0.64 + progress * 0.38)
	_star.rotation = progress * 0.75
	_star.modulate.a = max(0.0, 1.0 - progress * 1.5)

func _build_burst(radius: float) -> void:
	_soft_flash.visible = true
	_glow.scale = Vector2.ONE * max(0.85, radius / 20.0)
	_ring.scale = Vector2.ONE * max(0.58, radius / 36.0)
	_star.scale = Vector2.ONE * max(0.46, radius / 64.0)
	_prism_dust.emission_sphere_radius = max(12.0, radius * 0.48)
	_gold_dust.emission_sphere_radius = max(8.0, radius * 0.32)

	ShapeUtils.set_circle_points(_aura_ring, radius * 0.96, 32)
	_aura_ring.width = max(2.0, radius * 0.10)
	ShapeUtils.set_circle_points(_core_ring, radius * 0.42, 24)
	_core_ring.width = max(1.6, radius * 0.08)
	ShapeUtils.set_polygon_points(_prism, radius * 0.72, 3)
	_prism.width = max(1.8, radius * 0.08)

	for i in range(_bursts.size()):
		var angle: float = TAU * float(i) / float(_bursts.size()) + rand_range(-0.18, 0.18)
		var start: Vector2 = Vector2(cos(angle), sin(angle)) * radius * 0.28
		var end: Vector2 = Vector2(cos(angle), sin(angle)) * radius * rand_range(1.25, 1.72)
		var burst: Line2D = _bursts[i]
		ShapeUtils.set_line_points(burst, start, end)
		burst.width = max(1.4, radius * 0.08)
		burst.default_color = PRISM_COLORS[i % PRISM_COLORS.size()]

func _emit_particles(particles: CPUParticles2D) -> void:
	particles.emitting = false
	particles.emitting = true

func _on_Timer_timeout() -> void:
	Utils.get_scene_node().add_node_to_pool(self, get_meta("pool_id"))
	reset()
