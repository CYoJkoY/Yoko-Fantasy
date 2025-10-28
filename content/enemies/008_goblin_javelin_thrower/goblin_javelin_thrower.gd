extends Enemy

onready var arm: = $Animation / Arm as Sprite
onready var arm_projectile: = $Animation / ArmProjectile as Sprite

func death_animation_finished()->void :
	.death_animation_finished()
	
	arm.material = null
	arm_projectile.material = null

func _set_outlines(alpha: float = 1.0, desaturation: float = 0.0)->void :
	._set_outlines(alpha, desaturation)
	
	if not _outline_colors:
		arm.material = null
		arm_projectile.material = null
		return 

	arm.material = ShaderMaterial.new()
	arm_projectile.material = ShaderMaterial.new()
	arm.material.shader = outline_material.shader
	arm_projectile.material.shader = outline_material.shader

	arm.material.set_shader_param("texture_size", arm.texture.get_size())
	arm_projectile.material.set_shader_param("texture_size", arm_projectile.texture.get_size())

	if alpha < 1.0:
		_current_material_alpha = alpha
		arm.material.set_shader_param("alpha", alpha)
		arm_projectile.material.set_shader_param("alpha", alpha)
	else :
		arm.material.set_shader_param("alpha", _current_material_alpha)
		arm_projectile.material.set_shader_param("alpha", _current_material_alpha)

	if desaturation > 0.0:
		_current_material_desaturation = desaturation
		arm.material.set_shader_param("desaturation", desaturation)
		arm_projectile.material.set_shader_param("desaturation", desaturation)
	else :
		arm.material.set_shader_param("desaturation", _current_material_desaturation)
		arm_projectile.material.set_shader_param("desaturation", _current_material_desaturation)

	for i in range(_outline_colors.size()):
		arm.material.set_shader_param("outline_color_%s" % i, _outline_colors[i])
		arm_projectile.material.set_shader_param("outline_color_%s" % i, _outline_colors[i])

func update_animation(movement: Vector2)->void :
	.update_animation(movement)
	
	if mirror_sprite_with_movement:
		if movement.x > 0:
			arm.scale.x = abs(arm.scale.x)
			arm_projectile.scale.x = abs(arm_projectile.scale.x)
		elif movement.x < 0:
			arm.scale.x = - abs(arm.scale.x)
			arm_projectile.scale.x = - abs(arm_projectile.scale.x)

func flash()->void :
	.flash()
	
	var is_already_flashing = sprite.material == flash_mat
	if not is_already_flashing:
		arm.material = flash_mat
		arm_projectile.material = flash_mat

func _on_FlashTimer_timeout()->void :
	._on_FlashTimer_timeout()
	
	if sprite.material == flash_mat:
		arm.material = _non_flash_material
		arm_projectile.material = _non_flash_material
