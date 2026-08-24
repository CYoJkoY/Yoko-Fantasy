extends "res://mods-unpacked/Yoko-Fantasy/content/projectiles/player/micro_homing_player_projectile.gd"

const HIT_SPLASH_SCENE = preload("res://mods-unpacked/Yoko-Fantasy/content/projectiles/player/myriad_flourish_projectile/myriad_flourish_hit_splash.tscn")
const PETAL_DART_SCENE = preload("res://mods-unpacked/Yoko-Fantasy/content/projectiles/player/myriad_flourish_projectile/myriad_flourish_petal.tscn")
const MYRIAD_FLOURISH_EFFECT = preload("res://mods-unpacked/Yoko-Fantasy/content/weapons/ranged/myriad_flourish/myriad_flourish_effect.gd")
const DEFAULT_PETAL_COUNT: int = 3
const DEFAULT_PETAL_DAMAGE_RATIO: float = 0.45
const DEFAULT_SLOW_PERCENT: float = 35.0

const HOMING_TURN_RATE: float = 1.4
const HOMING_MAX_RANGE: float = 420.0
const HOMING_FOV_DEG: float = 35.0
const HOMING_RELEASE_FOV_DEG: float = 55.0

var base_petal_count: int = DEFAULT_PETAL_COUNT
var petal_damage_ratio: float = DEFAULT_PETAL_DAMAGE_RATIO
var slow_percent: float = DEFAULT_SLOW_PERCENT
export (int) var num_trail_points: int = 12
export (float) var trail_spacing: float = 6.0

var _elapsed_time: float = 0.0
var _history_positions: Array = []

onready var _orb_root: Node2D = $"%OrbRoot" as Node2D
onready var _glow_aura: Sprite = $"%GlowAura" as Sprite
onready var _inner_fluid: Sprite = $"%InnerFluid" as Sprite
onready var _outer_fluid: Sprite = $"%OuterFluid" as Sprite
onready var _vitality_swirl: Sprite = $"%VitalitySwirl" as Sprite
onready var _sprout_crest: Sprite = $"%SproutCrest" as Sprite
onready var _specular: Sprite = $"%Specular" as Sprite
onready var _trail_line: Line2D = $"%TrailLine" as Line2D
onready var _sparkle_particles: CPUParticles2D = $"%SparkleParticles" as CPUParticles2D
onready var _leaf_particles: CPUParticles2D = $"%LeafParticles" as CPUParticles2D


func _ready() -> void:
	_init_trail_points()


func _init_trail_points() -> void:
	if not is_instance_valid(_trail_line):
		return
	_trail_line.clear_points()
	for _i in range(num_trail_points):
		_trail_line.add_point(Vector2.ZERO)


func shoot_ex(
	p_from: Node,
	pos: Vector2,
	p_velocity: Vector2,
	p_rotation: float,
	p_weapon_stats: WeaponStats,
	damage_tracking_key: int,
	effects: Array,
	hitbox_args: Hitbox.HitboxArgs,
	knockback_direction: Vector2
) -> void:
	_configure_effect(effects)

	_elapsed_time = rand_range(0.0, 10.0)
	_history_positions.clear()
	_history_positions.push_back(pos)
	_init_trail_points()

	.shoot_ex(p_from, pos, p_velocity, p_rotation, p_weapon_stats, damage_tracking_key, effects, hitbox_args, knockback_direction)


func _configure_effect(effects: Array) -> void:
	base_petal_count = DEFAULT_PETAL_COUNT
	petal_damage_ratio = DEFAULT_PETAL_DAMAGE_RATIO
	slow_percent = DEFAULT_SLOW_PERCENT
	for effect in effects:
		if effect != null and effect.get_script() == MYRIAD_FLOURISH_EFFECT:
			base_petal_count = effect.petal_count
			petal_damage_ratio = float(effect.petal_damage_percent) / 100.0
			slow_percent = effect.slow_percent
			return


func shoot() -> void:
	.shoot()
	var opacity = ProgressData.settings.projectile_opacity
	_orb_root.modulate.a = opacity
	_trail_line.modulate.a = opacity
	_sparkle_particles.modulate.a = opacity
	_sparkle_particles.emitting = true
	_sparkle_particles.restart()
	_leaf_particles.modulate.a = opacity
	_leaf_particles.emitting = true
	_leaf_particles.restart()


func _physics_process(delta: float) -> void:
	if _enable_stop_delay:
		return

	_elapsed_time += delta
	var t = _elapsed_time

	_process_micro_homing(delta, HOMING_TURN_RATE, HOMING_MAX_RANGE, HOMING_FOV_DEG, HOMING_RELEASE_FOV_DEG)

	_inner_fluid.rotation -= delta * (3.8 + 1.8 * sin(t * 5.0))
	_outer_fluid.rotation += delta * (4.8 + 2.2 * cos(t * 4.5))
	_vitality_swirl.rotation += delta * (2.8 + 1.2 * sin(t * 6.0))

	_inner_fluid.scale = Vector2(1.0 + 0.07 * sin(t * 7.0), 1.0 - 0.07 * sin(t * 7.0))
	_outer_fluid.scale = Vector2(1.0 - 0.06 * cos(t * 6.0), 1.0 + 0.06 * cos(t * 6.0))
	_inner_fluid.position = Vector2(cos(t * 6.0) * 1.5, sin(t * 5.0) * 1.5)
	_outer_fluid.position = Vector2(sin(t * 5.5) * -1.5, cos(t * 6.5) * 1.5)

	_vitality_swirl.modulate.a = 0.7 + 0.3 * sin(t * 9.0)
	_vitality_swirl.scale = Vector2.ONE * (1.0 + 0.1 * sin(t * 8.0))
	_sprout_crest.scale = Vector2.ONE * (0.75 + 0.12 * sin(t * 7.0))

	var glow_pulse = 1.0 + 0.1 * sin(t * 9.0)
	_glow_aura.scale = Vector2.ONE * glow_pulse
	_glow_aura.modulate.a = 0.75 + 0.25 * sin(t * 11.0)

	_specular.position = Vector2(cos(t * 3.5) * 1.8, sin(t * 3.0) * 1.8)

	var breath = 0.52 + 0.03 * sin(t * 8.0)
	_orb_root.scale = Vector2.ONE * breath
	_orb_root.position.y = sin(t * 14.0) * 2.0

	_history_positions.push_front(global_position)
	_update_trail_line()


func _update_trail_line() -> void:
	if _history_positions.size() < 2:
		return

	_trail_line.set_point_position(0, Vector2.ZERO)
	var available_dist: float = 0.0
	var req_dist: float = (num_trail_points - 1) * trail_spacing

	for i in range(1, _history_positions.size()):
		available_dist += (_history_positions[i] - _history_positions[i - 1]).length()
		if available_dist >= req_dist:
			_history_positions.resize(i + 1)
			break

	var h_idx: int = 1
	var prev_dist: float = 0.0
	var cur_dist: float = (_history_positions[1] - _history_positions[0]).length()

	for pt_idx in range(1, num_trail_points):
		var target_d = pt_idx * trail_spacing
		if available_dist <= 0.001:
			_trail_line.set_point_position(pt_idx, Vector2.ZERO)
			continue

		var clamped_d = min(target_d, available_dist)
		while h_idx < _history_positions.size() - 1 and cur_dist < clamped_d:
			h_idx += 1
			prev_dist = cur_dist
			cur_dist += (_history_positions[h_idx] - _history_positions[h_idx - 1]).length()

		var prog = (clamped_d - prev_dist) / max(0.0001, cur_dist - prev_dist)
		var world_pt = _history_positions[h_idx - 1].linear_interpolate(_history_positions[h_idx], prog)
		_trail_line.set_point_position(pt_idx, to_local(world_pt))


func _on_Hitbox_hit_something(thing_hit: Node, damage_dealt: int) -> void:
	var weapon_pos: int = _hitbox.from.weapon_pos
	._on_Hitbox_hit_something(thing_hit, damage_dealt)

	var main = Utils.get_scene_node()
	if main == null:
		return

	var splash_pool_id: int = HIT_SPLASH_SCENE.get_instance_id()
	var splash = main.get_node_from_pool(splash_pool_id, main._effects)
	if splash == null:
		splash = HIT_SPLASH_SCENE.instance()
		main.add_effect(splash)
		splash.set_meta("pool_id", splash_pool_id)
	splash.play(global_position, main, splash_pool_id)

	var nearby_targets = ChainTargetService.collect_nearby_enemies(
		main,
		global_position,
		[thing_hit],
		360.0,
		base_petal_count
	)

	var petal_pool_id: int = PETAL_DART_SCENE.get_instance_id()
	var angle_step = TAU / float(base_petal_count)
	var base_angle = rand_range(0, TAU)
	var petal_dmg: int = max(1, int(float(damage_dealt) * petal_damage_ratio))
	var crit_ch: float = _weapon_stats.crit_chance if _weapon_stats != null else 0.05
	var crit_dmg: float = _weapon_stats.crit_damage if _weapon_stats != null else 1.5
	var slowed_target_ids: Dictionary = {}

	for i in range(base_petal_count):
		var dart = main.get_node_from_pool(petal_pool_id, main._effects)
		if dart == null:
			dart = PETAL_DART_SCENE.instance()
			main.add_effect(dart)
			dart.set_meta("pool_id", petal_pool_id)

		var spread_dir = Vector2.RIGHT.rotated(base_angle + i * angle_step)
		var assigned_target = nearby_targets[i % nearby_targets.size()] if not nearby_targets.empty() else null
		var apply_slow: bool = assigned_target != null and !slowed_target_ids.has(assigned_target.get_instance_id())
		if apply_slow:
			slowed_target_ids[assigned_target.get_instance_id()] = true

		dart.launch(
			global_position,
			spread_dir,
			assigned_target,
			petal_dmg,
			player_index,
			weapon_pos,
			crit_ch,
			crit_dmg,
			slow_percent,
			apply_slow,
			main,
			petal_pool_id
		)


func stop() -> void:
	.stop()
	_sparkle_particles.emitting = false
	_leaf_particles.emitting = false


func _return_to_pool() -> void:
	._return_to_pool()
	_sparkle_particles.emitting = false
	_leaf_particles.emitting = false
	_history_positions.clear()
	_elapsed_time = 0.0
	_inner_fluid.rotation = 0.0
	_inner_fluid.scale = Vector2.ONE
	_inner_fluid.position = Vector2.ZERO
	_outer_fluid.rotation = 0.0
	_outer_fluid.scale = Vector2.ONE
	_outer_fluid.position = Vector2.ZERO
	_vitality_swirl.rotation = 0.0
	_orb_root.scale = Vector2.ONE * 0.52
	_orb_root.position = Vector2.ZERO
	_init_trail_points()
