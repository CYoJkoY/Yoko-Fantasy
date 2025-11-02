extends EnemyProjectile

var lifetime = 0
var elapsed_time = 0

func set_lifetime(time) -> void:
	lifetime = time

func _physics_process(delta) -> void:
	if lifetime > 0:
		elapsed_time += delta
		if elapsed_time >= lifetime:
			queue_free()
