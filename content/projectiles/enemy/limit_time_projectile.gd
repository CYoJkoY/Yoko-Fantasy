extends EnemyProjectile

export(float) var lifetime = 0.0
export(bool) var reset_alpa = false
export(int) var reset_alpha = 0

var delta_time: float = 0.0

func _physics_process(delta) -> void:
    if lifetime <= 0: return

    delta_time += delta
    if delta_time < lifetime: return
    
    delta_time = 0.0
    stop()

func stop() -> void:
    if _enable_stop_delay: return

    if reset_alpa: _sprite.self_modulate.a = reset_alpha
    .stop()
