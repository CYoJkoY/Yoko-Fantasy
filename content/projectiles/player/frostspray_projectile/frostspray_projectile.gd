extends "res://mods-unpacked/Yoko-Fantasy/content/projectiles/player/micro_homing_player_projectile.gd"

const HIT_SPLASH_SCENE = preload("res://mods-unpacked/Yoko-Fantasy/content/projectiles/player/frostspray_projectile/frostspray_hit_splash.tscn")
const SHARD_SCENE = preload("res://mods-unpacked/Yoko-Fantasy/content/projectiles/player/frostspray_projectile/frostspray_shard.tscn")
const FROSTSPRAY_EFFECT = preload("res://mods-unpacked/Yoko-Fantasy/content/weapons/ranged/frostspray/frostspray_effect.gd")

const DEFAULT_SHARD_COUNT: int = 4
const DEFAULT_SHARD_DAMAGE_RATIO: float = 0.45
const TOTAL_SPREAD_DEG: float = 45.0

const HOMING_TURN_RATE: float = 2.0
const HOMING_MAX_RANGE: float = 480.0
const HOMING_FOV_DEG: float = 45.0
const HOMING_RELEASE_FOV_DEG: float = 70.0

export (int) var num_trail_points: int = 12
export (float) var trail_spacing: float = 6.0

var shard_count: int = DEFAULT_SHARD_COUNT
var shard_damage_ratio: float = DEFAULT_SHARD_DAMAGE_RATIO

var _elapsed_time: float = 0.0
var _history_positions: Array = []
var _clean_velocity: Vector2 = Vector2.ZERO

onready var _visual_root: Node2D = $"%VisualRoot" as Node2D
onready var _glow_aura: Sprite = $"%GlowAura" as Sprite
onready var _crystal_mesh: Sprite = $"%CrystalMesh" as Sprite
onready var _tip_shimmer: Sprite = $"%TipShimmer" as Sprite
onready var _trail_line: Line2D = $"%TrailLine" as Line2D
onready var _sparkle_particles: CPUParticles2D = $"%SparkleParticles" as CPUParticles2D


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
	p_weapon_stats,
	damage_tracking_key: int,
	effects: Array,
	hitbox_args: Hitbox.HitboxArgs,
	knockback_direction: Vector2
) -> void:
	_configure_effects(effects)
	_elapsed_time = 0.0
	_history_positions.clear()
	_history_positions.push_back(pos)
	_init_trail_points()
	_clean_velocity = p_velocity

	.shoot_ex(p_from, pos, p_velocity, p_rotation, p_weapon_stats, damage_tracking_key, effects, hitbox_args, knockback_direction)


func _configure_effects(effects: Array) -> void:
	shard_count = DEFAULT_SHARD_COUNT
	shard_damage_ratio = DEFAULT_SHARD_DAMAGE_RATIO
	for effect in effects:
		if effect != null and effect.get_script() == FROSTSPRAY_EFFECT:
			shard_count = effect.shard_count
			shard_damage_ratio = float(effect.shard_damage_percent) / 100.0
			return


func shoot() -> void:
	.shoot()
	var opacity = ProgressData.settings.projectile_opacity
	_visual_root.modulate.a = opacity
	_trail_line.modulate.a = opacity
	_sparkle_particles.modulate.a = opacity
	_sparkle_particles.emitting = true
	_sparkle_particles.restart()


func _physics_process(delta: float) -> void:
	if _enable_stop_delay:
		return

	_elapsed_time += delta
	var t = _elapsed_time

	_process_micro_homing(delta, HOMING_TURN_RATE, HOMING_MAX_RANGE, HOMING_FOV_DEG, HOMING_RELEASE_FOV_DEG)
	_clean_velocity = velocity

	var spawn_pop = clamp(t / 0.08, 0.3, 1.0)
	var breath = (0.70 + 0.03 * sin(t * 9.0)) * spawn_pop
	_visual_root.scale = Vector2.ONE * breath

	var glow_pulse = 1.0 + 0.08 * sin(t * 8.0)
	_glow_aura.scale = Vector2.ONE * glow_pulse
	_glow_aura.modulate.a = 0.8 + 0.2 * cos(t * 9.0)

	var shimmer_scale = 0.5 + 0.18 * sin(t * 15.0)
	_tip_shimmer.scale = Vector2.ONE * shimmer_scale
	_tip_shimmer.modulate.a = 0.85 + 0.15 * cos(t * 18.0)

	_crystal_mesh.modulate.a = 0.88 + 0.12 * sin(t * 7.5)

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

	var impact_dir: Vector2 = _clean_velocity
	if impact_dir.length_squared() < 100.0:
		impact_dir = Vector2.RIGHT.rotated(rotation)
	var hit_angle: float = impact_dir.angle()

	var shard_pool_id: int = SHARD_SCENE.get_instance_id()
	var shard_dmg: int = int(max(1, float(_hitbox.damage) * shard_damage_ratio))
	var crit_ch: float = _weapon_stats.crit_chance if _weapon_stats != null else 0.05
	var crit_dmg: float = _weapon_stats.crit_damage if _weapon_stats != null else 1.5

	var total_spread_rad: float = deg2rad(TOTAL_SPREAD_DEG)
	var half_spread: float = total_spread_rad / 2.0
	var count: int = shard_count

	var sector_size: float = total_spread_rad / float(max(1, count))
	var indices = []
	for i in range(count):
		indices.append(i)
	indices.shuffle()

	for i in range(count):
		var shard = main.get_node_from_pool(shard_pool_id, main._effects)
		if shard == null:
			shard = SHARD_SCENE.instance()
			main.add_effect(shard)
			shard.set_meta("pool_id", shard_pool_id)

		var sector_idx = indices[i]
		var min_ang = -half_spread + sector_idx * sector_size
		var max_ang = min_ang + sector_size
		var angle_offset = rand_range(min_ang, max_ang)
		angle_offset += rand_range(deg2rad(-2.5), deg2rad(2.5))
		var shard_dir = Vector2.RIGHT.rotated(hit_angle + angle_offset)

		var depth_tier: int = i % 3

		shard.launch_advanced(
			global_position,
			shard_dir,
			shard_dmg,
			player_index,
			weapon_pos,
			crit_ch,
			crit_dmg,
			depth_tier,
			main,
			shard_pool_id
		)


func stop() -> void:
	.stop()
	_sparkle_particles.emitting = false


func _return_to_pool() -> void:
	._return_to_pool()
	_sparkle_particles.emitting = false
	_history_positions.clear()
	_elapsed_time = 0.0
	_clean_velocity = Vector2.ZERO
	_visual_root.scale = Vector2.ONE * 0.70
	_init_trail_points()
