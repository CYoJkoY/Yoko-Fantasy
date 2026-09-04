extends Node2D

const PRIMARY_SLASH_DURATION: float = 0.085
const SECONDARY_SLASH_DURATION: float = 0.075
const FINISH_DURATION: float = 0.18

var target_unit: Node = null
var remaining_ticks: int = 3
var damage_per_tick: int = 5
var tick_interval: float = 0.13
var player_index: int = 0
var weapon_pos: int = 0
var crit_chance: float = 0.0
var crit_damage: float = 2.0

var _main: Node = null
var _pool_id: int = 0
var _timer: float = 0.0
var _visual_time: float = 0.0
var _slash_1_time: float = 0.0
var _slash_2_time: float = 0.0
var _slash_2_delay: float = 0.0
var _finish_delay: float = 0.0
var _finishing: bool = false
var _finished: bool = false
var _visual_opacity: float = 1.0
var _damage_args: TakeDamageArgs = null

onready var _vortex_sprite: Sprite = $"%VortexSprite" as Sprite
onready var _vortex_echo_sprite: Sprite = $"%VortexEchoSprite" as Sprite
onready var _slash_sprite_1: Sprite = $"%SlashSprite1" as Sprite
onready var _slash_sprite_2: Sprite = $"%SlashSprite2" as Sprite
onready var _particles: CPUParticles2D = $"%Particles" as CPUParticles2D


func _ready() -> void:
	visible = false
	set_physics_process(false)


func init_wind_force(
	p_target: Node,
	p_ticks: int,
	p_damage: int,
	p_interval: float,
	p_player_index: int,
	p_weapon_pos: int,
	p_crit_chance: float,
	p_crit_damage: float,
	main: Node,
	pool_id: int
) -> void:
	target_unit = p_target
	remaining_ticks = max(1, p_ticks) as int
	damage_per_tick = max(1, p_damage) as int
	tick_interval = max(0.05, p_interval)
	player_index = p_player_index
	weapon_pos = p_weapon_pos
	crit_chance = p_crit_chance
	crit_damage = p_crit_damage
	_damage_args = Utils.ncl_create_custom_damage_args(player_index, Color("#62e9be"))
	_main = main
	_pool_id = pool_id

	_timer = 0.0
	_visual_time = rand_range(0.0, 10.0)
	_slash_1_time = 0.0
	_slash_2_time = 0.0
	_slash_2_delay = 0.0
	_finish_delay = 0.0
	_finishing = false
	_finished = false
	_visual_opacity = ProgressData.settings.projectile_opacity
	modulate.a = _visual_opacity
	visible = true

	_vortex_sprite.rotation = rand_range(-PI, PI)
	_vortex_sprite.scale = Vector2.ONE * 0.48
	_vortex_sprite.modulate.a = 0.08
	_vortex_echo_sprite.rotation = -_vortex_sprite.rotation
	_vortex_echo_sprite.scale = Vector2.ONE * 0.62
	_vortex_echo_sprite.modulate.a = 0.0
	_slash_sprite_1.visible = false
	_slash_sprite_2.visible = false
	_particles.emitting = false

	if is_instance_valid(target_unit):
		global_position = target_unit.global_position

	set_physics_process(true)
	_trigger_tick()


func _physics_process(delta: float) -> void:
	_visual_time += delta
	if is_instance_valid(target_unit) and not target_unit.dead and target_unit.current_stats.health > 0:
		global_position = target_unit.global_position
	elif not _finishing:
		_begin_finish()

	_update_ambient_wind(delta)
	_update_slashes(delta)

	if _finishing:
		_finish_delay -= delta
		_update_finish_vortex(delta)
		if _finish_delay <= 0.0:
			_finish()
		return

	_timer += delta
	if _timer >= tick_interval:
		_timer -= tick_interval
		_trigger_tick()


func _update_ambient_wind(delta: float) -> void:
	if _finishing:
		return
	_vortex_sprite.rotation += delta * 4.5
	var wind_wave: float = max(0.0, sin(_visual_time * 17.0) + 0.45 * sin(_visual_time * 31.0))
	var pulse: float = 0.46 + 0.045 * wind_wave
	_vortex_sprite.scale = Vector2(pulse, pulse * 0.88)
	_vortex_sprite.modulate.a = 0.045 + 0.13 * wind_wave
	_vortex_echo_sprite.modulate.a = 0.0


func _update_finish_vortex(delta: float) -> void:
	var progress: float = clamp(1.0 - _finish_delay / FINISH_DURATION, 0.0, 1.0)
	var gather: float = 1.0 - pow(1.0 - progress, 3.0)
	var collapse: float = pow(progress, 2.2)
	var scale_value: float = lerp(0.68, 0.07, collapse)
	var echo_scale: float = lerp(0.92, 0.03, pow(progress, 1.7))
	var finish_alpha: float = sin(progress * PI) * (1.0 - 0.35 * progress)

	_vortex_sprite.rotation += delta * lerp(9.0, 27.0, gather)
	_vortex_sprite.scale = Vector2(scale_value, scale_value * lerp(0.88, 1.0, gather))
	_vortex_sprite.modulate.a = finish_alpha * 0.82
	_vortex_echo_sprite.rotation -= delta * lerp(7.0, 21.0, gather)
	_vortex_echo_sprite.scale = Vector2(echo_scale, echo_scale * 0.86)
	_vortex_echo_sprite.modulate.a = finish_alpha * 0.32


func _update_slashes(delta: float) -> void:
	if _slash_1_time > 0.0:
		_slash_1_time -= delta
		var primary_fade: float = clamp(_slash_1_time / PRIMARY_SLASH_DURATION, 0.0, 1.0)
		_slash_sprite_1.modulate.a = primary_fade * primary_fade
		_slash_sprite_1.scale.x += delta * 3.2
		if _slash_1_time <= 0.0:
			_slash_sprite_1.visible = false

	if _slash_2_delay > 0.0:
		_slash_2_delay -= delta
		if _slash_2_delay <= 0.0:
			_slash_2_time = SECONDARY_SLASH_DURATION
			_slash_sprite_2.visible = true

	if _slash_2_time > 0.0:
		_slash_2_time -= delta
		var secondary_fade: float = clamp(_slash_2_time / SECONDARY_SLASH_DURATION, 0.0, 1.0)
		_slash_sprite_2.modulate.a = secondary_fade * secondary_fade * 0.9
		_slash_sprite_2.scale.x += delta * 2.8
		if _slash_2_time <= 0.0:
			_slash_sprite_2.visible = false


func _trigger_tick() -> void:
	if not is_instance_valid(target_unit) or target_unit.dead or target_unit.current_stats.health <= 0:
		_begin_finish()
		return

	_play_slash_vfx()

	var final_damage: float = float(damage_per_tick)
	var was_crit: bool = Utils.get_chance_success(crit_chance)
	if was_crit:
		final_damage *= crit_damage

	var health_before: int = target_unit.current_stats.health
	var damage_taken: Array = target_unit.take_damage(int(max(1, final_damage)), _damage_args)

	if damage_taken.size() > 1:
		RunData.add_weapon_dmg_dealt(weapon_pos, damage_taken[1], player_index)
		Utils.fa_apply_direct_crit_kill_gold_rewards(
			player_index,
			was_crit,
			health_before > 0 and damage_taken[1] >= health_before
		)

	remaining_ticks -= 1
	if remaining_ticks <= 0:
		_begin_finish()


func _play_slash_vfx() -> void:
	var base_angle: float = rand_range(-PI, PI)
	var primary_scale: float = rand_range(1.05, 1.28)
	var normal: Vector2 = Vector2.RIGHT.rotated(base_angle + PI / 2.0)

	_slash_sprite_1.rotation = base_angle
	_slash_sprite_1.position = normal * rand_range(-7.0, 7.0)
	_slash_sprite_1.scale = Vector2(primary_scale, primary_scale * 0.72)
	_slash_sprite_1.modulate.a = 1.0
	_slash_sprite_1.visible = true
	_slash_1_time = PRIMARY_SLASH_DURATION

	_slash_2_time = 0.0
	_slash_2_delay = 0.0
	_slash_sprite_2.visible = false
	if randf() < 0.58:
		var angle_offset: float = rand_range(0.75, 1.35)
		if randf() < 0.5:
			angle_offset = -angle_offset
		var secondary_scale: float = primary_scale * rand_range(0.78, 0.94)
		_slash_sprite_2.rotation = base_angle + angle_offset
		_slash_sprite_2.position = -normal * rand_range(2.0, 9.0)
		_slash_sprite_2.scale = Vector2(secondary_scale, secondary_scale * 0.68)
		_slash_sprite_2.modulate.a = 0.0
		_slash_2_delay = 0.025

	_particles.rotation = base_angle
	_particles.emitting = true
	_particles.restart()


func _begin_finish() -> void:
	if _finishing or _finished:
		return
	_finishing = true
	_finish_delay = FINISH_DURATION


func _finish() -> void:
	if _finished:
		return
	_finished = true
	set_physics_process(false)
	_particles.emitting = false
	visible = false
	target_unit = null
	_damage_args = null

	if is_instance_valid(_main):
		_main.add_node_to_pool(self, _pool_id)
	else:
		queue_free()
