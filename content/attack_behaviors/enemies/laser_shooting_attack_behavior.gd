extends ShootingAttackBehavior

func spawn_projectile(rot: float, pos: Vector2, spd: int) -> Node:
    var main = Utils.get_scene_node()
    var projectile = main.get_node_from_pool(projectile_scene.resource_path)
    
    if not is_instance_valid(projectile):
        projectile = projectile_scene.instance()
        main.add_enemy_projectile(projectile)
        projectile.set_meta("pool_id", projectile_pool_id)

    projectile.global_position = pos
    projectile.call_deferred("set_from", _parent)
    projectile.set_deferred("velocity", Vector2.RIGHT.rotated(rot) * spd * RunData.current_run_accessibility_settings.speed)
    # For Laser Extends
    projectile.call_deferred("set_range", min_range, max_range)

    if rotate_projectile:
        projectile.set_deferred("rotation", rot)

    if delete_projectile_on_death and not _parent.is_connected("died", projectile, "on_entity_died"):
        var _error_died = _parent.connect("died", projectile, "on_entity_died")

    projectile.call_deferred("set_damage", projectile_damage)

    if custom_collision_layer != 0:
        projectile.call_deferred("set_collision_layer", custom_collision_layer)

    if custom_sprite_material:
        projectile.call_deferred("set_sprite_material", custom_sprite_material)

    projectile.call_deferred("shoot")
    return projectile
