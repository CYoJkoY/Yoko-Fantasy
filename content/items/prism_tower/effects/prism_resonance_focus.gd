extends Node2D

const ShapeUtils = preload("res://mods-unpacked/Yoko-Fantasy/content/items/prism_tower/effects/prism_effect_shape_utils.gd")

onready var _line_a: Line2D = $LineA
onready var _line_b: Line2D = $LineB
onready var _line_c: Line2D = $LineC
onready var _line_d: Line2D = $LineD
onready var _line_e: Line2D = $LineE
onready var _line_f: Line2D = $LineF
onready var _soft_focus: Node2D = $SoftFocus
onready var _soft_glow: Sprite = $SoftFocus/Glow
onready var _soft_ring: Sprite = $SoftFocus/Ring
onready var _soft_star: Sprite = $SoftFocus/Star
onready var _focus_dust: CPUParticles2D = $FocusDust
onready var _timer: Timer = $Timer

var _duration: float = 0.30
var _lines: Array = []

func _ready() -> void:
	_lines = [_line_a, _line_b, _line_c, _line_d, _line_e, _line_f]
	reset()

func reset() -> void:
	hide()
	set_process(false)
	set_as_toplevel(true)
	position = Vector2.ZERO
	modulate.a = 1.0
	for line in _lines:
		line.visible = false
		ShapeUtils.set_line_points(line, Vector2.ZERO, Vector2.ZERO)
	_soft_focus.visible = false
	_focus_dust.emitting = false

func start_focus(tower_positions: Array, focus_pos: Vector2, duration: float) -> void:
	_duration = duration
	var count: int = int(min(tower_positions.size(), _lines.size()))
	for i in range(count):
		var line: Line2D = _lines[i]
		ShapeUtils.set_line_points(line, tower_positions[i], focus_pos)
		line.width = 1.3 + float(i % 2) * 0.4
		line.modulate.a = 0.45
		line.visible = true

	_soft_focus.position = focus_pos
	_soft_focus.visible = true
	_build_focus(24.0 + float(count) * 3.0)
	_emit_particles(_focus_dust)
	_timer.wait_time = duration
	_timer.start()
	show()
	set_process(true)

func _process(_delta: float) -> void:
	var progress: float = 1.0 - (_timer.time_left / _duration)
	var fade: float = max(0.0, 1.0 - progress)
	modulate.a = fade
	_soft_focus.scale = Vector2.ONE * (0.72 + progress * 0.58)
	_soft_focus.rotation = progress * 0.42
	_soft_glow.modulate.a = fade * 0.52
	_soft_ring.modulate.a = fade * 0.50
	_soft_star.modulate.a = max(0.0, 1.0 - progress * 1.25)

func _build_focus(radius: float) -> void:
	_soft_glow.scale = Vector2.ONE * max(0.8, radius / 22.0)
	_soft_ring.scale = Vector2.ONE * max(0.48, radius / 42.0)
	_soft_star.scale = Vector2.ONE * max(0.38, radius / 68.0)
	_focus_dust.global_position = $SoftFocus.global_position
	_focus_dust.emission_sphere_radius = max(10.0, radius * 0.45)

func _emit_particles(particles: CPUParticles2D) -> void:
	particles.emitting = false
	particles.emitting = true

func _on_Timer_timeout() -> void:
	Utils.get_scene_node().add_node_to_pool(self, get_meta("pool_id"))
	reset()
