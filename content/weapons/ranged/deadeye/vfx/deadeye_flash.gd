extends Node2D

const MUZZLE_TEXTURE: Texture = preload("res://mods-unpacked/Yoko-Fantasy/content/weapons/ranged/deadeye/vfx/textures/muzzle.webp")
const IMPACT_TEXTURE: Texture = preload("res://mods-unpacked/Yoko-Fantasy/content/weapons/ranged/deadeye/vfx/textures/impact.webp")

onready var _flare: Sprite = $Flare
onready var _core: Sprite = $Core
onready var _upper_feather: Sprite = $UpperFeather
onready var _lower_feather: Sprite = $LowerFeather
onready var _sparks: CPUParticles2D = $Sparks

var _main: Node
var _elapsed: float = 0.0
var _duration: float = 0.0
var _enhanced: bool = false
var _muzzle: bool = false
var _base_scale: Vector2 = Vector2.ONE
var _flare_duration: float = 0.0


func _ready() -> void:
    set_process(false)


func play_flash(pos: Vector2, direction: float, muzzle: bool, enhanced: bool, main: Node, opacity: float) -> void:
    _main = main
    _elapsed = 0.0
    _muzzle = muzzle
    _enhanced = enhanced
    _duration = 0.20 if enhanced else 0.15
    _flare_duration = 0.12 if enhanced else 0.09
    global_position = pos
    rotation = direction
    scale = Vector2.ONE * (1.65 if enhanced else 1.5)
    visible = true
    modulate = Color(1.0, 1.0, 1.0, opacity)
    _flare.texture = MUZZLE_TEXTURE if muzzle else IMPACT_TEXTURE
    _flare.position.x = 13.0 if muzzle else 0.0
    _base_scale = Vector2(0.65, 0.65) if enhanced else Vector2(0.50, 0.40)
    _flare.scale = _base_scale * 0.7
    _flare.modulate = Color(1.0, 0.82, 0.38, 1.0) if enhanced else Color(1.0, 0.97, 0.84, 0.85)
    _core.texture = _flare.texture
    _core.position = _flare.position
    _core.scale = _base_scale * Vector2(0.8, 0.38)
    _core.modulate = Color(1.0, 0.99, 0.92, 1.0)
    _upper_feather.visible = muzzle and enhanced
    _lower_feather.visible = muzzle and enhanced
    _upper_feather.rotation = -0.40
    _lower_feather.rotation = 0.40
    _upper_feather.position = Vector2(1, -2)
    _lower_feather.position = Vector2(1, 2)
    _upper_feather.scale = Vector2.ONE * 0.48
    _lower_feather.scale = Vector2.ONE * 0.48
    _upper_feather.modulate.a = 0.85
    _lower_feather.modulate.a = 0.85
    _sparks.emitting = false
    _sparks.visible = not muzzle
    if not muzzle:
        _sparks.amount = 7 if enhanced else 4
        _sparks.color = Color(1.0, 0.80, 0.32, 1.0) if enhanced else Color(1.0, 0.96, 0.80, 0.8)
        _sparks.restart()
        _sparks.emitting = true
    set_process(true)


func _process(delta: float) -> void:
    _elapsed += delta
    var progress: float = min(_elapsed / _duration, 1.0)
    var flare_progress: float = min(_elapsed / _flare_duration, 1.0)
    var opening: float = 1.0 - pow(1.0 - min(_elapsed / 0.025, 1.0), 3.0)
    _flare.scale = _base_scale * Vector2(0.7 + 0.5 * opening, 1.0 - 0.4 * flare_progress)
    _flare.modulate.a = pow(1.0 - flare_progress, 1.5)
    _core.modulate.a = pow(1.0 - min(_elapsed / 0.055, 1.0), 2.0)
    if _muzzle and _enhanced:
        var spread: float = 1.0 - pow(1.0 - progress, 2.0)
        _upper_feather.rotation = -0.25 - spread * 0.42
        _lower_feather.rotation = 0.25 + spread * 0.42
        _upper_feather.position = Vector2(1.0 + spread * 6.0, -2.0 - spread * 3.0)
        _lower_feather.position = Vector2(1.0 + spread * 6.0, 2.0 + spread * 3.0)
        _upper_feather.scale = Vector2(0.48 + spread * 0.12, 0.48 * (1.0 - progress * 0.45))
        _lower_feather.scale = _upper_feather.scale
        _upper_feather.modulate.a = 0.85 * pow(1.0 - progress, 1.5)
        _lower_feather.modulate.a = _upper_feather.modulate.a
    if progress >= 1.0:
        _sparks.emitting = false
        visible = false
        set_process(false)
        _main.add_node_to_pool(self, get_meta("pool_id"))
