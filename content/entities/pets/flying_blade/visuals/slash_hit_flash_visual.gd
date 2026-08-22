extends Node2D

const TEXTURE_STAR_GLINT = preload("res://mods-unpacked/Yoko-Fantasy/content/entities/pets/flying_blade/visuals/textures/star_glint_4pt.png")

var _material: CanvasItemMaterial = null
var _sprite_glint: Sprite = null

var _base_color: Color = Color.white
var _age: float = 0.0
var _lifetime: float = 0.10
var _radius: float = 20.0

func _init() -> void:
	_material = CanvasItemMaterial.new()
	_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = _material

	_sprite_glint = Sprite.new()
	_sprite_glint.name = "CenterGlint"
	_sprite_glint.texture = TEXTURE_STAR_GLINT
	_sprite_glint.material = _material
	_sprite_glint.centered = true
	_sprite_glint.z_as_relative = false
	_sprite_glint.z_index = 24
	add_child(_sprite_glint)

func flash(p_position: Vector2, direction: Vector2, color: Color, radius: float, lifetime: float) -> void:
	global_position = p_position
	global_rotation = direction.angle() + rand_range(-0.6, 0.6)
	_base_color = color
	_radius = clamp(radius, 16.0, 26.0)
	_lifetime = max(0.08, min(0.14, lifetime))
	_age = 0.0
	visible = true
	_refresh(1.0)

func tick(delta: float) -> bool:
	if !visible:
		return false
	_age += delta
	var pct: float = _age / _lifetime
	if pct >= 1.0:
		hide_visual()
		return false
	global_rotation += delta * 2.2
	_refresh(1.0 - pct)
	return true

func hide_visual() -> void:
	visible = false
	if is_instance_valid(_sprite_glint):
		_sprite_glint.visible = false

func _refresh(strength: float) -> void:
	var progress: float = 1.0 - strength
	var current_radius: float = _radius * (1.15 - progress * 0.45)
	var scale_val: float = (current_radius * 2.0) / 128.0

	var alpha: float = clamp(_base_color.a * strength * 1.1, 0.0, 0.95)
	var col_glint: Color = Color(_base_color.r * 1.2, _base_color.g * 1.15, _base_color.b * 1.4, alpha)

	_sprite_glint.scale = Vector2(scale_val, scale_val)
	_sprite_glint.modulate = col_glint
	_sprite_glint.visible = true
