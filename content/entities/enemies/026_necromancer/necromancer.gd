extends Boss

onready var mutation_1_spawning_attack_behavior = $AttackBehavior

onready var mutation_2_shooting_attack_behavior: ShootingAttackBehavior = $"%Mutation1ShootingAttackBehavior"
onready var COOLDOWN_0: float = mutation_2_shooting_attack_behavior.cooldown
var current_cooldown_0: float = 0.0

# =========================== Extension =========================== #
func _ready() -> void:
    mutation_1_spawning_attack_behavior.init(self )
    mutation_2_shooting_attack_behavior.init(self )

    register_attack_behavior(mutation_1_spawning_attack_behavior)
    register_attack_behavior(mutation_2_shooting_attack_behavior)

func _physics_process(delta: float) -> void:
    # Mutation 2: shoot five projectiles
    if _current_state == 1:
        current_cooldown_0 = current_cooldown_0 - Utils.physics_one(delta)
        if current_cooldown_0 <= 0 and !dead:
            current_cooldown_0 = COOLDOWN_0
            mutation_2_shooting_attack_behavior.shoot()

func shoot() -> void:
    .shoot()

    if _current_state == 0: mutation_1_spawning_attack_behavior.shoot()
