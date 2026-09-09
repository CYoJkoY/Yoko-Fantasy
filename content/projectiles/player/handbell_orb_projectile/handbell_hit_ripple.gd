extends Node2D

var _lifetime: float = 0.24
var _elapsed: float = 0.0
var _main: Node = null
var _pool_id: int = 0
var _active: bool = false
var _opacity: float = 1.0

onready var _ring_sprite: Sprite = $Ring
onready var _flash_sprite: Sprite = $Flash
onready var _particles: CPUParticles2D = $Particles


func _ready() -> void:
    set_process(false)
    _elapsed = 0.0
    _ring_sprite.scale = Vector2.ONE * 0.2
    _ring_sprite.modulate.a = 1.0
    _flash_sprite.scale = Vector2.ONE * 0.4
    _flash_sprite.modulate.a = 1.0
    _particles.emitting = true
    _particles.restart()


func play(at_position: Vector2, main: Node, pool_id: int, respect_opacity: bool = true) -> void:
    _main = main
    _pool_id = pool_id
    _elapsed = 0.0
    _active = true
    _opacity = 1.0
    if respect_opacity:
        _opacity = FantasyProjectileVisualUtils.get_opacity()
    global_position = at_position
    visible = true
    _ring_sprite.scale = Vector2.ONE * 0.2
    _ring_sprite.modulate.a = _opacity
    _flash_sprite.scale = Vector2.ONE * 0.4
    _flash_sprite.modulate.a = _opacity
    _particles.modulate.a = _opacity
    _particles.emitting = true
    _particles.restart()
    set_process(true)


func _process(delta: float) -> void:
    if not _active:
        return
    _elapsed += delta
    var progress = clamp(_elapsed / _lifetime, 0.0, 1.0)
    var ease_out = 1.0 - pow(1.0 - progress, 2)

    _ring_sprite.scale = Vector2.ONE * (0.2 + 1.4 * ease_out)
    _ring_sprite.modulate.a = (1.0 - progress) * 0.95 * _opacity

    _flash_sprite.scale = Vector2.ONE * (0.4 + 0.6 * progress)
    _flash_sprite.modulate.a = (1.0 - progress) * 0.8 * _opacity

    if _elapsed >= _lifetime:
        visible = false
        _active = false
        set_process(false)
        _particles.emitting = false
        _main.add_node_to_pool(self, _pool_id)
