extends Node2D

const DURATION: float = 0.18

onready var _orb: Sprite = $Orb
onready var _glint: Sprite = $Glint
onready var _dust: CPUParticles2D = $Dust

var _elapsed: float = 0.0
var _active: bool = false
var _main: Node = null
var _pool_id: int = 0
var _opacity: float = 1.0


func _ready() -> void:
	set_as_toplevel(true)
	set_process(false)
	visible = false


func play_disappear(pos: Vector2, main: Node, pool_id: int) -> void:
	_main = main
	_pool_id = pool_id
	global_position = pos
	_elapsed = 0.0
	_active = true
	visible = true

	_opacity = FantasyProjectileVisualUtils.get_opacity()

	if is_instance_valid(_orb):
		_orb.visible = true
		_orb.scale = Vector2.ONE * 0.38
		_orb.modulate = Color(1.0, 0.95, 0.75, 0.85 * _opacity)

	if is_instance_valid(_glint):
		_glint.visible = true
		_glint.scale = Vector2.ONE * 0.15
		_glint.rotation = rand_range(0.0, PI * 0.5)
		_glint.modulate = Color(1.0, 0.98, 0.85, 0.9 * _opacity)

	if is_instance_valid(_dust):
		_dust.modulate.a = _opacity
		_dust.emitting = true
		_dust.restart()

	set_process(true)


func _process(delta: float) -> void:
	if not _active:
		return

	_elapsed += delta
	var progress = clamp(_elapsed / DURATION, 0.0, 1.0)

	if is_instance_valid(_orb):
		if progress < 0.35:
			var p = progress / 0.35
			_orb.scale = Vector2.ONE * (0.38 + 0.08 * sin(p * PI * 0.5))
			_orb.modulate.a = (0.85 - 0.15 * p) * _opacity
		else:
			var p = (progress - 0.35) / 0.65
			var ease_p = p * p
			_orb.scale = Vector2.ONE * (0.46 * (1.0 - ease_p))
			_orb.modulate.a = max(0.0, 0.70 * (1.0 - p)) * _opacity

	if is_instance_valid(_glint):
		_glint.rotation += delta * 4.0
		if progress < 0.3:
			var p = progress / 0.3
			_glint.scale = Vector2.ONE * (0.15 + 0.15 * sin(p * PI * 0.5))
			_glint.modulate.a = 0.9 * _opacity
		else:
			var p = (progress - 0.3) / 0.7
			_glint.scale = Vector2.ONE * (0.30 * (1.0 - p))
			_glint.modulate.a = max(0.0, 0.9 * (1.0 - p)) * _opacity

	if progress >= 1.0:
		_active = false
		set_process(false)
		_main.add_node_to_pool(self, _pool_id)
