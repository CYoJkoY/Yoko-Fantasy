class_name HandbellWeapon
extends MeleeWeapon

const STRIKE_RIPPLE_SCENE: PackedScene = preload("res://mods-unpacked/Yoko-Fantasy/content/projectiles/player/handbell_orb_projectile/handbell_hit_ripple.tscn")
onready var _strike_ripple_pool_id: int = STRIKE_RIPPLE_SCENE.get_instance_id()

var _vibration_time: float = 0.0
const VIBRATION_DURATION: float = 0.12
var _flash_time: float = 0.0
const FLASH_DURATION: float = 0.10
var _was_flashing: bool = false
var _was_vibrating: bool = false


func _ready() -> void:
	._ready()
	_hitbox.connect("hit_something", self, "_on_handbell_hit_something")


func _process(delta: float) -> void:
	if _vibration_time > 0.0:
		_vibration_time -= delta
		_was_vibrating = true
		var fade: float = clamp(_vibration_time / VIBRATION_DURATION, 0.0, 1.0)
		var shake_offset: Vector2 = Vector2(
			cos(_vibration_time * 95.0),
			sin(_vibration_time * 80.0)
		) * 4.0 * fade

		if is_instance_valid(sprite):
			sprite.offset = shake_offset
	elif _was_vibrating:
		_was_vibrating = false
		if is_instance_valid(sprite):
			sprite.offset = Vector2.ZERO

	if _flash_time > 0.0:
		_flash_time -= delta
		_was_flashing = true
		var flash_fade: float = clamp(_flash_time / FLASH_DURATION, 0.0, 1.0)
		if is_instance_valid(sprite):
			sprite.modulate = Color(1.0 + 0.85 * flash_fade, 1.0 + 0.75 * flash_fade, 1.0 + 0.3 * flash_fade, 1.0)
	elif _was_flashing:
		_was_flashing = false
		if is_instance_valid(sprite):
			sprite.modulate = Color.white


func _on_handbell_hit_something(thing_hit: Node, _damage_dealt: int) -> void:
	_vibration_time = VIBRATION_DURATION
	_flash_time = FLASH_DURATION

	if thing_hit != null and is_instance_valid(thing_hit):
		_spawn_strike_shockwave(thing_hit.global_position)


func _spawn_strike_shockwave(at_pos: Vector2) -> void:
	var main = Utils.get_scene_node()
	if main == null or not is_instance_valid(main):
		return
	var ripple = main.get_node_from_pool(_strike_ripple_pool_id, main._effects)
	if ripple == null:
		ripple = STRIKE_RIPPLE_SCENE.instance()
		main.add_effect(ripple)
		ripple.set_meta("pool_id", _strike_ripple_pool_id)
	ripple.play(at_pos, main, _strike_ripple_pool_id, false)
