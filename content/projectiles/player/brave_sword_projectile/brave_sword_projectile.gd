extends PlayerProjectile

const LASER_COUNT: int = 4
const LASER_HALF_LENGTH: float = 4000.0
const LASER_HALF_WIDTH: float = 56.0
const LASER_SPAWN_MIN_RADIUS: float = 35.0
const LASER_SPAWN_MAX_RADIUS: float = 185.0
const LASER_DURATION: float = 0.36

const WAVE_GROW_DURATION: float = 0.16
const WAVE_START_SCALE := Vector2(0.10, 0.12)
const WAVE_END_SCALE := Vector2(0.88, 1.38)
const WAVE_BASE_COLLISION_POS := Vector2(-27.0, -20.0)

var _is_laser_mode: bool = true
var _elapsed: float = 0.0
var _visual_opacity: float = 1.0
var _laser_transforms: Array = []
var _laser_visuals: Array = []
var _laser_collisions: Array = []
var _laser_damage_applied: bool = false

onready var _particles: CPUParticles2D = $"%CPUParticles2D" as CPUParticles2D
onready var _wave_collision: CollisionShape2D = $Hitbox/Collision as CollisionShape2D
onready var _laser_container: Node2D = $LaserContainer as Node2D


func _ready() -> void:
	._ready()
	_build_laser_nodes()


func _build_laser_nodes() -> void:
	_laser_visuals.clear()
	_laser_collisions.clear()

	var additive_mat := CanvasItemMaterial.new()
	additive_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD

	for i in range(LASER_COUNT):
		var beam_root := Node2D.new()
		beam_root.name = "LaserBeam%d" % i
		beam_root.visible = false
		_laser_container.add_child(beam_root)

		var outer_line := Line2D.new()
		outer_line.name = "OuterGlow"
		outer_line.width = LASER_HALF_WIDTH * 2.35
		outer_line.default_color = Color(1.0, 0.78, 0.18, 0.42)
		outer_line.material = additive_mat
		outer_line.points = PoolVector2Array([Vector2(-LASER_HALF_LENGTH, 0.0), Vector2(LASER_HALF_LENGTH, 0.0)])
		beam_root.add_child(outer_line)

		var mid_line := Line2D.new()
		mid_line.name = "MidBeam"
		mid_line.width = LASER_HALF_WIDTH * 1.45
		mid_line.default_color = Color(1.0, 0.92, 0.42, 0.78)
		mid_line.material = additive_mat
		mid_line.points = PoolVector2Array([Vector2(-LASER_HALF_LENGTH, 0.0), Vector2(LASER_HALF_LENGTH, 0.0)])
		beam_root.add_child(mid_line)

		var core_line := Line2D.new()
		core_line.name = "CoreBeam"
		core_line.width = LASER_HALF_WIDTH * 0.62
		core_line.default_color = Color(1.0, 0.99, 0.88, 0.98)
		core_line.material = additive_mat
		core_line.points = PoolVector2Array([Vector2(-LASER_HALF_LENGTH, 0.0), Vector2(LASER_HALF_LENGTH, 0.0)])
		beam_root.add_child(core_line)

		var cross_flare := Line2D.new()
		cross_flare.name = "CrossFlare"
		cross_flare.width = 24.0
		cross_flare.default_color = Color(1.0, 0.96, 0.72, 0.85)
		cross_flare.material = additive_mat
		cross_flare.points = PoolVector2Array([Vector2(0.0, -LASER_HALF_WIDTH * 1.9), Vector2(0.0, LASER_HALF_WIDTH * 1.9)])
		beam_root.add_child(cross_flare)

		_laser_visuals.push_back(beam_root)

		var col := CollisionShape2D.new()
		col.name = "LaserCollision%d" % i
		var rect := RectangleShape2D.new()
		rect.extents = Vector2(LASER_HALF_LENGTH, LASER_HALF_WIDTH)
		col.shape = rect
		col.disabled = true
		_hitbox.add_child(col)
		_laser_collisions.push_back(col)


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
	_elapsed = 0.0
	_laser_damage_applied = false

	_is_laser_mode = true
	if is_instance_valid(p_from):
		var current_shot: int = int(p_from.get("_nb_shots_taken")) if p_from.get("_nb_shots_taken") != null else -1
		var last_shot: int = int(p_from.get_meta("fa_brave_sword_last_shot", -1))
		var current_mode_is_laser: bool = bool(p_from.get_meta("fa_brave_sword_is_laser", false))
		if current_shot != last_shot or last_shot == -1:
			current_mode_is_laser = not current_mode_is_laser
			p_from.set_meta("fa_brave_sword_is_laser", current_mode_is_laser)
			p_from.set_meta("fa_brave_sword_last_shot", current_shot)
		_is_laser_mode = current_mode_is_laser

	var actual_spawn_pos: Vector2 = pos
	if _is_laser_mode:
		if is_instance_valid(p_from) and is_instance_valid(p_from.get("_parent")):
			actual_spawn_pos = p_from._parent.global_position
		elif is_instance_valid(p_from):
			actual_spawn_pos = p_from.global_position
		p_velocity = Vector2.ZERO
		p_rotation = 0.0
	else:
		if is_instance_valid(p_from):
			actual_spawn_pos = p_from.global_position + Vector2(18.0, 0.0).rotated(p_rotation)

	.shoot_ex(
		p_from,
		actual_spawn_pos,
		p_velocity,
		p_rotation,
		p_weapon_stats,
		damage_tracking_key,
		effects,
		hitbox_args,
		knockback_direction
	)


func shoot() -> void:
	.shoot()
	_visual_opacity = ProgressData.settings.projectile_opacity
	_piercing = 9999
	_bounce = 0

	if _is_laser_mode:
		destroy_on_leaving_screen = false
		_time_until_max_range = LASER_DURATION
		_sprite.visible = false
		if is_instance_valid(_particles):
			_particles.emitting = false
			_particles.visible = false
		if is_instance_valid(_wave_collision):
			_wave_collision.set_deferred("disabled", true)
		_setup_lasers()
	else:
		destroy_on_leaving_screen = true
		_sprite.visible = true
		_sprite.modulate = Color(1.0, 1.0, 1.0, _visual_opacity)
		_sprite.scale = WAVE_START_SCALE
		if is_instance_valid(_particles):
			_particles.visible = true
			_particles.modulate.a = _visual_opacity
			_particles.scale = WAVE_START_SCALE
			_particles.emitting = true
			_particles.restart()
		if is_instance_valid(_wave_collision):
			_wave_collision.position = WAVE_BASE_COLLISION_POS * WAVE_START_SCALE
			_wave_collision.scale = WAVE_START_SCALE
			_wave_collision.set_deferred("disabled", false)
		_disable_lasers()


func _setup_lasers() -> void:
	_laser_transforms.clear()
	var base_angle: float = rand_range(0.0, PI)
	var angle_step: float = PI / float(LASER_COUNT)

	for i in range(LASER_COUNT):
		var offset_angle: float = rand_range(0.0, TAU)
		var offset_dist: float = rand_range(LASER_SPAWN_MIN_RADIUS, LASER_SPAWN_MAX_RADIUS)
		var local_pos: Vector2 = Vector2.RIGHT.rotated(offset_angle) * offset_dist
		var beam_angle: float = base_angle + float(i) * angle_step + rand_range(-0.28, 0.28)

		_laser_transforms.push_back({
			"local_pos": local_pos,
			"world_pos": global_position + local_pos,
			"angle": beam_angle,
			"dir": Vector2.RIGHT.rotated(beam_angle)
		})

		var beam_root: Node2D = _laser_visuals[i]
		beam_root.position = local_pos
		beam_root.rotation = beam_angle
		beam_root.scale = Vector2(1.0, 0.15)
		beam_root.modulate = Color(1.0, 1.0, 1.0, _visual_opacity)
		beam_root.visible = true

		var col: CollisionShape2D = _laser_collisions[i]
		col.position = local_pos
		col.rotation = beam_angle
		col.set_deferred("disabled", false)


func _disable_lasers() -> void:
	for i in range(_laser_visuals.size()):
		_laser_visuals[i].visible = false
		_laser_collisions[i].set_deferred("disabled", true)


func _physics_process(delta: float) -> void:
	if _enable_stop_delay:
		return

	_elapsed += delta

	if _is_laser_mode:
		_process_laser_mode(delta)
	else:
		_process_wave_mode(delta)


func _process_laser_mode(_delta: float) -> void:
	if not _laser_damage_applied:
		_laser_damage_applied = true
		_damage_enemies_in_lasers()

	var progress: float = clamp(_elapsed / LASER_DURATION, 0.0, 1.0)
	var width_scale: float = 1.0
	var alpha_mult: float = 1.0

	if progress < 0.16:
		var t_in: float = progress / 0.16
		width_scale = lerp(0.18, 1.18, 1.0 - pow(1.0 - t_in, 3.0))
		alpha_mult = clamp(t_in * 1.4, 0.0, 1.0)
	elif progress < 0.52:
		var pulse: float = 1.0 + 0.10 * sin(_elapsed * 55.0)
		width_scale = pulse
		alpha_mult = 1.0
	else:
		var t_out: float = (progress - 0.52) / 0.48
		width_scale = lerp(1.0, 0.02, pow(t_out, 1.6))
		alpha_mult = 1.0 - pow(t_out, 1.4)

	for i in range(_laser_visuals.size()):
		var beam_root: Node2D = _laser_visuals[i]
		beam_root.scale = Vector2(1.0, max(0.01, width_scale))
		beam_root.modulate.a = _visual_opacity * alpha_mult

	if _elapsed >= LASER_DURATION:
		stop()


func _damage_enemies_in_lasers() -> void:
	var main = Utils.get_scene_node()
	if main == null or not is_instance_valid(main) or main.get("_entity_spawner") == null:
		return

	var spawner = main._entity_spawner
	if spawner == null or not is_instance_valid(spawner):
		return

	var all_enemies: Array = spawner.get_all_enemies()
	for enemy in all_enemies:
		if not is_instance_valid(enemy) or enemy.dead or _hitbox.ignored_objects.has(enemy):
			continue

		var enemy_pos: Vector2 = enemy.global_position
		var hit_by_laser: bool = false
		for beam in _laser_transforms:
			var rel: Vector2 = enemy_pos - beam.world_pos
			var along: float = abs(rel.dot(beam.dir))
			if along > LASER_HALF_LENGTH:
				continue
			var perp: float = abs(rel.cross(beam.dir))
			if perp <= LASER_HALF_WIDTH + 28.0:
				hit_by_laser = true
				break

		if hit_by_laser and enemy.has_method("hurt_area_entered_deferred"):
			enemy.call_deferred("hurt_area_entered_deferred", _hitbox)


func _process_wave_mode(_delta: float) -> void:
	var grow_t: float = clamp(_elapsed / WAVE_GROW_DURATION, 0.0, 1.0)
	var eased: float = 1.0 - pow(1.0 - grow_t, 3.0)
	var current_scale: Vector2 = WAVE_START_SCALE.linear_interpolate(WAVE_END_SCALE, eased)

	_sprite.scale = current_scale
	if is_instance_valid(_particles):
		_particles.scale = current_scale
	if is_instance_valid(_wave_collision):
		_wave_collision.position = WAVE_BASE_COLLISION_POS * current_scale
		_wave_collision.scale = current_scale


func set_sprite_material(_material: ShaderMaterial) -> void:
	pass


func stop() -> void:
	if _enable_stop_delay:
		return
	_disable_lasers()
	if is_instance_valid(_particles):
		_particles.emitting = false
	.stop()


func _return_to_pool() -> void:
	_disable_lasers()
	if is_instance_valid(_particles):
		_particles.emitting = false
	_sprite.scale = Vector2.ONE
	if is_instance_valid(_wave_collision):
		_wave_collision.position = WAVE_BASE_COLLISION_POS
		_wave_collision.scale = Vector2.ONE
	var saved_mat = _sprite.material
	._return_to_pool()
	_sprite.material = saved_mat
