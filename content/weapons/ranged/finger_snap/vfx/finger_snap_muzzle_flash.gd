extends Node2D

const DURATION: float = 0.28
const PEAK_SCALE: float = 0.78

onready var _flare: Sprite = $Flare

var _elapsed: float = 0.0
var _active: bool = false
var _spin_speed: float = 4.0
var _main: Node = null
var _pool_id: int = 0
var _opacity: float = 1.0


func _ready() -> void:
	set_as_toplevel(true)
	set_process(false)
	visible = false


func play_flash(pos: Vector2, rot: float, main: Node, pool_id: int) -> void:
	_main = main
	_pool_id = pool_id
	_opacity = FantasyProjectileVisualUtils.get_opacity()
	global_position = pos
	rotation = rot
	_elapsed = 0.0
	_active = true
	visible = true
	_spin_speed = rand_range(3.5, 5.5) * (1.0 if randf() > 0.5 else -1.0)

	if is_instance_valid(_flare):
		_flare.visible = true
		_flare.scale = Vector2.ONE * 0.1
		_flare.modulate = Color(1.0, 0.96, 0.80, 0.75 * _opacity)
		_flare.rotation = rand_range(0.0, PI * 0.5)

	set_process(true)


func _process(delta: float) -> void:
	if not _active:
		return

	_elapsed += delta
	var progress = clamp(_elapsed / DURATION, 0.0, 1.0)

	if is_instance_valid(_flare):
		_flare.rotation += delta * _spin_speed

		if progress < 0.22:
			var p = progress / 0.22
			var ease_out = 1.0 - pow(1.0 - p, 3.0)
			_flare.scale = Vector2.ONE * (PEAK_SCALE * (0.1 + 0.95 * ease_out))
			_flare.modulate.a = 0.75 * p * _opacity
		elif progress < 0.45:
			var p = (progress - 0.22) / 0.23
			var settle = sin(p * PI) * 0.08
			_flare.scale = Vector2.ONE * (PEAK_SCALE * (1.05 - p * 0.08 + settle))
			_flare.modulate.a = 0.75 * _opacity
		else:
			var p = (progress - 0.45) / 0.55
			var ease_p = p * p
			_flare.scale = Vector2.ONE * (PEAK_SCALE * (0.97 - ease_p * 0.35))
			_flare.modulate.a = max(0.0, 0.75 * (1.0 - p) * _opacity)

	if progress >= 1.0:
		_active = false
		set_process(false)
		_main.add_node_to_pool(self, _pool_id)
