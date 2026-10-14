extends ShootingAttackBehavior

var locked_direction: float = 0.0

# ══════════════════════════════════════════ Extension ══════════════════════════════════════════ #
func shoot() -> void:
    for i in range(number_projectiles):
        var spread: float = 0.0
        if number_projectiles > 1:
            spread = -projectile_spread + 2.0 * projectile_spread * i / (number_projectiles - 1)
        spawn_projectile(locked_direction + spread, _parent.global_position, projectile_speed)
    _shots_taken += 1
