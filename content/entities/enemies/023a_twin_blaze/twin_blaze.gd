extends Boss

onready var _spread_shooting_attack_behavior: ShootingAttackBehavior = $"SpreadAttackBehavior"

var _attack_times: int = 0
var _can_attack: bool = false

# =========================== Extension =========================== #
func _ready() -> void:
    _spread_shooting_attack_behavior.init(self )

    register_attack_behavior(_spread_shooting_attack_behavior)

func shoot() -> void:
    .shoot()
    _attack_times += 1
    if _attack_times % 2 == 0: _can_attack = true

func _physics_process(_delta) -> void:
    if _can_attack and _current_state == -1:
        _can_attack = false
        _spread_shooting_attack_behavior.shoot()
