extends EnemyProjectile

export(int) var piercing_times = 99

onready var remaining_piercing_times = piercing_times

# =========================== Extension =========================== #
func _on_Hitbox_hit_something(_thing_hit: Node, _damage_dealt: int) -> void:
	remaining_piercing_times -= 1

	if remaining_piercing_times <= 0: stop()

func _return_to_pool() -> void:
    ._return_to_pool()
    remaining_piercing_times = piercing_times
