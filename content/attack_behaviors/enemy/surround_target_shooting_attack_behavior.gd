extends AttackBehavior

enum TargetClass {SELF, PLAYER, RANDOM}

export(PackedScene) var projectile_scene = preload("res://projectiles/bullet_enemy/enemy_projectile.tscn")
var projectile_pool_id: int = Keys.empty_hash
export(int) var projectile_speed = 800
export(float) var cooldown = 90.0
export(float) var damage = 0.0
export(float) var damage_increase_each_wave = 0.0
export(int) var number_projectiles = 6
export(TargetClass) var target_class = TargetClass.PLAYER
export(int) var spawn_radius = 1100
export(int, 0, 360) var init_rotation = 0
export(int, 0, 360) var projectile_direction = 180
export(int, 0, 360) var direction_change_after_each_proj = 60
export(bool) var rotate_projectile = true
export(bool) var pos_base_on_centerx = true
export(bool) var pos_base_on_centery = false

onready var map_center: Vector2 = ZoneService.get_map_center()

var main: Main = null

var _current_cd: float = cooldown
var projectile_damage: int = 0

# =========================== Extension =========================== #
func _ready() -> void:
    _current_cd = cooldown
    if projectile_scene != null:
        projectile_pool_id = Keys.generate_hash(projectile_scene.resource_path)
    main = Utils.get_scene_node()
    init_rotation = deg2rad(init_rotation)
    projectile_direction = deg2rad(projectile_direction)
    direction_change_after_each_proj = deg2rad(direction_change_after_each_proj)

func reset() -> void:
    _current_cd = cooldown
    projectile_damage = 0

func physics_process(delta: float) -> void:
    _current_cd -= Utils.physics_one(delta)

    if _parent.is_playing_shoot_animation() or _current_cd > 0: return

    _parent._animation_player.play(_parent.shoot_animation_name)

func shoot() -> void:
    var target_pos: Vector2
    match target_class:
        TargetClass.PLAYER: target_pos = _parent.current_target.global_position
        TargetClass.SELF: target_pos = _parent.global_position
        TargetClass.RANDOM: target_pos = ZoneService.get_rand_pos()

    match [pos_base_on_centerx, pos_base_on_centery]:
        [true, true]:
            target_pos.x = map_center.x
            target_pos.y = map_center.y
        [true, false]: target_pos.x = map_center.x
        [false, true]: target_pos.y = map_center.y
    
    for i in number_projectiles:
        var angle = init_rotation + (TAU * i) / number_projectiles
        var spawn_pos = target_pos + spawn_radius * Vector2(cos(angle), sin(angle))
        var proj_direction = projectile_direction + (direction_change_after_each_proj * i)

        spawn_projectile(proj_direction, spawn_pos, projectile_speed)
    
    _current_cd = cooldown

func spawn_projectile(rot: float, pos: Vector2, spd: int) -> Node:
    var projectile = main.get_node_from_pool(projectile_pool_id, main._enemy_projectiles)
    if !is_instance_valid(projectile):
        projectile = projectile_scene.instance()
        main.add_enemy_projectile(projectile)
        projectile.set_meta("pool_id", projectile_pool_id)

    projectile.global_position = pos
    projectile.set_from(_parent)
    projectile.velocity = Vector2.RIGHT.rotated(rot) * spd

    if rotate_projectile:
        projectile.rotation = rot

    projectile.set_damage(projectile_damage)
    projectile.shoot()
    return projectile
