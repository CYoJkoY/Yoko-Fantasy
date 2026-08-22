extends Node2D

const TEXTURE_EMBER = preload("res://mods-unpacked/Yoko-Fantasy/content/entities/pets/flying_blade/visuals/textures/spark_fleck_flow.png")

var _material: CanvasItemMaterial = null
var _sprite: Sprite = null

var velocity: Vector2 = Vector2.ZERO
var angular_velocity: float = 0.0
var age: float = 0.0
var lifetime: float = 0.12
var _base_color: Color = Color.white
var length: float = 16.0
var width: float = 3.0

func _init() -> void:
    _material = CanvasItemMaterial.new()
    _material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
    material = _material

    _sprite = Sprite.new()
    _sprite.name = "SparkSprite"
    _sprite.texture = TEXTURE_EMBER
    _sprite.material = _material
    _sprite.centered = true
    add_child(_sprite)

func ignite(p_position: Vector2, direction: Vector2, p_color: Color, p_lifetime: float, p_length: float, p_width: float, p_velocity: Vector2, p_angular_velocity: float) -> void:
    global_position = p_position
    global_rotation = direction.angle()
    _base_color = p_color
    lifetime = max(0.02, min(0.14, p_lifetime))
    length = max(6.0, p_length * 0.65)
    width = max(1.5, p_width * 0.55)
    velocity = p_velocity
    angular_velocity = p_angular_velocity
    age = 0.0
    visible = true
    _refresh(1.0)

func tick(delta: float) -> bool:
    if !visible:
        return false
    age += delta
    var pct: float = age / lifetime
    if pct >= 1.0:
        hide_visual()
        return false
    global_position += velocity * delta
    velocity = velocity.linear_interpolate(Vector2.ZERO, delta * 7.5)
    global_rotation += angular_velocity * delta
    _refresh(1.0 - pct)
    return true

func hide_visual() -> void:
    visible = false
    if is_instance_valid(_sprite):
        _sprite.visible = false

func _refresh(strength: float) -> void:
    var sx: float = (length / 48.0) * strength
    var sy: float = (width / 24.0) * strength * strength
    _sprite.scale = Vector2(sx, sy)
    var col: Color = Color(_base_color.r * 1.3, _base_color.g * 1.2, _base_color.b * 1.5, _base_color.a * strength * strength)
    _sprite.modulate = col
    _sprite.visible = true
