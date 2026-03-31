extends Boss

onready var _crescent_shooting_attack_behavior: ShootingAttackBehavior = $"CrescentShootingAttackBehavior"
onready var _projectile_shooting_attack_behavior: ShootingAttackBehavior = $"ProjectileShootingAttackBehavior"

onready var _crescent_shooting_attack_behavior_1: ShootingAttackBehavior = $"%CrescentShootingAttackBehavior1"
onready var _projectile_shooting_attack_behavior_1: ShootingAttackBehavior = $"%ProjectileShootingAttackBehavior1"
onready var COOLDOWN_0: float = _crescent_shooting_attack_behavior_1.cooldown
var current_cooldown_0: float = 0.0

onready var _crescent_shooting_attack_behavior_2: ShootingAttackBehavior = $"%CrescentShootingAttackBehavior2"

onready var _charging_slash_shooting_attack_behavior_3: ShootingAttackBehavior = $"%ChargingSlashShootingAttackBehavior3"
onready var _projectile_shooting_attack_behavior_3: ShootingAttackBehavior = $"%ProjectileShootingAttackBehavior3"
onready var COOLDOWN_1: float = _charging_slash_shooting_attack_behavior_3.cooldown
var current_cooldown_1: float = 0.0
onready var _horizontal_global_shooting_attack_behavior_3: ShootingAttackBehavior = $"%HorizontalGlobalShootingAttackBehavior3"
onready var _vertical_global_shooting_attack_behavior_3: ShootingAttackBehavior = $"%VerticalGlobalShootingAttackBehavior3"


# =========================== Extension =========================== #
func _ready() -> void:
    _crescent_shooting_attack_behavior.init(self )
    _projectile_shooting_attack_behavior.init(self )
    _crescent_shooting_attack_behavior_1.init(self )
    _projectile_shooting_attack_behavior_1.init(self )
    _crescent_shooting_attack_behavior_2.init(self )
    _charging_slash_shooting_attack_behavior_3.init(self )
    _projectile_shooting_attack_behavior_3.init(self )
    _horizontal_global_shooting_attack_behavior_3.init(self )
    _vertical_global_shooting_attack_behavior_3.init(self )

    register_attack_behavior(_crescent_shooting_attack_behavior)
    register_attack_behavior(_projectile_shooting_attack_behavior)
    register_attack_behavior(_crescent_shooting_attack_behavior_1)
    register_attack_behavior(_projectile_shooting_attack_behavior_1)
    register_attack_behavior(_crescent_shooting_attack_behavior_2)
    register_attack_behavior(_charging_slash_shooting_attack_behavior_3)
    register_attack_behavior(_projectile_shooting_attack_behavior_3)
    register_attack_behavior(_horizontal_global_shooting_attack_behavior_3)
    register_attack_behavior(_vertical_global_shooting_attack_behavior_3)

func _physics_process(delta: float) -> void:
    # Mutation 1 Dash:  Shoot Slashes and Projectiles
    if _current_state == 0 and _move_locked and !dead:
        current_cooldown_0 = current_cooldown_0 - Utils.physics_one(delta)
        if current_cooldown_0 <= 0:
            current_cooldown_0 = COOLDOWN_0
            _crescent_shooting_attack_behavior_1.shoot()
            _projectile_shooting_attack_behavior_1.shoot()

    # Mutation 3 Dash: Shoot random direction Slashes
    elif _current_state == 2 and _move_locked and !dead:
        current_cooldown_1 = current_cooldown_1 - Utils.physics_one(delta)
        if current_cooldown_1 <= 0:
            current_cooldown_1 = COOLDOWN_1
            _charging_slash_shooting_attack_behavior_3.shoot()
            _projectile_shooting_attack_behavior_3.shoot()

func shoot() -> void:
    .shoot()
    # Mutation 2: Async operation
    if _current_state == 1: mutation_2_slash_shoot()

func on_state_changed(_new_state: int) -> void:
    .on_state_changed(_new_state)
    # Mutation 2 Change: Stand still when shoot and speed up
    if _new_state == 1:
        shoot_animation_name = "shoot_stand"
        reset_speed_stat(50)

# =========================== Custom =========================== #
func mutation_2_slash_shoot() -> void:
    for i in 3:
        _crescent_shooting_attack_behavior_2.shoot()
        if i < 2: yield (get_tree().create_timer(0.2), "timeout")

# =========================== Method =========================== #
func switch_can_move(can_move: bool) -> void:
    _can_move = can_move

func choose_random_mutation_3_global_shoot() -> void:
    if randf() < 0.5: _horizontal_global_shooting_attack_behavior_3.shoot()
    else: _vertical_global_shooting_attack_behavior_3.shoot()
