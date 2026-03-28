extends Boss

onready var mutation_0_attack_behavior_2: ShootingAttackBehavior = $"AttackBehavior2"
var mutation_0_attack_mode: int = 0

onready var triangel_attack_behavior: ShootingAttackBehavior = $"%TriangleAttackBehavior"

# =========================== Extension =========================== #
func _ready() -> void:
    mutation_0_attack_behavior_2.init(self )
    triangel_attack_behavior.init(self )

    register_attack_behavior(mutation_0_attack_behavior_2)
    register_attack_behavior(triangel_attack_behavior)

func shoot() -> void:
    .shoot()
    if _current_state != -1: return

    # Mutation 0 switch attack mode
    mutation_0_attack_mode ^= 1
    match mutation_0_attack_mode:
        0: _current_attack_behavior = _attack_behavior
        1: _current_attack_behavior = mutation_0_attack_behavior_2

func on_state_changed(_new_state: int) -> void:
    .on_state_changed(_new_state)
    if _new_state == 0: current_stats.speed = 0
