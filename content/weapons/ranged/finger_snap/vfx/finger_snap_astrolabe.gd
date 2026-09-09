extends Node2D

const TOTAL_DURATION: float = 0.34

onready var _aura_shock: Sprite = $AuraShock
onready var _direct_flare: Sprite = $DirectFlare
onready var _star_dust: CPUParticles2D = $StarDust

var _elapsed: float = 0.0
var _active: bool = false
var _flare_scale: float = 1.0
var _main: Node = null
var _pool_id: int = 0
var _opacity: float = 1.0


func _ready() -> void:
    set_as_toplevel(true)
    set_process(false)
    visible = false


func start_astrolabe(pos: Vector2, _target: Node, tier: int, main: Node, pool_id: int, tint: Color = Color(1.0, 0.95, 0.75, 1.0)) -> void:
    _main = main
    _pool_id = pool_id
    _opacity = FantasyProjectileVisualUtils.get_opacity()
    global_position = pos
    _elapsed = 0.0
    _active = true
    visible = true
    modulate = tint

    _flare_scale = 0.95 + float(tier) * 0.12

    if is_instance_valid(_aura_shock):
        _aura_shock.visible = true
        _aura_shock.scale = Vector2.ZERO
        _aura_shock.modulate.a = 0.8 * _opacity

    if is_instance_valid(_direct_flare):
        _direct_flare.visible = true
        _direct_flare.scale = Vector2.ZERO
        _direct_flare.rotation = rand_range(0.0, PI * 0.25)
        _direct_flare.modulate.a = _opacity

    if is_instance_valid(_star_dust):
        _star_dust.emitting = true
        _star_dust.modulate.a = _opacity
        _star_dust.restart()

    set_process(true)


func _process(delta: float) -> void:
    if not _active:
        return

    _elapsed += delta
    var progress: float = clamp(_elapsed / TOTAL_DURATION, 0.0, 1.0)

    if is_instance_valid(_direct_flare):
        if progress < 0.2:
            var p = progress / 0.2
            var ease_out = 1.0 - pow(1.0 - p, 2.5)
            _direct_flare.scale = Vector2.ONE * (ease_out * 1.35 * _flare_scale)
            _direct_flare.modulate.a = _opacity
        else:
            var p = (progress - 0.2) / 0.8
            _direct_flare.scale = Vector2.ONE * ((1.35 - p * 0.45) * _flare_scale)
            _direct_flare.modulate.a = max(0.0, (1.0 - p * 1.25) * _opacity)
            _direct_flare.rotation += delta * 0.8

    if is_instance_valid(_aura_shock):
        var ease_out = 1.0 - pow(1.0 - progress, 3.0)
        _aura_shock.scale = Vector2.ONE * (ease_out * 0.55 * _flare_scale)
        _aura_shock.modulate.a = max(0.0, (1.0 - progress) * 0.75 * _opacity)

    if progress >= 1.0:
        _active = false
        set_process(false)
        _main.add_node_to_pool(self, _pool_id)
