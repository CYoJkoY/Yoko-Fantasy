extends Node2D

const SlashSparkVisual = preload("res://mods-unpacked/Yoko-Fantasy/content/entities/pets/flying_blade/visuals/slash_spark_visual.gd")
const SlashHitFlashVisual = preload("res://mods-unpacked/Yoko-Fantasy/content/entities/pets/flying_blade/visuals/slash_hit_flash_visual.gd")

const FRAGMENT_POOL_SIZE = 32
const AFTERIMAGE_POOL_SIZE = 24
const HIT_FLASH_POOL_SIZE = 24

var _fragments: Array = []
var _afterimages: Array = []
var _afterimage_ages: Array = []
var _afterimage_lifetimes: Array = []
var _afterimage_colors: Array = []
var _hit_flashes: Array = []
var _fragment_cursor: int = 0
var _afterimage_cursor: int = 0
var _hit_flash_cursor: int = 0

func ensure_capacity(sword_count: int) -> void:
    var count: int = sword_count
    if count < 1:
        count = 1
    var fragment_count: int = int(clamp(count * 2, 4, FRAGMENT_POOL_SIZE))
    var afterimage_count: int = int(clamp(count * 2, 2, AFTERIMAGE_POOL_SIZE))
    var hit_flash_count: int = int(clamp(count, 4, HIT_FLASH_POOL_SIZE))
    while _fragments.size() < fragment_count:
        _create_fragment()
    while _afterimages.size() < afterimage_count:
        _create_afterimage()
    while _hit_flashes.size() < hit_flash_count:
        _create_hit_flash()

func emit_fragment(position: Vector2, direction: Vector2, color: Color, lifetime: float, length: float, width: float, velocity: Vector2, angular_velocity: float, z: int) -> void:
    var fragment = _acquire_fragment()
    fragment.z_index = z
    fragment.ignite(position, direction, color, lifetime, length, width, velocity, angular_velocity)

func emit_afterimage(texture: Texture, centered: bool, offset: Vector2, flip_h: bool, flip_v: bool, position: Vector2, rotation: float, scale: Vector2, color: Color, lifetime: float, z: int) -> void:
    var index: int = _acquire_afterimage()
    var afterimage: Sprite = _afterimages[index]
    _afterimage_ages[index] = 0.0
    _afterimage_lifetimes[index] = max(0.01, lifetime)
    _afterimage_colors[index] = color
    afterimage.texture = texture
    afterimage.centered = centered
    afterimage.offset = offset
    afterimage.flip_h = flip_h
    afterimage.flip_v = flip_v
    afterimage.global_position = position
    afterimage.global_rotation = rotation
    afterimage.scale = scale
    afterimage.modulate = color
    afterimage.z_index = z
    afterimage.visible = true

func emit_hit_flash(position: Vector2, direction: Vector2, color: Color, radius: float, lifetime: float, z: int) -> void:
    var flash = _acquire_hit_flash()
    flash.z_index = z
    flash.flash(position, direction, color, radius, lifetime)

func _physics_process(delta: float) -> void:
    for fragment in _fragments:
        if fragment.visible:
            fragment.tick(delta)
    for i in range(_afterimages.size()):
        var afterimage: Sprite = _afterimages[i]
        if !afterimage.visible:
            continue
        var age: float = _afterimage_ages[i] + delta
        _afterimage_ages[i] = age
        var pct: float = age / _afterimage_lifetimes[i]
        if pct >= 1.0:
            afterimage.visible = false
            continue
        var base_color: Color = _afterimage_colors[i]
        var remaining: float = 1.0 - pct
        base_color.a *= remaining * remaining
        afterimage.modulate = base_color
        afterimage.scale = afterimage.scale.linear_interpolate(Vector2.ZERO, min(1.0, delta * 2.4))
    for flash in _hit_flashes:
        if flash.visible:
            flash.tick(delta)

func _acquire_fragment():
    for offset in range(_fragments.size()):
        var index: int = (_fragment_cursor + offset) % _fragments.size()
        if !_fragments[index].visible:
            _fragment_cursor = (index + 1) % _fragments.size()
            return _fragments[index]
    if _fragments.size() < FRAGMENT_POOL_SIZE:
        var fragment = _create_fragment()
        _fragment_cursor = _fragments.size() % FRAGMENT_POOL_SIZE
        return fragment
    var recycled = _fragments[_fragment_cursor]
    _fragment_cursor = (_fragment_cursor + 1) % _fragments.size()
    return recycled

func _acquire_afterimage() -> int:
    for offset in range(_afterimages.size()):
        var index: int = (_afterimage_cursor + offset) % _afterimages.size()
        if !_afterimages[index].visible:
            _afterimage_cursor = (index + 1) % _afterimages.size()
            return index
    if _afterimages.size() < AFTERIMAGE_POOL_SIZE:
        _create_afterimage()
        _afterimage_cursor = _afterimages.size() % AFTERIMAGE_POOL_SIZE
        return _afterimages.size() - 1
    var recycled_index: int = _afterimage_cursor
    _afterimage_cursor = (_afterimage_cursor + 1) % _afterimages.size()
    return recycled_index

func _acquire_hit_flash():
    for offset in range(_hit_flashes.size()):
        var index: int = (_hit_flash_cursor + offset) % _hit_flashes.size()
        if !_hit_flashes[index].visible:
            _hit_flash_cursor = (index + 1) % _hit_flashes.size()
            return _hit_flashes[index]
    if _hit_flashes.size() < HIT_FLASH_POOL_SIZE:
        var flash = _create_hit_flash()
        _hit_flash_cursor = _hit_flashes.size() % HIT_FLASH_POOL_SIZE
        return flash
    var recycled = _hit_flashes[_hit_flash_cursor]
    _hit_flash_cursor = (_hit_flash_cursor + 1) % _hit_flashes.size()
    return recycled

func _create_fragment():
    var fragment = SlashSparkVisual.new()
    fragment.name = "Fragment%s" % _fragments.size()
    fragment.set_as_toplevel(true)
    fragment.z_as_relative = false
    fragment.visible = false
    add_child(fragment)
    _fragments.push_back(fragment)
    return fragment

func _create_afterimage() -> Sprite:
    var afterimage: Sprite = Sprite.new()
    afterimage.name = "Afterimage%s" % _afterimages.size()
    afterimage.set_as_toplevel(true)
    afterimage.z_as_relative = false
    afterimage.visible = false
    add_child(afterimage)
    _afterimages.push_back(afterimage)
    _afterimage_ages.push_back(1.0)
    _afterimage_lifetimes.push_back(0.1)
    _afterimage_colors.push_back(Color(0, 0, 0, 0))
    return afterimage

func _create_hit_flash():
    var flash = SlashHitFlashVisual.new()
    flash.name = "HitFlash%s" % _hit_flashes.size()
    flash.set_as_toplevel(true)
    flash.z_as_relative = false
    flash.visible = false
    add_child(flash)
    _hit_flashes.push_back(flash)
    return flash
