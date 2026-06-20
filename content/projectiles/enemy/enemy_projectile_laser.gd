extends Projectile

var min_range: int = 0
var max_range: int = 0

onready var end_container: Node2D = $LaserVisuals/EndContainer
onready var start_container: Node2D = $LaserVisuals/StartContainer
onready var contents: Node2D = $LaserVisuals/Contents
onready var content_sprite: Sprite = $LaserVisuals/Contents/Content
onready var line: Node2D = $LaserVisuals/Line
onready var line_sprite: Sprite = $LaserVisuals/Line/line

# =========================== Extension =========================== #
func _ready() -> void:
	._ready()

func shoot() -> void:
	_hitbox.active = true
	if not _original_hitbox_disabled:
		_hitbox.enable()
	_animation_player.play("fire")
	_animation_player.playback_speed = 2
	var sprite_w = content_sprite.texture.get_width()
	var base_scale_x = max(1.0, float(max_range) / float(sprite_w))
	var hitbox_scale_x = max(1.0, (max_range + sprite_w * 2.0) / sprite_w)

	line_sprite.scale.x = base_scale_x
	content_sprite.scale.x = base_scale_x
	_hitbox.scale.x = hitbox_scale_x

	end_container.position.x = max_range + sprite_w
	line.position.x = sprite_w
	contents.position.x = sprite_w
	_hitbox.position.x = - sprite_w
	start_container.position.x = 0
	_set_laser_outline_texture_sizes()

func set_range(p_min_range: int, p_max_range: int) -> void:
	min_range = p_min_range
	max_range = p_max_range

func _set_laser_outline_texture_sizes() -> void:
	var outline_size: Vector2 = content_sprite.texture.get_size() if ProgressData.settings.projectile_highlighting else Vector2(0, 0)
	content_sprite.material.set_shader_param("texture_size", outline_size)
