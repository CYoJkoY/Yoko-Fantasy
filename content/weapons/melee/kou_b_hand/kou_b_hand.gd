extends "res://weapons/melee/melee_weapon.gd"


func is_manual_aim() -> bool:
    return false


func get_direction_and_calculate_target() -> float:
    _current_target = Utils.get_nearest_no_max(_targets_in_range, global_position, current_stats.min_range)
    return get_direction()


func get_direction() -> float:
    var target_angle: float = rotation
    if not _current_target.empty() and is_instance_valid(_current_target[0]) and not _current_target[0].dead:
        target_angle = (_current_target[0].global_position - global_position).angle()
    return lerp_angle(rotation, target_angle, 1.0 - exp(-18.0 * get_physics_process_delta_time()))


func should_shoot() -> bool:
    if _parent.dead or _parent.cleaning_up:
        return false
    return .should_shoot()


func shoot() -> void:
    if _parent.dead or _parent.cleaning_up:
        set_shooting(false)
        return
    .shoot()


func strike() -> void:
    if _parent.dead or _parent.cleaning_up:
        return
    _current_target = Utils.get_nearest_no_max(_targets_in_range, global_position, current_stats.min_range)
    var target: Unit = _current_target[0]
    if not is_instance_valid(target) or target.dead:
        return
    if not Utils.is_between(_current_target[1], current_stats.min_range, get_max_range()):
        return
    _hitbox.set_knockback((target.global_position - global_position).normalized(), current_stats.knockback, current_stats.knockback_piercing)
    SoundManager.play(Utils.get_rand_element(current_stats.shooting_sounds), current_stats.sound_db_mod, 0.2)
    target.hurt_area_entered_deferred(_hitbox)
