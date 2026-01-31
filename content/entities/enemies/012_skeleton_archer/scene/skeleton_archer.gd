extends Enemy

var _cache_current_speed: int

onready var bow: = $Animation / Bow as Sprite
onready var bow_arm: = $Animation / BowArm as Sprite
onready var arrow: = $Animation / Arrow as Sprite
onready var up_arm: = $Animation / UpArm as Sprite
onready var down_arm: = $Animation / DownArm as Sprite

func nullify_speed() -> void:
    _cache_current_speed = current_stats.speed
    current_stats.speed = 0

func recovery_speed() -> void:
    current_stats.speed = _cache_current_speed

func get_direction()->int:
    var direction: int = 1 if _animation.scale.x > 0 else -1
    
    return direction

func update_animation(movement: Vector2)->void :
    if mirror_sprite_with_movement:
        if movement.x > 0:
            _animation.scale.x = abs(_animation.scale.x)
        elif movement.x < 0:
            _animation.scale.x = - abs(_animation.scale.x)

func death_animation_finished()->void :
    is_boosted = false
    _outline_colors.clear()
    sprite.material = null
    bow.material = null
    bow_arm.material = null
    arrow.material = null
    up_arm.material = null
    down_arm.material = null
    _current_material_alpha = 1.0
    _current_material_desaturation = 0.0
    _boosted_args = null
    sleeping = true
    hide()
    call_deferred("set_physics_process", false)

    _animation_player.play("RESET")
    _animation_player.advance(1.0)
    Utils.get_scene_node().add_node_to_pool(self)

func _set_outlines(alpha: float = 1.0, desaturation: float = 0.0)->void :
    if !_outline_colors:
        sprite.material = null
        bow.material = null
        bow_arm.material = null
        arrow.material = null
        up_arm.material = null
        down_arm.material = null
        return 

    sprite.material = ShaderMaterial.new()
    bow.material = ShaderMaterial.new()
    bow_arm.material = ShaderMaterial.new()
    arrow.material = ShaderMaterial.new()
    up_arm.material = ShaderMaterial.new()
    down_arm.material = ShaderMaterial.new()
    sprite.material.shader = outline_material.shader
    bow.material.shader = outline_material.shader
    bow_arm.material.shader = outline_material.shader
    arrow.material.shader = outline_material.shader
    up_arm.material.shader = outline_material.shader
    down_arm.material.shader = outline_material.shader

    sprite.material.set_shader_param("texture_size", sprite.texture.get_size())
    bow.material.set_shader_param("texture_size", bow.texture.get_size())
    bow_arm.material.set_shader_param("texture_size", bow_arm.texture.get_size())
    arrow.material.set_shader_param("texture_size", arrow.texture.get_size())
    up_arm.material.set_shader_param("texture_size", up_arm.texture.get_size())
    down_arm.material.set_shader_param("texture_size", down_arm.texture.get_size())

    if alpha < 1.0:
        _current_material_alpha = alpha
        sprite.material.set_shader_param("alpha", alpha)
        bow.material.set_shader_param("alpha", alpha)
        bow_arm.material.set_shader_param("alpha", alpha)
        arrow.material.set_shader_param("alpha", alpha)
        up_arm.material.set_shader_param("alpha", alpha)
        down_arm.material.set_shader_param("alpha", alpha)
    else :
        sprite.material.set_shader_param("alpha", _current_material_alpha)
        bow.material.set_shader_param("alpha", _current_material_alpha)
        bow_arm.material.set_shader_param("alpha", _current_material_alpha)
        arrow.material.set_shader_param("alpha", _current_material_alpha)
        up_arm.material.set_shader_param("alpha", _current_material_alpha)
        down_arm.material.set_shader_param("alpha", _current_material_alpha)

    if desaturation > 0.0:
        _current_material_desaturation = desaturation
        sprite.material.set_shader_param("desaturation", desaturation)
        bow.material.set_shader_param("desaturation", desaturation)
        bow_arm.material.set_shader_param("desaturation", desaturation)
        arrow.material.set_shader_param("desaturation", desaturation)
        up_arm.material.set_shader_param("desaturation", desaturation)
        down_arm.material.set_shader_param("desaturation", desaturation)
    else :
        sprite.material.set_shader_param("desaturation", _current_material_desaturation)
        bow.material.set_shader_param("desaturation", _current_material_desaturation)
        bow_arm.material.set_shader_param("desaturation", _current_material_desaturation)
        arrow.material.set_shader_param("desaturation", _current_material_desaturation)
        up_arm.material.set_shader_param("desaturation", _current_material_desaturation)
        down_arm.material.set_shader_param("desaturation", _current_material_desaturation)

    for i in _outline_colors.size():
        sprite.material.set_shader_param("outline_color_%s" % i, _outline_colors[i])
        bow.material.set_shader_param("outline_color_%s" % i, _outline_colors[i])
        bow_arm.material.set_shader_param("outline_color_%s" % i, _outline_colors[i])
        arrow.material.set_shader_param("outline_color_%s" % i, _outline_colors[i])
        up_arm.material.set_shader_param("outline_color_%s" % i, _outline_colors[i])
        down_arm.material.set_shader_param("outline_color_%s" % i, _outline_colors[i])

func flash()->void :
    var is_already_flashing = sprite.material == flash_mat
    if !is_already_flashing:
        _non_flash_material = sprite.material
        sprite.material = flash_mat
        bow.material = flash_mat
        bow_arm.material = flash_mat
        arrow.material = flash_mat
        up_arm.material = flash_mat
        down_arm.material = flash_mat
    _flash_timer.start()


func _on_FlashTimer_timeout()->void :
    if sprite.material == flash_mat:
        sprite.material = _non_flash_material
        bow.material = _non_flash_material
        bow_arm.material = _non_flash_material
        arrow.material = _non_flash_material
        up_arm.material = _non_flash_material
        down_arm.material = _non_flash_material
