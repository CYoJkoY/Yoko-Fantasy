extends Node2D

const SlashSparkVisual = preload("res://mods-unpacked/Yoko-Fantasy/content/entities/pets/flying_blade/visuals/slash_spark_visual.gd")
const SlashHitFlashVisual = preload("res://mods-unpacked/Yoko-Fantasy/content/entities/pets/flying_blade/visuals/slash_hit_flash_visual.gd")
const SlashRibbonVisual = preload("res://mods-unpacked/Yoko-Fantasy/content/entities/pets/flying_blade/visuals/slash_ribbon_visual.gd")

const FRAGMENT_POOL_SIZE = 32
const AFTERIMAGE_POOL_SIZE = 24
const HIT_FLASH_POOL_SIZE = 24
const SLASH_RIFT_POOL_SIZE = 16

var _material_add: CanvasItemMaterial = null

var _fragments: Array = []
var _afterimages: Array = []
var _afterimage_ages: Array = []
var _afterimage_lifetimes: Array = []
var _afterimage_colors: Array = []
var _hit_flashes: Array = []
var _slash_rifts: Array = []

var _fragment_cursor: int = 0
var _afterimage_cursor: int = 0
var _hit_flash_cursor: int = 0
var _slash_rift_cursor: int = 0

var _fragment_capacity: int = 4
var _afterimage_capacity: int = 2
var _hit_flash_capacity: int = 4
var _slash_rift_capacity: int = 4

func _init() -> void:
	_material_add = CanvasItemMaterial.new()
	_material_add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	set_physics_process(false)

func ensure_capacity(sword_count: int) -> void:
	var count: int = int(max(1, sword_count))
	_fragment_capacity = int(clamp(count * 2, 4, FRAGMENT_POOL_SIZE))
	_afterimage_capacity = int(clamp(count * 2, 2, AFTERIMAGE_POOL_SIZE))
	_hit_flash_capacity = int(clamp(count, 4, HIT_FLASH_POOL_SIZE))
	_slash_rift_capacity = int(clamp(count, 4, SLASH_RIFT_POOL_SIZE))

	while _fragments.size() < _fragment_capacity:
		_create_fragment()
	while _afterimages.size() < _afterimage_capacity:
		_create_afterimage()
	while _hit_flashes.size() < _hit_flash_capacity:
		_create_hit_flash()
	while _slash_rifts.size() < _slash_rift_capacity:
		_create_slash_rift()

func emit_slash_rift(start_pos: Vector2, control_pos: Vector2, end_pos: Vector2, direction: Vector2, curve_side: float, slash_width: float, slash_color: Color, lifetime: float = 0.18, z: int = 18) -> void:
	set_physics_process(true)
	var rift = _acquire_slash_rift()
	rift.z_index = z
	rift.ignite_world_rift(start_pos, control_pos, end_pos, direction, curve_side, slash_width, slash_color, lifetime)

func emit_fragment(position: Vector2, direction: Vector2, color: Color, lifetime: float, length: float, width: float, velocity: Vector2, angular_velocity: float, z: int) -> void:
	set_physics_process(true)
	var fragment = _acquire_fragment()
	fragment.z_index = z
	fragment.ignite(position, direction, color, lifetime, length, width, velocity, angular_velocity)

func emit_afterimage(texture: Texture, centered: bool, offset: Vector2, flip_h: bool, flip_v: bool, position: Vector2, rotation: float, scale: Vector2, color: Color, lifetime: float, z: int) -> void:
	set_physics_process(true)
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
	set_physics_process(true)
	var flash = _acquire_hit_flash()
	flash.z_index = z
	flash.flash(position, direction, color, radius, lifetime)

func _physics_process(delta: float) -> void:
	var has_active_visual: bool = false
	for fragment in _fragments:
		if fragment.visible:
			fragment.tick(delta)
			has_active_visual = has_active_visual or fragment.visible
	for rift in _slash_rifts:
		if rift.visible:
			rift.tick(delta)
			has_active_visual = has_active_visual or rift.visible
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
		afterimage.scale = afterimage.scale.linear_interpolate(Vector2.ZERO, min(1.0, delta * 2.5))
		has_active_visual = true
	for flash in _hit_flashes:
		if flash.visible:
			flash.tick(delta)
			has_active_visual = has_active_visual or flash.visible
	if !has_active_visual:
		set_physics_process(false)

func _acquire_fragment():
	var active_size: int = int(min(_fragments.size(), _fragment_capacity))
	for offset in range(active_size):
		var index: int = (_fragment_cursor + offset) % active_size
		if !_fragments[index].visible:
			_fragment_cursor = (index + 1) % active_size
			return _fragments[index]
	if _fragments.size() < _fragment_capacity:
		var fragment = _create_fragment()
		_fragment_cursor = _fragments.size() % FRAGMENT_POOL_SIZE
		return fragment
	var recycle_index: int = _fragment_cursor % active_size
	var recycled = _fragments[recycle_index]
	_fragment_cursor = (recycle_index + 1) % active_size
	return recycled

func _acquire_slash_rift():
	var active_size: int = int(min(_slash_rifts.size(), _slash_rift_capacity))
	for offset in range(active_size):
		var index: int = (_slash_rift_cursor + offset) % active_size
		if !_slash_rifts[index].visible:
			_slash_rift_cursor = (index + 1) % active_size
			return _slash_rifts[index]
	if _slash_rifts.size() < _slash_rift_capacity:
		var rift = _create_slash_rift()
		_slash_rift_cursor = _slash_rifts.size() % SLASH_RIFT_POOL_SIZE
		return rift
	var recycle_index: int = _slash_rift_cursor % active_size
	var recycled = _slash_rifts[recycle_index]
	_slash_rift_cursor = (recycle_index + 1) % active_size
	return recycled

func _acquire_afterimage() -> int:
	var active_size: int = int(min(_afterimages.size(), _afterimage_capacity))
	for offset in range(active_size):
		var index: int = (_afterimage_cursor + offset) % active_size
		if !_afterimages[index].visible:
			_afterimage_cursor = (index + 1) % active_size
			return index
	if _afterimages.size() < _afterimage_capacity:
		_create_afterimage()
		_afterimage_cursor = _afterimages.size() % AFTERIMAGE_POOL_SIZE
		return _afterimages.size() - 1
	var recycled_index: int = _afterimage_cursor % active_size
	_afterimage_cursor = (recycled_index + 1) % active_size
	return recycled_index

func _acquire_hit_flash():
	var active_size: int = int(min(_hit_flashes.size(), _hit_flash_capacity))
	for offset in range(active_size):
		var index: int = (_hit_flash_cursor + offset) % active_size
		if !_hit_flashes[index].visible:
			_hit_flash_cursor = (index + 1) % active_size
			return _hit_flashes[index]
	if _hit_flashes.size() < _hit_flash_capacity:
		var flash = _create_hit_flash()
		_hit_flash_cursor = _hit_flashes.size() % HIT_FLASH_POOL_SIZE
		return flash
	var recycle_index: int = _hit_flash_cursor % active_size
	var recycled = _hit_flashes[recycle_index]
	_hit_flash_cursor = (recycle_index + 1) % active_size
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

func _create_slash_rift():
	var rift = SlashRibbonVisual.new()
	rift.name = "SlashRift%s" % _slash_rifts.size()
	rift.set_as_toplevel(true)
	rift.z_as_relative = false
	rift.visible = false
	add_child(rift)
	_slash_rifts.push_back(rift)
	return rift

func _create_afterimage() -> Sprite:
	var afterimage: Sprite = Sprite.new()
	afterimage.name = "Afterimage%s" % _afterimages.size()
	afterimage.material = _material_add
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
