extends Node2D

const DURATION: float = 0.16

var _elapsed: float = 0.0
var _main: Node = null
var _pool_id: int = 0

onready var _speed_streak_sprite: Sprite = $"%SpeedStreakSprite" as Sprite
onready var _primary_cut_sprite: Sprite = $"%PrimaryCutSprite" as Sprite
onready var _secondary_cut_sprite: Sprite = $"%SecondaryCutSprite" as Sprite
onready var _impact_core_sprite: Sprite = $"%ImpactCoreSprite" as Sprite
onready var _sparkle_particles: CPUParticles2D = $"%SparkleParticles" as CPUParticles2D


func _ready() -> void:
	visible = false
	set_process(false)


func play(at_position: Vector2, impact_rotation: float, main: Node, pool_id: int) -> void:
	_main = main
	_pool_id = pool_id
	_elapsed = 0.0
	global_position = at_position
	global_rotation = impact_rotation
	modulate.a = ProgressData.settings.projectile_opacity
	visible = true

	_speed_streak_sprite.position = Vector2(-14.0, 0.0)
	_speed_streak_sprite.scale = Vector2(0.34, 0.42)
	_speed_streak_sprite.modulate.a = 0.9
	_primary_cut_sprite.position = Vector2(4.0, 0.0)
	_primary_cut_sprite.rotation = rand_range(-0.10, 0.10)
	_primary_cut_sprite.scale = Vector2(0.34, 0.78)
	_primary_cut_sprite.modulate.a = 1.0
	_secondary_cut_sprite.position = Vector2(0.0, 0.0)
	_secondary_cut_sprite.rotation = -1.22 + rand_range(-0.08, 0.08)
	_secondary_cut_sprite.scale = Vector2(0.20, 0.52)
	_secondary_cut_sprite.modulate.a = 0.0
	_impact_core_sprite.position = Vector2(10.0, 0.0)
	_impact_core_sprite.scale = Vector2(0.48, 0.16)
	_impact_core_sprite.modulate.a = 1.0

	_sparkle_particles.emitting = true
	_sparkle_particles.restart()
	set_process(true)


func _process(delta: float) -> void:
	_elapsed += delta
	var progress: float = clamp(_elapsed / DURATION, 0.0, 1.0)
	var snap: float = 1.0 - pow(1.0 - min(progress * 2.8, 1.0), 3.0)
	var ease_out: float = 1.0 - pow(1.0 - progress, 3.0)
	var fade: float = 1.0 - progress

	_speed_streak_sprite.position.x = lerp(-14.0, 28.0, ease_out)
	_speed_streak_sprite.scale = Vector2(lerp(0.34, 1.24, snap), lerp(0.42, 0.18, ease_out))
	_speed_streak_sprite.modulate.a = fade * fade * fade * 0.9

	_primary_cut_sprite.position.x = lerp(4.0, 14.0, ease_out)
	_primary_cut_sprite.scale = Vector2(lerp(0.34, 0.98, snap), lerp(0.78, 0.62, ease_out))
	_primary_cut_sprite.modulate.a = fade * fade

	var secondary_progress: float = clamp((progress - 0.10) / 0.90, 0.0, 1.0)
	var secondary_snap: float = 1.0 - pow(1.0 - min(secondary_progress * 3.2, 1.0), 3.0)
	_secondary_cut_sprite.position.x = lerp(0.0, 10.0, secondary_progress)
	_secondary_cut_sprite.scale = Vector2(lerp(0.20, 0.70, secondary_snap), lerp(0.52, 0.44, secondary_progress))
	_secondary_cut_sprite.modulate.a = sin(secondary_progress * PI) * fade * 0.72

	_impact_core_sprite.position.x = lerp(10.0, 25.0, ease_out)
	_impact_core_sprite.scale = Vector2(lerp(0.48, 1.12, snap), lerp(0.16, 0.04, ease_out))
	_impact_core_sprite.modulate.a = fade * fade * fade

	if _elapsed >= DURATION:
		_finish()


func _finish() -> void:
	visible = false
	_sparkle_particles.emitting = false
	set_process(false)
	if is_instance_valid(_main):
		_main.add_node_to_pool(self, _pool_id)
	else:
		queue_free()
