extends Node2D

const ShapeUtils = preload("res://mods-unpacked/Yoko-Fantasy/content/items/prism_tower/effects/prism_effect_shape_utils.gd")

var PRISM_COLORS: Array = [
	Color("#ff4b4b"),
	Color("#ffd447"),
	Color("#44f0c8"),
	Color("#55a7ff"),
	Color("#b96cff")
]

onready var _aura_line: Line2D = $AuraLine
onready var _main_line: Line2D = $MainLine
onready var _core_line: Line2D = $CoreLine
onready var _ray_a: Line2D = $RayA
onready var _ray_b: Line2D = $RayB
onready var _ray_c: Line2D = $RayC
onready var _ray_d: Line2D = $RayD
onready var _hit_flash: Node2D = $HitFlash
onready var _flash_outer: Line2D = $HitFlash/OuterRing
onready var _flash_inner: Line2D = $HitFlash/InnerPrism
onready var _flash_burst_a: Line2D = $HitFlash/BurstA
onready var _flash_burst_b: Line2D = $HitFlash/BurstB
onready var _flash_burst_c: Line2D = $HitFlash/BurstC
onready var _flash_burst_d: Line2D = $HitFlash/BurstD
onready var _timer: Timer = $Timer

var _duration: float = 0.18
var _ray_lines: Array = []
var _flash_bursts: Array = []

func _ready() -> void:
	_ray_lines = [_ray_a, _ray_b, _ray_c, _ray_d]
	_flash_bursts = [_flash_burst_a, _flash_burst_b, _flash_burst_c, _flash_burst_d]
	reset()

func reset() -> void:
	hide()
	set_process(false)
	set_as_toplevel(true)
	position = Vector2.ZERO
	modulate.a = 1.0
	ShapeUtils.set_line_points(_aura_line, Vector2.ZERO, Vector2.ZERO)
	ShapeUtils.set_line_points(_main_line, Vector2.ZERO, Vector2.ZERO)
	ShapeUtils.set_line_points(_core_line, Vector2.ZERO, Vector2.ZERO)
	for ray in _ray_lines:
		ShapeUtils.set_line_points(ray, Vector2.ZERO, Vector2.ZERO)
		ray.visible = false
	_hit_flash.position = Vector2.ZERO
	_hit_flash.scale = Vector2.ONE
	_hit_flash.rotation = 0.0
	_hit_flash.visible = false

func show_beam(
	from_pos: Vector2,
	to_pos: Vector2,
	width: float,
	line_color: Color,
	glow_color: Color,
	duration: float,
	with_flash: bool
) -> void:
	_duration = duration
	var direction: Vector2 = (to_pos - from_pos).normalized()
	var perpendicular: Vector2 = Vector2(-direction.y, direction.x)
	var length: float = from_pos.distance_to(to_pos)
	var ray_width: float = max(1.0, width * 0.26)

	ShapeUtils.set_line_points(_aura_line, from_pos, to_pos)
	_aura_line.width = width * 4.8
	_aura_line.default_color = glow_color
	ShapeUtils.set_line_points(_main_line, from_pos, to_pos)
	_main_line.width = width
	_main_line.default_color = line_color
	ShapeUtils.set_line_points(_core_line, from_pos, to_pos)
	_core_line.width = max(1.0, width * 0.26)

	for i in range(_ray_lines.size()):
		var offset: float = (-1.5 + float(i)) * width * 0.42
		var start_bias: float = length * (0.10 + float(i % 2) * 0.08)
		var end_bias: float = length * (0.08 + float((i + 1) % 2) * 0.06)
		var ray_from: Vector2 = from_pos + direction * start_bias + perpendicular * offset
		var ray_to: Vector2 = to_pos - direction * end_bias - perpendicular * offset * 0.45
		var ray: Line2D = _ray_lines[i]
		ShapeUtils.set_line_points(ray, ray_from, ray_to)
		ray.width = ray_width
		ray.default_color = PRISM_COLORS[i % PRISM_COLORS.size()]
		ray.visible = true

	_hit_flash.position = to_pos
	_hit_flash.visible = with_flash
	if with_flash:
		_hit_flash.rotation = rand_range(0.0, TAU)
		_build_hit_flash(max(10.0, width * 2.1))

	_timer.wait_time = duration
	_timer.start()
	show()
	set_process(true)

func _process(_delta: float) -> void:
	var progress: float = 1.0
	if _timer.time_left > 0.0:
		progress = 1.0 - (_timer.time_left / _duration)
		modulate.a = pow(1.0 - progress, 0.72)
	else:
		modulate.a = 0.0

	_aura_line.width = max(1.0, _aura_line.width * (0.96 + 0.03 * (1.0 - progress)))
	if _hit_flash.visible:
		_hit_flash.scale = Vector2.ONE * (0.72 + progress * 0.95)
		_hit_flash.modulate.a = max(0.0, 1.0 - progress)

func _build_hit_flash(radius: float) -> void:
	ShapeUtils.set_circle_points(_flash_outer, radius, 18)
	_flash_outer.width = max(1.5, radius * 0.12)
	ShapeUtils.set_polygon_points(_flash_inner, radius * 0.76, 3)
	_flash_inner.width = max(1.4, radius * 0.10)

	for i in range(_flash_bursts.size()):
		var angle: float = TAU * float(i) / float(_flash_bursts.size()) + rand_range(-0.16, 0.16)
		var start: Vector2 = Vector2(cos(angle), sin(angle)) * radius * 0.55
		var end: Vector2 = Vector2(cos(angle), sin(angle)) * radius * rand_range(1.15, 1.65)
		var burst: Line2D = _flash_bursts[i]
		ShapeUtils.set_line_points(burst, start, end)
		burst.width = max(1.0, radius * 0.08)
		burst.default_color = PRISM_COLORS[i % PRISM_COLORS.size()]

func _on_Timer_timeout() -> void:
	Utils.get_scene_node().add_node_to_pool(self, get_meta("pool_id"))
	reset()
