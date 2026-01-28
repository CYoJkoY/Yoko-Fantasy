extends Enemy

onready var arm: = $Animation / Arm as Sprite
onready var arm_projectile: = $Animation / ArmProjectile as Sprite

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
    arm.material = null
    arm_projectile.material = null
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
    if not _outline_colors:
        sprite.material = null
        arm.material = null
        arm_projectile.material = null
        return 

    sprite.material = ShaderMaterial.new()
    arm.material = ShaderMaterial.new()
    arm_projectile.material = ShaderMaterial.new()
    sprite.material.shader = outline_material.shader
    arm.material.shader = outline_material.shader
    arm_projectile.material.shader = outline_material.shader

    sprite.material.set_shader_param("texture_size", sprite.texture.get_size())
    arm.material.set_shader_param("texture_size", arm.texture.get_size())
    arm_projectile.material.set_shader_param("texture_size", arm_projectile.texture.get_size())

    if alpha < 1.0:
        _current_material_alpha = alpha
        sprite.material.set_shader_param("alpha", alpha)
        arm.material.set_shader_param("alpha", alpha)
        arm_projectile.material.set_shader_param("alpha", alpha)
    else :
        sprite.material.set_shader_param("alpha", _current_material_alpha)
        arm.material.set_shader_param("alpha", _current_material_alpha)
        arm_projectile.material.set_shader_param("alpha", _current_material_alpha)

    if desaturation > 0.0:
        _current_material_desaturation = desaturation
        sprite.material.set_shader_param("desaturation", desaturation)
        arm.material.set_shader_param("desaturation", desaturation)
        arm_projectile.material.set_shader_param("desaturation", desaturation)
    else :
        sprite.material.set_shader_param("desaturation", _current_material_desaturation)
        arm.material.set_shader_param("desaturation", _current_material_desaturation)
        arm_projectile.material.set_shader_param("desaturation", _current_material_desaturation)

    for i in range(_outline_colors.size()):
        sprite.material.set_shader_param("outline_color_%s" % i, _outline_colors[i])
        arm.material.set_shader_param("outline_color_%s" % i, _outline_colors[i])
        arm_projectile.material.set_shader_param("outline_color_%s" % i, _outline_colors[i])

func flash()->void :
    var is_already_flashing = sprite.material == flash_mat
    if not is_already_flashing:
        _non_flash_material = sprite.material
        sprite.material = flash_mat
        arm.material = flash_mat
        arm_projectile.material = flash_mat
    _flash_timer.start()


func _on_FlashTimer_timeout()->void :
    if sprite.material == flash_mat:
        sprite.material = _non_flash_material
        arm.material = _non_flash_material
        arm_projectile.material = _non_flash_material

