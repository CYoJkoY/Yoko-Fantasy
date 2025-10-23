extends EnemyProjectile

var min_range: int = 0
var max_range: int = 0

onready var end_container = $EndContainer
onready var start_container = $StartContainer
onready var contents = $Contents
onready var Line = $Line
onready var _line = $Line/line

func shoot()->void :
	.shoot()
	
	if contents != null:
		_animation_player.playback_speed = 2
		var sprite_w = _sprite.texture.get_width()
		var base_scale_x = max(1.0, float(max_range) / float(sprite_w))
		var hitbox_scale_x = max(1.0, (max_range + sprite_w * 2.0) / sprite_w)
		
		_line.scale.x = base_scale_x
		Line.position.x = sprite_w
		
		_sprite.scale.x = base_scale_x
		_hitbox.scale.x = hitbox_scale_x
		_hitbox.position.x = - sprite_w
		end_container.position.x = max_range + sprite_w
		contents.position.x = sprite_w
		start_container.position.x = 0

func set_range(p_min_range: int, p_max_range: int) -> void:
	min_range = p_min_range
	max_range = p_max_range
