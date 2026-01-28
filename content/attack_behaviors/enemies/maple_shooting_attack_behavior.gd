extends ShootingAttackBehavior

var other_pos: Vector2 = Vector2.ZERO

func get_projectile_spawn_pos(target_pos: Vector2, projectile_index: int, base_pos: float)->Vector2:
    var pos: Vector2 = .get_projectile_spawn_pos(target_pos, projectile_index, base_pos)
    if other_pos != Vector2.ZERO:
        pos = other_pos
    
    return pos
