extends ShootingAttackBehavior

export(int) var projectiles_per_time = 3
export(int, 0, 360) var angle_min = 0
export(int, 0, 360) var angle_max = 24
export(float) var wave_speed = 1.5
export(float) var wave_range = 120.0
export(float) var air_resistance = 0.2

var map_zero: Vector2 = ZoneService.current_zone_min_position
var map_size_quarter: Vector2 = ZoneService.current_zone_max_position * 0.25
var map_size_three_quarter: Vector2 = ZoneService.current_zone_max_position * 0.75

var main: Main = null

var _time_passed: float = 0.0
var active_projectiles: Array = []

# =========================== Extension =========================== #
func _ready() -> void:
    main = Utils.get_scene_node()
    angle_min = deg2rad(angle_min)
    angle_max = deg2rad(angle_max)

func reset() -> void:
    _time_passed = 0.0
    active_projectiles.clear()

func physics_process(delta: float) -> void:
    _time_passed += delta

    for i in range(active_projectiles.size() - 1, -1, -1):
        var p = active_projectiles[i]

        if p._hitbox.is_disabled():
            active_projectiles.remove(i)
            continue

        var p_id_offset: int = p.get_instance_id() % 100
        p.velocity.x = sin(_time_passed * wave_speed + p_id_offset) * wave_range
        p.velocity.y = p.velocity.y / (1.0 + air_resistance * delta)

    if _current_initial_cooldown > 0:
        _current_initial_cooldown = _current_initial_cooldown - Utils.physics_one(delta)
        return

    _current_cd = _current_cd - Utils.physics_one(delta)

    if not _parent.is_playing_shoot_animation() and _current_cd <= 0 and Utils.is_between(_parent.global_position.distance_to(_parent.current_target.global_position), min_range, max_range):
        _parent._animation_player.playback_speed = attack_anim_speed
        _parent._animation_player.play(_parent.shoot_animation_name)
        emit_signal("shot")

func shoot() -> void:
    var speed: float = 0

    for i in projectiles_per_time:
        var spawn_x: float = rand_range(map_size_quarter.x, map_size_three_quarter.x)
        var spawn_y: float = map_zero.y
        var spawn_pos = Vector2(spawn_x, spawn_y)

        var random_angle: float = rand_range(angle_min - angle_max, angle_min + angle_max)
        speed = rand_range(projectile_speed - projectile_speed_randomization, projectile_speed + projectile_speed_randomization)

        if speed_change_after_each_projectile != 0:
            speed += speed_change_after_each_projectile * i

        active_projectiles.append(spawn_projectile(random_angle, spawn_pos, speed as int))

    _shots_taken += 1

func spawn_projectile(rot: float, pos: Vector2, spd: int) -> Node:
    var projectile: EnemyProjectile = main.get_node_from_pool(projectile_pool_id, main._enemy_projectiles)
    if !is_instance_valid(projectile):
        projectile = projectile_scene.instance()
        main.add_enemy_projectile(projectile)
        projectile.set_meta("pool_id", projectile_pool_id)

    projectile.global_position = pos
    projectile.set_from(_parent)
    projectile.velocity = Vector2.DOWN.rotated(rot) * spd * RunData.current_run_accessibility_settings.speed # (-24°~24°, Down) for (480~1440,1080)

    if rotate_projectile:
        projectile.rotation = rot

    if delete_projectile_on_death and not _parent.is_connected("died", projectile, "on_entity_died"):
        var _error_died = _parent.connect("died", projectile, "on_entity_died")

    projectile.set_damage(projectile_damage)

    if custom_collision_layer != 0:
        projectile.set_collision_layer(custom_collision_layer)
    
    if custom_sprite_material:
        projectile.set_sprite_material(custom_sprite_material)

    projectile.shoot()
    return projectile
