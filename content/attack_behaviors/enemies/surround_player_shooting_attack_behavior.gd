extends AttackBehavior

signal shot
signal finished_shooting

enum TargetClass { SELF, PLAYER }

export (PackedScene) var projectile_scene: PackedScene = preload("res://projectiles/bullet_enemy/enemy_projectile.tscn")
export (int) var projectile_speed: int = 800
export (float) var cooldown: float = 90.0
export (int) var number_projectiles: int = 2
export (TargetClass) var target_class = TargetClass.PLAYER
export (int) var spawn_radius: int = 1100
export (float, 0, 6.28, 0.01) var init_rotation: float = 0.08
export (float, 0, 6.28, 0.01) var projectile_direction: float = 3.14
export (float, 0, 6.28, 0.01) var direction_change_after_each_proj: float = 3.14
export (bool) var rotate_projectile: bool = true
export (bool) var pos_base_on_centerx: bool = true
export (bool) var pos_base_on_centery: bool = false

var _current_cd: float = cooldown
var projectile_damage: int = 0
var living_time: float = 0.0
var living_projectiles: Array = []

func _ready() -> void:
    _current_cd = cooldown

func reset() -> void:
    _current_cd = cooldown
    projectile_damage = 0

func physics_process(delta: float) -> void:
    _current_cd = max(_current_cd - Utils.physics_one(delta), 0)

    if !_parent.is_playing_shoot_animation() and _current_cd <= 0:
        _parent._animation_player.play(_parent.shoot_animation_name)
        emit_signal("shot")

func shoot() -> void:
    var target_pos: Vector2
    match target_class:
        TargetClass.PLAYER: target_pos = _parent.current_target.global_position
        TargetClass.SELF: target_pos = _parent.global_position

    if pos_base_on_centerx or pos_base_on_centery:
        var map_center: Vector2 = ZoneService.get_map_center()
        
        if pos_base_on_centerx:
            target_pos.x = map_center.x
        if pos_base_on_centery:
            target_pos.y = map_center.y
    
    for i in number_projectiles:
        var angle = init_rotation + (TAU * i) / number_projectiles
        var spawn_pos = target_pos + Vector2(cos(angle), sin(angle)) * spawn_radius
        var proj_direction = projectile_direction + (direction_change_after_each_proj * i)

        spawn_projectile(proj_direction, spawn_pos, projectile_speed)
    
    _current_cd = cooldown
    emit_signal("finished_shooting")


func spawn_projectile(rot: float, pos: Vector2, spd: int) -> Node:
    var main = Utils.get_scene_node()
    var projectile = main.get_node_from_pool(projectile_scene.resource_path)
    if projectile == null:
        projectile = projectile_scene.instance()
        main.call_deferred("add_enemy_projectile", projectile)

    projectile.global_position = pos
    projectile.call_deferred("set_from", _parent)
    projectile.set_deferred("velocity", Vector2.RIGHT.rotated(rot) * spd * RunData.current_run_accessibility_settings.speed)

    if rotate_projectile:
        projectile.set_deferred("rotation", rot)

    projectile.call_deferred("set_damage", projectile_damage)
    projectile.call_deferred("shoot")
    return projectile
