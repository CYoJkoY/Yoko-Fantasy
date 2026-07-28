extends Node2D
# Guard Blade Satellite — encapsulated version using internal class for state.

const FlyingBladeMotion = preload("res://mods-unpacked/Yoko-Fantasy/content/entities/pets/flying_blade/motion_math.gd")
const CombatCoordinator = preload("res://mods-unpacked/Yoko-Fantasy/content/entities/pets/flying_blade/combat_coordinator.gd")

const ROLE := "satellite"

# 内部类：状态上下文
class SatelliteContext:
	var orbit_angle_offset: float = 0.0
	var attack_start := Vector2()
	var attack_control := Vector2()
	var attack_end := Vector2()
	var attack_direction := Vector2.RIGHT
	var return_start := Vector2()
	var return_control := Vector2()
	var return_end := Vector2()
	var velocity := Vector2.ZERO
	var target: Node2D = null
	
	var state_ticks: float = 0.0
	var cooldown: float = 0.0
	var formation_index: int = 0
	var formation_count: int = 1
	
	var attack_slot_active: bool = false
	var attack_queued: bool = false
	var hitbox_enabled: bool = false
	
	func reset() -> void:
		attack_start = Vector2()
		attack_control = Vector2()
		attack_end = Vector2()
		attack_direction = Vector2.RIGHT
		return_start = Vector2()
		return_control = Vector2()
		return_end = Vector2()
		velocity = Vector2.ZERO
		target = null
		state_ticks = 0.0
		attack_slot_active = false
		hitbox_enabled = false

enum SatelliteState { ORBIT, ATTACK, RETURN }

var owner_pet: Node = null
var combat_coordinator: CombatCoordinator = null
var player_index: int = -1
var players_ref: Array = []
var weapon_stats: MeleeWeaponStats = null
var damage_tracking_key_hash: int = Keys.empty_hash
var _tuning: Resource = null

# 使用上下文对象替代散落的变量
var _ctx: SatelliteContext = SatelliteContext.new()

var _state: int = SatelliteState.ORBIT
var _initialized: bool = false

var _body: Sprite = null
var _hitbox: Hitbox = null
var _hitbox_collision: CollisionShape2D = null
var _hitbox_shape: RectangleShape2D = null
var _trail_line: Line2D = null
var _fragment_particles: Particles2D = null

# 运行时参数（从tuning读取）
var orbit_radius: float = 100.0
var orbit_speed: float = 3.4
var attack_range: float = 200.0
var attack_cooldown_ticks: float = 90.0
var attack_ticks: float = 8.0
var return_ticks: float = 10.0
var attack_distance: float = 34.0
var hitbox_length: float = 82.0
var hitbox_width: float = 20.0
var knockback: float = 5.0
var orbit_radius_offset: float = 28.0

func setup(config: Dictionary) -> void:
	owner_pet = config["owner"]
	combat_coordinator = config["coordinator"]
	player_index = config["player_index"]
	players_ref = config["players_ref"]
	weapon_stats = config["weapon_stats"]
	damage_tracking_key_hash = config["damage_tracking_key_hash"]
	_tuning = config["tuning"]
	
	# 加载参数
	orbit_radius = _tuning.guard_radius
	orbit_speed = _tuning.guard_orbit_speed
	attack_range = _tuning.satellite_attack_range
	attack_cooldown_ticks = _tuning.satellite_attack_cooldown_ticks
	attack_ticks = _tuning.satellite_attack_ticks
	return_ticks = _tuning.satellite_return_ticks
	attack_distance = _tuning.satellite_attack_distance
	hitbox_length = _tuning.satellite_hitbox_length
	hitbox_width = _tuning.satellite_hitbox_width
	knockback = _tuning.satellite_knockback
	orbit_radius_offset = _tuning.satellite_orbit_radius_offset
	
	_setup_visual(config["texture"], config["centered"], config["offset"], config["flip_h"], config["flip_v"])
	_setup_hitbox()
	_apply_weapon_stats()
	
	_ctx.cooldown = rand_range(0.5, 1.5)
	global_position = _get_orbit_position()
	_initialized = true
	
	combat_coordinator.register_satellite(self)

func _setup_visual(texture: Texture, centered: bool, offset: Vector2, flip_h: bool, flip_v: bool) -> void:
	_body = Sprite.new()
	_body.texture = texture
	_body.centered = centered
	_body.offset = offset
	_body.flip_h = flip_h
	_body.flip_v = flip_v
	_body.scale = Vector2(0.72, 0.72)
	_body.modulate = Color(1.2, 1.0, 1.4, 0.55)
	add_child(_body)
	
	_trail_line = Line2D.new()
	_trail_line.width = _tuning.trail_line_width * 0.6
	_trail_line.set_as_toplevel(true)
	_trail_line.global_position = Vector2.ZERO
	var grad := Gradient.new()
	grad.colors = [_tuning.trail_gradient_top, _tuning.trail_gradient_bottom]
	grad.offsets = [0.0, 1.0]
	_trail_line.gradient = grad
	_trail_line.z_index = 18
	var tc := Curve.new()
	tc.add_point(Vector2(0, 0))
	tc.add_point(Vector2(0.4, 0.6))
	tc.add_point(Vector2(0.8, 1.0))
	tc.add_point(Vector2(1, 1))
	_trail_line.width_curve = tc
	_trail_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_trail_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(_trail_line)
	
	_fragment_particles = Particles2D.new()
	_fragment_particles.amount = 6
	_fragment_particles.lifetime = 0.15
	_fragment_particles.one_shot = true
	_fragment_particles.emitting = false
	_fragment_particles.z_index = 22
	var mat := ParticlesMaterial.new()
	mat.color = Color(0.6, 0.4, 0.9, 0.5)
	mat.scale = 1.5
	mat.initial_velocity = 80
	mat.damping = 0.9
	mat.gravity = Vector3.ZERO
	mat.flag_disable_z = true
	_fragment_particles.process_material = mat
	add_child(_fragment_particles)

func _setup_hitbox() -> void:
	_hitbox = Hitbox.new()
	_hitbox.name = "Hitbox"
	_hitbox.collision_layer = Utils.PET_PROJECTILES_BIT
	_hitbox.collision_mask = 0
	_hitbox.from = owner_pet
	_hitbox.damage_tracking_key_hash = damage_tracking_key_hash
	_hitbox.active = false
	_hitbox.set_as_toplevel(true)
	_hitbox_collision = CollisionShape2D.new()
	_hitbox_collision.name = "Collision"
	_hitbox_shape = RectangleShape2D.new()
	_hitbox_shape.extents = Vector2(hitbox_length * 0.5, hitbox_width * 0.5)
	_hitbox_collision.shape = _hitbox_shape
	_hitbox_collision.disabled = true
	_hitbox.add_child(_hitbox_collision)
	add_child(_hitbox)
	_hitbox.connect("hit_something", self, "_on_Hitbox_hit_something")

func _apply_weapon_stats() -> void:
	weapon_stats.burning_data.from = owner_pet
	var hitbox_args := Hitbox.HitboxArgs.new().set_from_weapon_stats(weapon_stats)
	_hitbox.projectiles_on_hit = []
	_hitbox.effect_scale = weapon_stats.effect_scale
	_hitbox.speed_percent_modifier = weapon_stats.speed_percent_modifier
	_hitbox.from = owner_pet
	_hitbox.damage_tracking_key_hash = damage_tracking_key_hash
	_hitbox.set_damage(weapon_stats.damage, hitbox_args)

func sync_weapon_stats(stats: MeleeWeaponStats) -> void:
	weapon_stats = stats
	_apply_weapon_stats()

func _physics_process(delta: float) -> void:
	if not _initialized: return
	# 简化检查：如果 owner_pet 不在场景树中（通常意味着已被删除），则 shutdown
	if not owner_pet or not is_instance_valid(owner_pet) or owner_pet.dead:
		shutdown()
		return
	
	var ticks := Utils.physics_one(delta)
	_ctx.cooldown -= ticks
	_ctx.state_ticks += ticks
	
	match _state:
		SatelliteState.ORBIT:
			_process_orbit(delta)
		SatelliteState.ATTACK:
			_process_attack(delta)
		SatelliteState.RETURN:
			_process_return(delta)
	
	_update_trail()

func _get_actual_orbit_radius() -> float:
	return orbit_radius + _ctx.formation_index * orbit_radius_offset

func _get_current_angle() -> float:
	var base := combat_coordinator.get_orbit_phase(orbit_speed) if combat_coordinator else (OS.get_ticks_msec() / 1000.0) * orbit_speed * 0.72
	return base + float(_ctx.formation_index) * (TAU / float(max(_ctx.formation_count, 1)))

func _get_orbit_position() -> Vector2:
	var angle := _get_current_angle()
	var r := _get_actual_orbit_radius()
	var offset := Vector2(cos(angle) * r, sin(angle) * r * 0.46)
	return FlyingBladeMotion.clamp_to_zone(_get_player_position() + offset)

func _get_orbit_rotation() -> float:
	var angle := _get_current_angle()
	return Vector2(-sin(angle), cos(angle) * 0.46).angle() - PI / 2

func _process_orbit(delta: float) -> void:
	_trail_line.clear_points()
	var target_pos := _get_orbit_position()
	var t := 1.0 - exp(-10.0 * delta)
	global_position = global_position.linear_interpolate(target_pos, t)
	_ctx.velocity = (global_position - target_pos) / max(delta, 0.001)
	_body.rotation = lerp_angle(_body.rotation, _get_orbit_rotation(), 0.2)
	
	var angle := _get_current_angle()
	_body.modulate.a = 0.1 + 0.4 * (0.5 + 0.5 * sin(angle * 2.0))
	
	if _ctx.cooldown <= 0.0 and not _ctx.attack_queued and not _ctx.attack_slot_active:
		_enqueue_coordinated_attack()

func _process_attack(delta: float) -> void:
	if not _ctx.target or _ctx.target.dead:
		_retarget_lost_attack()
		return
	
	var raw := min(_ctx.state_ticks / max(attack_ticks, 1.0), 1.0)
	var progress := FlyingBladeMotion.ease_out_cubic(raw)
	var prev := global_position
	global_position = FlyingBladeMotion.clamp_to_zone(FlyingBladeMotion.bezier2(_ctx.attack_start, _ctx.attack_control, _ctx.attack_end, progress))
	_ctx.velocity = (global_position - prev) / max(delta, 0.001)
	_ctx.attack_direction = prev.direction_to(global_position)
	if _ctx.attack_direction.length_squared() <= 0.1:
		_ctx.attack_direction = prev.direction_to(_ctx.target.global_position)
	
	_body.rotation = lerp_angle(_body.rotation, _ctx.attack_direction.angle() - PI / 2, 0.3)
	
	var angle := _get_current_angle()
	_body.modulate.a = 0.4 + (0.5 + 0.3 * sin(angle * 2.0)) * 0.25
	
	_position_hitbox(prev, global_position)
	
	if raw >= 0.18 and not _ctx.hitbox_enabled:
		_enable_hitbox()
	if raw > 0.1 and raw < 0.9:
		_emit_attack_fragment()
		
	if _ctx.state_ticks >= attack_ticks:
		_begin_return()

func _process_return(delta: float) -> void:
	_ctx.return_end = _get_orbit_position()
	var progress := FlyingBladeMotion.ease_out_cubic(min(_ctx.state_ticks / max(return_ticks, 1.0), 1.0))
	var prev := global_position
	global_position = FlyingBladeMotion.clamp_to_zone(FlyingBladeMotion.bezier2(_ctx.return_start, _ctx.return_control, _ctx.return_end, progress))
	_ctx.velocity = (global_position - prev) / max(delta, 0.001)
	var dir := prev.direction_to(global_position)
	if dir.length_squared() > 0.1:
		_body.rotation = lerp_angle(_body.rotation, dir.angle() - PI / 2, 0.2)
		
	if progress >= 1.0 or global_position.distance_squared_to(_ctx.return_end) <= 324.0:
		_state = SatelliteState.ORBIT
		_ctx.state_ticks = 0.0
		_ctx.velocity *= 0.12
		_trail_line.clear_points()

func _begin_attack(target: Node2D) -> void:
	_ctx.target = target
	_state = SatelliteState.ATTACK
	_ctx.state_ticks = 0.0
	_trail_line.clear_points()
	
	var target_pos := target.global_position
	_ctx.attack_direction = global_position.direction_to(target_pos)
	if _ctx.attack_direction.length_squared() <= 0.1:
		_ctx.attack_direction = Vector2.RIGHT
		
	var side := Vector2(-_ctx.attack_direction.y, _ctx.attack_direction.x) * (1.0 if randf() < 0.5 else -1.0)
	_ctx.attack_start = global_position
	_ctx.attack_end = FlyingBladeMotion.clamp_to_zone(target_pos + _ctx.attack_direction * attack_distance)
	_ctx.attack_control = FlyingBladeMotion.clamp_to_zone(_ctx.attack_start.linear_interpolate(_ctx.attack_end, 0.5) + side * 6.0)
	
	_disable_hitbox()

func _begin_return(apply_cooldown: bool = true) -> void:
	_release_attack_slot()
	_state = SatelliteState.RETURN
	_ctx.state_ticks = 0.0
	_trail_line.clear_points()
	
	if apply_cooldown:
		_ctx.cooldown = combat_coordinator.get_next_cooldown(attack_cooldown_ticks, ROLE) if combat_coordinator else rand_range(0.5, 1.5)
	else:
		_ctx.cooldown = 0.0
		
	_ctx.target = null
	_disable_hitbox()
	_ctx.return_start = global_position
	_ctx.return_end = _get_orbit_position()
	
	var dir := _ctx.return_start.direction_to(_ctx.return_end)
	if dir.length_squared() <= 0.1:
		dir = _ctx.velocity.normalized() if _ctx.velocity.length_squared() > 0.1 else Vector2.RIGHT
		
	var side := Vector2(-dir.y, dir.x)
	var dist := _ctx.return_start.distance_to(_ctx.return_end)
	_ctx.return_control = FlyingBladeMotion.clamp_to_zone((_ctx.return_start + _ctx.return_end) * 0.5 + dir * dist * 0.15 + side * dist * 0.20)

func _enable_hitbox() -> void:
	if not _ctx.hitbox_enabled:
		_ctx.hitbox_enabled = true
		_hitbox.active = true
		_hitbox.ignored_objects.clear()
		_hitbox.enable()

func _disable_hitbox() -> void:
	if _ctx.hitbox_enabled:
		_ctx.hitbox_enabled = false
		_hitbox.active = false
		_hitbox.disable()
		_hitbox.ignored_objects.clear()

func _position_hitbox(from_pos: Vector2, to_pos: Vector2) -> void:
	var movement := to_pos - from_pos
	if movement.length_squared() <= 1.0:
		movement = _ctx.attack_direction * hitbox_length
	var length := max(hitbox_length, movement.length())
	_hitbox_shape.extents = Vector2(length * 0.5, hitbox_width * 0.5)
	_hitbox.global_position = (from_pos + to_pos) * 0.5
	_hitbox.global_rotation = movement.angle()
	_hitbox.set_knockback(movement.normalized(), knockback, 0.0)

func _enqueue_coordinated_attack() -> void:
	if combat_coordinator:
		_ctx.attack_queued = combat_coordinator.enqueue_attack(self, ROLE)

func get_coordinated_attack_target() -> Node2D:
	_ctx.attack_queued = false
	return _select_target()

func begin_coordinated_attack(target: Node2D) -> void:
	_ctx.attack_queued = false
	if not target or target.dead:
		coordinated_attack_failed()
		return
	_ctx.attack_slot_active = true
	_begin_attack(target)

func coordinated_attack_failed() -> void:
	_ctx.attack_queued = false
	_ctx.attack_slot_active = false
	_ctx.target = null

func _release_attack_slot() -> void:
	if _ctx.attack_slot_active:
		_ctx.attack_slot_active = false
		if combat_coordinator:
			combat_coordinator.release_attack(self, ROLE)

func _retarget_lost_attack() -> void:
	var next_target := _select_target()
	if next_target and not next_target.dead:
		_begin_attack(next_target)
	else:
		_begin_return(_ctx.hitbox_enabled)

func _select_target() -> Node2D:
	if not combat_coordinator: return null
	var best: Node2D = null
	var best_dist := INF
	var range_sq := attack_range * attack_range
	
	for t in combat_coordinator.get_targets():
		if t.dead: continue
		var d := global_position.distance_squared_to(t.global_position)
		if d > range_sq or d >= best_dist: continue
		best_dist = d
		best = t
	return best

func _get_player_position() -> Vector2:
	if player_index >= 0 and player_index < players_ref.size() and is_instance_valid(players_ref[player_index]):
		return players_ref[player_index].global_position
	return global_position

func _update_trail() -> void:
	_trail_line.visible = (_state == SatelliteState.ATTACK) or (_state == SatelliteState.RETURN)
	if not _trail_line.visible: return
	
	var pos := global_position
	var n := _trail_line.get_point_count()
	var sample_sq: float = _tuning.trail_sample_min_distance * _tuning.trail_sample_min_distance
	if n == 0 or _trail_line.get_point_position(n - 1).distance_squared_to(pos) > sample_sq:
		_trail_line.add_point(pos)
	while _trail_line.get_point_count() > _tuning.trail_max_points:
		_trail_line.remove_point(0)

func _emit_attack_fragment() -> void:
	if _fragment_particles.emitting: return
	_fragment_particles.global_position = global_position
	_fragment_particles.emitting = true

func _on_Hitbox_hit_something(thing_hit: Node, _damage_dealt: int) -> void:
	RunData.manage_life_steal(weapon_stats, player_index)
	if not _hitbox.ignored_objects.has(thing_hit):
		_hitbox.ignored_objects.push_back(thing_hit)
	_emit_attack_fragment()

func set_formation(index: int, count: int) -> void:
	_ctx.formation_index = clamp(index, 0, max(count - 1, 0)) as int
	_ctx.formation_count = max(1, count) as int

func reset() -> void:
	_state = SatelliteState.ORBIT
	_ctx.reset()
	visible = true

func shutdown() -> void:
	_initialized = false
	if is_instance_valid(combat_coordinator):
		combat_coordinator.unregister_satellite(self)
	if is_instance_valid(_hitbox):
		_hitbox.disconnect("hit_something", self, "_on_Hitbox_hit_something")
		_hitbox.queue_free()
		_hitbox = null
		_hitbox_collision = null
		_hitbox_shape = null
	queue_free()
