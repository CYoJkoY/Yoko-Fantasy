extends Node2D

const Palette = preload("res://mods-unpacked/Yoko-Fantasy/content/weapons/ranged/bloodstained_banner/vfx/blood_palette.gd")
const DURATION: float = 0.86

onready var _ground_layer: Node2D = $GroundLayer
onready var _seal: Sprite = $GroundLayer/Ground/Seal
onready var _glyphs: Sprite = $GroundLayer/Ground/Glyphs
onready var _sweep: Sprite = $GroundLayer/Ground/Sweep
onready var _pool: Sprite = $GroundLayer/Pool
onready var _rift: Sprite = $GroundLayer/Rift
onready var _shockwave: Sprite = $GroundLayer/Shockwave
onready var _plume: Sprite = $Plume
onready var _ribbons: Sprite = $Ribbons
onready var _spiral: Sprite = $Spiral
onready var _glint: Sprite = $Glint
onready var _bloom: Sprite = $Bloom
onready var _foot_flash: Sprite = $FootFlash
onready var _root_glow: Sprite = $RootGlow
onready var _embers: CPUParticles2D = $Embers
onready var _cinders: CPUParticles2D = $Cinders
onready var _tinted_sprites: Array = [_bloom, _foot_flash, _glint, _root_glow, _sweep, _pool, _shockwave]

var _cursed: bool = false
var _particle_colors: PoolColorArray
var _elapsed: float = 0.0
var _pool_id: int = -1
var _seal_angle: float = 0.0


func _ready() -> void:
    _particle_colors = _embers.color_ramp.colors
    _embers.color_ramp = _embers.color_ramp.duplicate()
    _cinders.color_ramp = _embers.color_ramp
    set_as_toplevel(true)
    visible = false
    set_process(false)


func set_pool_id(pool_id: int) -> void:
    _pool_id = pool_id


func set_cursed(cursed: bool) -> void:
    if _cursed == cursed:
        return
    _cursed = cursed
    for visual in [_seal, _plume, _ribbons, _spiral]:
        visual.material.set_shader_param("cursed", 1.0 if cursed else 0.0)
    Palette.set_gradient(_embers.color_ramp, _particle_colors, cursed)


func start_strike(target_pos: Vector2, _target_node: Node = null, scale_mult: float = 1.0, tint_color: Color = Color.white) -> void:
    _elapsed = 0.0
    global_position = target_pos
    scale = Vector2.ONE * scale_mult
    modulate = tint_color
    modulate.a = FantasyProjectileVisualUtils.get_opacity()
    _seal_angle = randf() * TAU
    _embers.restart()
    _embers.emitting = true
    _cinders.restart()
    _cinders.emitting = true
    _ground_layer.visible = true
    _update_visuals()
    visible = true
    set_process(true)
    var main = Utils.get_scene_node()
    if main != null:
        var floor_node: Node2D = main.get_node("TileMap")
        if _ground_layer.get_parent() != floor_node:
            _ground_layer.get_parent().remove_child(_ground_layer)
            floor_node.add_child(_ground_layer)
        _ground_layer.global_transform = global_transform
        _ground_layer.modulate = modulate
    if main != null and is_instance_valid(main._fog_viewport):
        main._fog_viewport._on_spawn_explosion(self)


func _exit_tree() -> void:
    if is_instance_valid(_ground_layer) and _ground_layer.get_parent() != self:
        _ground_layer.get_parent().remove_child(_ground_layer)
        add_child(_ground_layer)
        _ground_layer.transform = Transform2D.IDENTITY
        _ground_layer.modulate = Color.white


func _process(delta: float) -> void:
    _elapsed += delta
    if _elapsed >= DURATION:
        _finish()
        return
    _update_visuals()


func _update_visuals() -> void:
    var rise: float = clamp(_elapsed / 0.16, 0.0, 1.0)
    var rise_ease: float = sin(rise * PI * 0.5)
    var birth: float = smoothstep(0.0, 0.035, _elapsed)
    var fade: float = 1.0 - smoothstep(0.22, 0.67, _elapsed)
    var ground_fade: float = 1.0 - smoothstep(0.38, DURATION, _elapsed)
    _plume.material.set_shader_param("rise", 0.04 + 0.96 * rise_ease)
    _plume.material.set_shader_param("age", _elapsed)
    _plume.material.set_shader_param("strength", birth * fade)
    _plume.scale.x = 0.64 + 0.12 * sin(rise * PI) - 0.22 * (1.0 - fade)
    _ribbons.material.set_shader_param("rise", 0.04 + 0.96 * rise_ease)
    _ribbons.material.set_shader_param("age", _elapsed + 0.4)
    _ribbons.material.set_shader_param("strength", birth * fade * 0.78)
    _ribbons.scale.x = 0.82 + rise_ease * 0.12
    _spiral.material.set_shader_param("age", _elapsed)
    _spiral.material.set_shader_param("strength", birth * fade * 0.75)
    _bloom.modulate = Color(0.95, 0.018, 0.10, birth * fade * 0.30)
    _bloom.scale = Vector2(0.58, 1.20) * (0.65 + rise_ease * 0.35)
    var flash: float = birth * (1.0 - smoothstep(0.055, 0.22, _elapsed))
    _foot_flash.modulate = Color(1.0, 0.38, 0.31, flash * 0.68)
    _foot_flash.scale = Vector2(0.48, 0.32) * (0.8 + rise_ease * 0.7)
    _glint.modulate = Color(1.0, 0.57, 0.48, flash * 0.90)
    _glint.scale = Vector2(0.80, 0.52) * (0.65 + rise_ease * 0.55)
    _glint.rotation = -0.12 + _elapsed * 0.7
    _root_glow.scale = Vector2(0.62 + rise_ease * 0.18, 0.48 + rise_ease * 0.16)
    _root_glow.modulate = Color(1.0, 0.12, 0.23, birth * fade * (0.70 + flash * 0.22))
    var ground_spread: float = sin(clamp(_elapsed / 0.15, 0.0, 1.0) * PI * 0.5)
    _seal.scale = Vector2.ONE * (0.67 + ground_spread * 0.33)
    _seal.rotation = _seal_angle + _elapsed * 0.32
    _seal.material.set_shader_param("age", _elapsed)
    _seal.modulate = Color(1.0, 1.0, 1.0, ground_fade * 0.90)
    _glyphs.scale = Vector2.ONE * (0.80 + ground_spread * 0.20)
    _glyphs.rotation = _seal_angle - _elapsed * 0.78
    _glyphs.modulate = Color(1.0, 0.80, 0.95, ground_fade * 0.90)
    _sweep.scale = Vector2.ONE * (0.78 + ground_spread * 0.22)
    _sweep.rotation = _seal_angle + _elapsed * 2.4
    _sweep.modulate = Color(1.0, 0.48, 0.57, birth * ground_fade * 0.85)
    _pool.modulate = Color(0.38, 0.008, 0.045, birth * ground_fade * 0.65)
    _rift.modulate = Color(1.0, 0.85, 0.95, fade * 0.68)
    var ripple: float = clamp(_elapsed / 0.42, 0.0, 1.0)
    _shockwave.scale = Vector2(1.20, 1.02) * (0.40 + sin(ripple * PI * 0.5) * 0.80)
    _shockwave.modulate = Color(1.0, 0.12, 0.32, birth * pow(1.0 - ripple, 1.7) * 0.60)
    if _cursed:
        for visual in _tinted_sprites:
            visual.modulate = Palette.tint(visual.modulate, true)


func _finish() -> void:
    _ground_layer.visible = false
    visible = false
    set_process(false)
    _embers.emitting = false
    _cinders.emitting = false
    var main = Utils.get_scene_node()
    if is_instance_valid(main) and _pool_id >= 0:
        main.add_node_to_pool(self, _pool_id)
    else:
        queue_free()
