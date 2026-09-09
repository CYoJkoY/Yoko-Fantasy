extends Node2D

var _lifetime: float = 0.22
var _elapsed: float = 0.0
var _main: Node = null
var _pool_id: int = 0
var _active: bool = false
var _opacity: float = 1.0

onready var _sprite: Sprite = $Sprite


func _ready() -> void:
	set_process(false)
	_elapsed = 0.0
	_sprite.scale = Vector2.ONE * 0.25
	_sprite.modulate.a = 0.85


func play(at_position: Vector2, main: Node, pool_id: int) -> void:
	_main = main
	_pool_id = pool_id
	_elapsed = 0.0
	_active = true
	_opacity = FantasyProjectileVisualUtils.get_opacity()
	global_position = at_position
	visible = true
	_sprite.scale = Vector2.ONE * 0.25
	_sprite.modulate.a = 0.85 * _opacity
	set_process(true)


func _process(delta: float) -> void:
	if not _active:
		return
	_elapsed += delta
	var progress = clamp(_elapsed / _lifetime, 0.0, 1.0)
	var ease_out = 1.0 - pow(1.0 - progress, 2)

	_sprite.scale = Vector2.ONE * (0.25 + 0.75 * ease_out)
	_sprite.modulate.a = (1.0 - progress) * 0.85 * _opacity

	if _elapsed >= _lifetime:
		visible = false
		_active = false
		set_process(false)
		_main.add_node_to_pool(self, _pool_id)
