extends ShootingAttackBehavior

enum TargetClass {SELF, PLAYER, RANDOM}

export(TargetClass) var target_class = TargetClass.PLAYER
export(bool) var towards_player = false
export(int) var spawn_radius = 1100
export(float) var spawn_degrees = 360.0
export(float) var init_rotation = 0.0
export(float) var projectile_direction = 180.0
export(float) var direction_change_after_each_proj = 60.0
export(bool) var pos_base_on_centerx = true
export(bool) var pos_base_on_centery = false
export(Dictionary) var specific_projectiles = {}

onready var map_center: Vector2 = ZoneService.get_map_center()

var main: Main = null
var base_rot: float = 0.0

# =========================== Extension =========================== #
func _ready() -> void:
    main = Utils.get_scene_node()
    spawn_degrees = deg2rad(spawn_degrees)
    init_rotation = deg2rad(init_rotation)
    projectile_direction = deg2rad(projectile_direction)
    direction_change_after_each_proj = deg2rad(direction_change_after_each_proj)
    for specific_projectile in specific_projectiles.values():
        specific_projectile[1] = deg2rad(specific_projectile[1])
        specific_projectile[2] = deg2rad(specific_projectile[2])

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
    
    if towards_player: base_rot = (_parent.current_target.global_position - _parent.global_position).angle()

    for i in number_projectiles:
        var angle = base_rot + init_rotation + (spawn_degrees * i) / number_projectiles
        var spawn_pos = target_pos + spawn_radius * Vector2(cos(angle), sin(angle))
        var proj_direction = base_rot + projectile_direction + (direction_change_after_each_proj * i)

        if !specific_projectiles.empty() and specific_projectiles.keys().has(i):
            var specific_porjectile: Array = specific_projectiles[i]
            var specific_spawn_radius = specific_porjectile[0]
            angle = base_rot + specific_porjectile[1]
            proj_direction = base_rot + specific_porjectile[2]
            spawn_pos = target_pos + specific_spawn_radius * Vector2(cos(angle), sin(angle))

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
    projectile.velocity = Vector2.RIGHT.rotated(rot) * spd * RunData.current_run_accessibility_settings.speed

    if rotate_projectile:
        projectile.rotation = rot

    projectile.set_damage(projectile_damage)

    if custom_collision_layer != 0:
        projectile.set_collision_layer(custom_collision_layer)

    if custom_sprite_material:
        projectile.set_sprite_material(custom_sprite_material)

    projectile.shoot()
    return projectile
