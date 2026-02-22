extends Boss

onready var _laser_shooting_attack_behavior: ShootingAttackBehavior = $"%LaserShootingAttackBehavior"
onready var COOLDOWN_0: float = _laser_shooting_attack_behavior.cooldown
var current_cooldown_0: float = 0.0

# =========================== Extension =========================== #
func _ready() -> void:
    _laser_shooting_attack_behavior.init(self )

    _all_attack_behaviors.append(_laser_shooting_attack_behavior)

func _physics_process(delta) -> void:
    if _current_state == 0:
        current_cooldown_0 = max(0.0, current_cooldown_0 - Utils.physics_one(delta))
        if current_cooldown_0 <= 0 and !dead:
            current_cooldown_0 = COOLDOWN_0
            _laser_shooting_attack_behavior.shoot()
