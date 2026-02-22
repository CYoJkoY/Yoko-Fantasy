extends AttackBehavior

export(PackedScene) var projectile_scene = preload("res://projectiles/bullet_enemy/enemy_projectile.tscn")
var projectile_pool_id: int = Keys.empty_hash

export(float) var cooldown: float = 60
export(int) var projectiles_per_time = 3
export(int) var projectile_speed_min = 200
export(int) var projectile_speed_max = 400
export(int, 0, 360) var angle_min = 0
export(int, 0, 360) var angle_max = 24
export(float) var wave_speed = 1.5
export(float) var wave_range = 120.0
export(float) var air_resistance = 0.2

var map_zero: Vector2 = ZoneService.current_zone_min_position
var map_size_quarter: Vector2 = ZoneService.current_zone_max_position * 0.25
var map_size_three_quarter: Vector2 = ZoneService.current_zone_max_position * 0.75

var main: Main = null

var _current_cd: float = 0.0
var projectile_damage: int = 0
var _time_passed: float = 0.0
var active_projectiles: Array = []

# =========================== Extension =========================== #
func _ready() -> void:
    _current_cd = cooldown
    if projectile_scene != null:
        projectile_pool_id = Keys.generate_hash(projectile_scene.resource_path)
    main = Utils.get_scene_node()
    angle_min = deg2rad(angle_min)
    angle_max = deg2rad(angle_max)

func reset() -> void:
    _current_cd = cooldown
    projectile_damage = 0
    _time_passed = 0.0
    active_projectiles.clear()

func physics_process(delta: float) -> void:
    _current_cd -= Utils.physics_one(delta)
    _time_passed += delta

    for i in range(active_projectiles.size() - 1, -1, -1):
        var p = active_projectiles[i]

        if p._hitbox.is_disabled():
            active_projectiles.remove(i)
            continue

        var p_id_offset: int = p.get_instance_id() % 100
        p.velocity.x = sin(_time_passed * wave_speed + p_id_offset) * wave_range
        p.velocity.y = p.velocity.y / (1.0 + air_resistance * delta)
    
    if _parent.is_playing_shoot_animation() or _current_cd > 0: return

    _parent._animation_player.play(_parent.shoot_animation_name)

func shoot() -> void:
    for i in projectiles_per_time:
        var spawn_x: float = rand_range(map_size_quarter.x, map_size_three_quarter.x)
        var spawn_y: float = map_zero.y
        var spawn_pos = Vector2(spawn_x, spawn_y)

        var random_angle: float = rand_range(angle_min - angle_max, angle_min + angle_max)
        var random_speed: float = rand_range(projectile_speed_min, projectile_speed_max)

        active_projectiles.append(spawn_projectile(random_angle, spawn_pos, random_speed))

    _current_cd = cooldown

func spawn_projectile(rot: float, pos: Vector2, spd: float) -> Node:
    var projectile: EnemyProjectile = main.get_node_from_pool(projectile_pool_id, main._enemy_projectiles)
    if !is_instance_valid(projectile):
        projectile = projectile_scene.instance()
        main.add_enemy_projectile(projectile)
        projectile.set_meta("pool_id", projectile_pool_id)

    projectile.global_position = pos
    projectile.set_from(_parent)
    projectile.velocity = Vector2.DOWN.rotated(rot) * spd # (-24°~24°, Down) for (480~1440,1080)

    projectile.set_damage(projectile_damage)
    projectile.shoot()
    return projectile
