extends Enemy

onready var _charging_shoot_attack_behavior: ShootingAttackBehavior = $ChargingShootAttackBehavior
onready var COOLDOWN = _charging_shoot_attack_behavior.cooldown
var current_projectiles_cooldown: float = 0.0

# =========================== Extension =========================== #
func respawn() -> void:
    .respawn()
    current_projectiles_cooldown = 0.0

    _charging_shoot_attack_behavior.reset()


func _ready() -> void:
    _charging_shoot_attack_behavior.init(self )
    
    _all_attack_behaviors.append(_charging_shoot_attack_behavior)


func _physics_process(delta: float) -> void:
    current_projectiles_cooldown -= Utils.physics_one(delta)

    if current_projectiles_cooldown <= 0.0 and !dead:
        current_projectiles_cooldown = COOLDOWN
        _charging_shoot_attack_behavior.shoot()
