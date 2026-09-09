extends Node2D

const DURATION: float = 0.16

onready var _flare: Sprite = $Flare
onready var _sparks: CPUParticles2D = $Sparks

var _elapsed: float = 0.0
var _active: bool = false
var _main: Node = null
var _pool_id: int = 0
var _opacity: float = 1.0


func _ready() -> void:
    set_as_toplevel(true)
    set_process(false)
    visible = false


func play_hit(pos: Vector2, main: Node, pool_id: int) -> void:
    _main = main
    _pool_id = pool_id
    _opacity = FantasyProjectileVisualUtils.get_opacity()
    global_position = pos
    _elapsed = 0.0
    _active = true
    visible = true

    if is_instance_valid(_flare):
        _flare.visible = true
        _flare.scale = Vector2.ZERO
        _flare.rotation = rand_range(0.0, PI * 0.5)
        _flare.modulate = Color(1.0, 0.96, 0.82, 0.8 * _opacity)

    if is_instance_valid(_sparks):
        _sparks.emitting = true
        _sparks.modulate.a = _opacity
        _sparks.restart()

    set_process(true)


func _process(delta: float) -> void:
    if not _active:
        return

    _elapsed += delta
    var progress = clamp(_elapsed / DURATION, 0.0, 1.0)

    if is_instance_valid(_flare):
        if progress < 0.3:
            var p = progress / 0.3
            var ease_out = 1.0 - pow(1.0 - p, 2.0)
            _flare.scale = Vector2.ONE * (0.32 * ease_out)
            _flare.modulate.a = 0.8 * _opacity
        else:
            var p = (progress - 0.3) / 0.7
            _flare.scale = Vector2.ONE * (0.32 * (1.0 - p * 0.4))
            _flare.modulate.a = max(0.0, 0.8 * (1.0 - p) * _opacity)
            _flare.rotation += delta * 3.0

    if progress >= 1.0:
        _active = false
        set_process(false)
        _main.add_node_to_pool(self, _pool_id)
