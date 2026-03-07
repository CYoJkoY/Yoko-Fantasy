extends EnemyProjectile

export(int) var max_distance = 250
export(bool) var reset_alpa = false
export(int) var reset_alpha = 0

var delta_distance: float = 0.0

func _physics_process(delta: float) -> void:
    delta_distance += (velocity * delta).length()
    if delta_distance < max_distance: return

    delta_distance = 0.0
    stop()

func stop() -> void:
    if _enable_stop_delay: return

    if reset_alpa: _sprite.self_modulate.a = reset_alpha
    .stop()
