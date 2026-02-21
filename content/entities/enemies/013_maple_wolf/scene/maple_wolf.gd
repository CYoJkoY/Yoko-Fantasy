extends Enemy

var current_projectiles_cooldown: float = 0.0
var maple_pos: Vector2 = Vector2.ZERO

onready var _charging_shoot_attack_behavior: ShootingAttackBehavior = $ChargingShootAttackBehavior
onready var maple_shoot_attack_behavior: Node2D = $MapleShootAttackBehavior

# =========================== Extension =========================== #
func respawn() -> void:
    .respawn()
    current_projectiles_cooldown = 0.0


func _ready() -> void:
    _charging_shoot_attack_behavior.init(self )
    maple_shoot_attack_behavior.init(self )
    
    _all_attack_behaviors.append(_charging_shoot_attack_behavior)
    _all_attack_behaviors.append(maple_shoot_attack_behavior)

func _physics_process(delta: float) -> void:
    current_projectiles_cooldown = max(0.0, current_projectiles_cooldown - Utils.physics_one(delta))

    if _move_locked and current_projectiles_cooldown <= 0.0 and !dead:
        current_projectiles_cooldown = _charging_shoot_attack_behavior.cooldown
        maple_pos = _charging_shoot_attack_behavior.global_position
        _charging_shoot_attack_behavior.shoot()
        
        maple_shoot_attack_behavior.other_pos = maple_pos
        maple_shoot_attack_behavior.shoot()
