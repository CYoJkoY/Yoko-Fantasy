extends ShootingAttackBehavior

enum TargetClass {SELF, PLAYER, RANDOM}

export(TargetClass) var target_class = TargetClass.PLAYER
export(bool) var towards_player = false
export(int) var spawn_radius = 1100
export(float, 0.0, 6.28, 0.01) var spawn_degrees = 6.28
export(float, 0.0, 6.28, 0.01) var init_rotation = 0.0
export(float, 0.0, 6.28, 0.01) var projectile_direction = 3.14
export(float, 0.0, 6.28, 0.01) var direction_change_after_each_proj = 1.05
export(bool) var pos_base_on_centerx = true
export(bool) var pos_base_on_centery = false
export(Dictionary) var specific_projectiles = {}
export(int) var bullets_per_frame = 4

onready var map_center: Vector2 = ZoneService.get_map_center()

var main: Main = null
var true_number_projectiles: int = 0
var _shooting_cancelled: bool = false

func _ready() -> void:
    main = Utils.get_scene_node()
    true_number_projectiles = number_projectiles - specific_projectiles.size()

func shoot() -> void:
    _shooting_cancelled = true

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

    var base_rot: float = 0.0
    if towards_player:
        base_rot = (_parent.current_target.global_position - _parent.global_position).angle()
    elif shoot_in_unit_direction:
        base_rot = (_parent.global_position + _parent.get_movement()).angle()

    _current_cd = cooldown
    _shooting_cancelled = false
    _fantasy_distribute_shots(target_pos, base_rot)

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

# =========================== Custom =========================== #
func _fantasy_distribute_shots(target_pos: Vector2, base_rot: float) -> void:
    var bullets_this_frame = 0
    for i in range(number_projectiles):
        if _shooting_cancelled: return

        var angle: float = 0.0
        var spawn_pos: Vector2 = Vector2.ZERO
        var proj_direction: float = 0.0

        if !specific_projectiles.empty() and specific_projectiles.keys().has(i):
            var specific_porjectile: Array = specific_projectiles[i]
            var specific_spawn_radius: int = specific_porjectile[0]
            angle = base_rot + specific_porjectile[1]
            spawn_pos = target_pos + specific_spawn_radius * Vector2(cos(angle), sin(angle))
            proj_direction = base_rot + specific_porjectile[2]
        else:
            angle = base_rot + init_rotation + (spawn_degrees * i) / true_number_projectiles
            spawn_pos = target_pos + spawn_radius * Vector2(cos(angle), sin(angle))
            proj_direction = base_rot + projectile_direction + (direction_change_after_each_proj * i)

        spawn_projectile(proj_direction, spawn_pos, projectile_speed)
        bullets_this_frame += 1
        if bullets_this_frame < bullets_per_frame: continue

        yield (get_tree(), "idle_frame")
        bullets_this_frame = 0
