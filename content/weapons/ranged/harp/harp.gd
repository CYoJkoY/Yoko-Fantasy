extends "res://weapons/ranged/ranged_weapon.gd"

var harp_note_index: int = 0
var _pluck_time: float = 1.0
var _awaiting_reload: bool = false
var _ready_time: float = 1.0
var _ready_glint: Sprite

onready var _strings: Sprite = $Sprite/Strings


func _ready() -> void:
    _ready_glint = Sprite.new()
    _ready_glint.texture = preload("res://mods-unpacked/Yoko-Fantasy/content/weapons/ranged/harp/harp_ready.webp")
    _ready_glint.position = Vector2(21, -8)
    _ready_glint.visible = false
    sprite.add_child(_ready_glint)


func get_next_cooldown(at_wave_begin: bool = false) -> float:
    if is_big_reload_active(at_wave_begin):
        _awaiting_reload = true
    return .get_next_cooldown(at_wave_begin)


func should_shoot() -> bool:
    _check_reload_ready()
    return .should_shoot()


func _check_reload_ready() -> void:
    if _awaiting_reload and _current_cooldown <= 0.0 and not _is_shooting:
        _awaiting_reload = false
        _ready_time = 0.0
        _ready_glint.visible = true


func shoot() -> void:
    harp_note_index = _nb_shots_taken % 4
    _pluck_time = 0.0
    _strings.pluck(harp_note_index)
    .shoot()


func _process(delta: float) -> void:
    if _ready_glint.visible:
        _ready_time += delta
        var fade: float = max(0.0, 1.0 - _ready_time / 0.55)
        _ready_glint.modulate = Color(1.0, 0.94, 0.7, sin(min(_ready_time / 0.08, 1.0) * PI * 0.5) * fade)
        _ready_glint.scale = Vector2.ONE * (0.55 + _ready_time * 0.5)
        _ready_glint.position.y = 8.0 if sprite.flip_v else -8.0
        if fade <= 0.0:
            _ready_glint.visible = false
    if _pluck_time < 0.7:
        _pluck_time += delta
        var envelope: float = exp(-_pluck_time * 13.0)
        sprite.rotation = sin(_pluck_time * 23.0) * 0.055 * envelope if _pluck_time < 0.7 else 0.0
    _strings.flip_v = sprite.flip_v


func get_max_rand_cooldown(_cooldown_basis: int) -> float:
    return 0.0
