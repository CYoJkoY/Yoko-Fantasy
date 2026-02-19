extends ShootingAttackBehavior

# =========================== Extension =========================== #
func spawn_projectile(rot: float, pos: Vector2, spd: int) -> Node:
    var main: Main = Utils.get_scene_node()
    var projectile: Node = main.get_node_from_pool(projectile_pool_id, main._enemy_projectiles)
    
    if !is_instance_valid(projectile):
        projectile = projectile_scene.instance()
        main.add_enemy_projectile(projectile)
        projectile.set_meta("pool_id", projectile_pool_id)

    projectile.global_position = pos
    projectile.set_from(_parent)
    projectile.velocity = Vector2.RIGHT.rotated(rot) * spd * RunData.current_run_accessibility_settings.speed
    projectile.set_range(min_range, max_range) # For Laser Extends

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
