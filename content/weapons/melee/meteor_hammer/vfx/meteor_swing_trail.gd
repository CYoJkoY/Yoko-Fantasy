extends Node2D

const LIFETIME: float = 0.16
const SAMPLE_INTERVAL: float = 0.025
const MAX_IMAGES: int = 7

var _poses: Array = []
var _ages: Array = []
var _sample_cooldown: float = 0.0
var _texture: Texture
var _texture_rect: Rect2


func _ready() -> void:
    set_as_toplevel(true)
    global_transform = Transform2D.IDENTITY
    show_behind_parent = true
    visible = false


func clear_trail() -> void:
    _sample_cooldown = 0.0
    if _poses.empty():
        return
    _poses.clear()
    _ages.clear()
    visible = false
    update()


func advance(source: Sprite, emitting: bool, delta: float, opacity: float) -> void:
    if opacity <= 0.0:
        clear_trail()
        return
    if not emitting and _poses.empty():
        return
    for i in range(_ages.size()):
        _ages[i] += delta
    while not _ages.empty() and _ages[0] >= LIFETIME:
        _poses.pop_front()
        _ages.pop_front()
    _sample_cooldown = max(0.0, _sample_cooldown - delta)
    if emitting and _sample_cooldown <= 0.0:
        _texture = source.texture
        _texture_rect = source.get_rect()
        _poses.append(source.global_transform)
        _ages.append(0.0)
        if _poses.size() > MAX_IMAGES:
            _poses.pop_front()
            _ages.pop_front()
        _sample_cooldown = SAMPLE_INTERVAL
    elif not emitting:
        _sample_cooldown = 0.0
    modulate.a = 0.50 * opacity
    visible = not _poses.empty()
    if visible:
        update()


func _draw() -> void:
    for i in range(_poses.size()):
        var fade: float = 1.0 - _ages[i] / LIFETIME
        draw_set_transform_matrix(_poses[i])
        var alpha: float = fade * fade * (3.0 - 2.0 * fade)
        draw_texture_rect(_texture, _texture_rect, false, Color(1.35, 1.35, 1.35, alpha))
    draw_set_transform_matrix(Transform2D.IDENTITY)
