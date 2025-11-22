extends EnemyProjectile

export (float) var lifetime = 0.0
var elapsed_time: float = 0.0

func _physics_process(delta) -> void:
    if lifetime > 0:
        elapsed_time += delta
        if elapsed_time >= lifetime:
            queue_free()
