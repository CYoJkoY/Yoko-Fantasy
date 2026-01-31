extends Enemy

var current_projectiles_cooldown: float = 0.0

onready var _charging_shoot_attack_behavior = $ChargingShootAttackBehavior

func respawn()->void :
    .respawn()
    current_projectiles_cooldown = 0.0


func _ready()->void :
    _charging_shoot_attack_behavior.init(self)
    
    _all_attack_behaviors.append(_charging_shoot_attack_behavior)


func _physics_process(delta: float)->void :
    current_projectiles_cooldown = max(0.0, current_projectiles_cooldown - Utils.physics_one(delta))

    if bonus_speed > 0 and current_projectiles_cooldown <= 0.0 and not dead:
        current_projectiles_cooldown = _charging_shoot_attack_behavior.cooldown
        _charging_shoot_attack_behavior.shoot()
