extends AttackBehavior

signal shot
signal finished_shooting

enum BorderDirection {TOP, BOTTOM, LEFT, RIGHT}
enum MovementType {STRAIGHT, SINUSOIDAL, WAVE}

export (PackedScene) var projectile_scene = preload("res://projectiles/bullet_enemy/enemy_projectile.tscn")
export (int) var projectile_speed = 1000
export (float) var cooldown = 90.0
export (int) var number_projectiles = 4
export (BorderDirection) var border_direction = BorderDirection.TOP
export (Array, BorderDirection) var multiple_borders = []
export (int) var border_offset = 100
export (int) var border_spread = 500
export (MovementType) var movement_type = MovementType.STRAIGHT
export (float) var wave_frequency = 1.0
export (float) var wave_amplitude = 50.0
export (bool) var rotate_projectile = true
export (bool) var target_player = true
export (int) var damage = 1
export (float) var damage_increase_each_wave = 1.0

var _current_cd: float = cooldown
var projectile_damage: int = 0
var _main_node: Node


func _ready() -> void:
    _current_cd = cooldown
    _main_node = Utils.get_scene_node()


func reset() -> void:
    _current_cd = cooldown
    projectile_damage = 0


func physics_process(delta: float) -> void:
    _current_cd = max(_current_cd - Utils.physics_one(delta), 0)

    if !_parent.is_playing_shoot_animation() and _current_cd <= 0:
        _parent._animation_player.play(_parent.shoot_animation_name)
        emit_signal("shot")


func shoot() -> void:
    var borders_to_use = multiple_borders if multiple_borders.size() > 0 else [border_direction]
    
    for border in borders_to_use:
        spawn_border_projectiles(border)
    
    _current_cd = cooldown
    emit_signal("finished_shooting")


func spawn_border_projectiles(border: int) -> void:
    var zone_rect = ZoneService.get_current_zone_rect()
    var zone_center = ZoneService.get_map_center()
    
    var border_positions = []
    
    match border:
        BorderDirection.TOP:
            for i in number_projectiles:
                var x = zone_center.x + (i - (number_projectiles - 1) * 0.5) * (border_spread / number_projectiles)
                border_positions.append(Vector2(x, zone_rect.position.y - border_offset))
        BorderDirection.BOTTOM:
            for i in number_projectiles:
                var x = zone_center.x + (i - (number_projectiles - 1) * 0.5) * (border_spread / number_projectiles)
                border_positions.append(Vector2(x, zone_rect.end.y + border_offset))
        BorderDirection.LEFT:
            for i in number_projectiles:
                var y = zone_center.y + (i - (number_projectiles - 1) * 0.5) * (border_spread / number_projectiles)
                border_positions.append(Vector2(zone_rect.position.x - border_offset, y))
        BorderDirection.RIGHT:
            for i in number_projectiles:
                var y = zone_center.y + (i - (number_projectiles - 1) * 0.5) * (border_spread / number_projectiles)
                border_positions.append(Vector2(zone_rect.end.x + border_offset, y))
    
    for pos in border_positions:
        spawn_projectile(pos)


func spawn_projectile(spawn_pos: Vector2) -> void:
    var projectile = _main_node.get_node_from_pool(projectile_scene.resource_path)
    if projectile == null:
        projectile = projectile_scene.instance()
        _main_node.call_deferred("add_enemy_projectile", projectile)
    
    # 安全检查
    if !is_instance_valid(projectile):
        push_error("Projectile instance is invalid")
        return
    
    projectile.global_position = spawn_pos
    projectile.call_deferred("set_from", _parent)
    projectile.call_deferred("set_damage", damage + projectile_damage)
    
    var target_pos = _parent.current_target.global_position if target_player and is_instance_valid(_parent.current_target) else ZoneService.get_map_center()
    var direction = (target_pos - spawn_pos).normalized()
    
    var velocity = direction * projectile_speed * RunData.current_run_accessibility_settings.speed
    
    # 优化特殊运动处理
    if movement_type != MovementType.STRAIGHT:
        if projectile.has_method("init_special_movement"):
            # 将枚举值转换为world_tree_projectile_leaf.gd中的对应值
            var movement_type_int = movement_type - 1  # 转换为0-based
            projectile.call_deferred("init_special_movement", movement_type_int, wave_frequency, wave_amplitude, direction)
        else:
            push_warning("Projectile does not support special movement")
    
    projectile.set_deferred("velocity", velocity)
    
    if rotate_projectile:
        projectile.set_deferred("rotation", direction.angle())


func animation_finished(anim_name: String) -> void:
    if _parent.is_shooting_anim(anim_name):
        _current_cd = cooldown
