extends Sprite

const MASK = preload("res://mods-unpacked/Yoko-Fantasy/content/weapons/ranged/harp/harp_strings_mask.png")
const STRING_SHADER = preload("res://mods-unpacked/Yoko-Fantasy/content/weapons/ranged/harp/harp_strings.gdshader")
const COLORS = [Color(0.46, 0.86, 1.0), Color(1.0, 0.67, 0.3), Color(0.83, 0.48, 1.0), Color(1.0, 0.86, 0.48)]

var _time: float = 1.0


func _ready() -> void:
    texture = MASK
    scale = Vector2.ONE * 0.5
    material = ShaderMaterial.new()
    material.shader = STRING_SHADER
    visible = false
    set_process(false)


func pluck(note_index: int) -> void:
    _time = 0.0
    material.set_shader_param("age", 0.0)
    material.set_shader_param("accent", COLORS[note_index])
    visible = true
    set_process(true)


func _process(delta: float) -> void:
    _time += delta
    if _time > 0.7:
        visible = false
        set_process(false)
    else:
        material.set_shader_param("age", _time)
