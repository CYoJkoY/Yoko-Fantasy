extends Enemy

var maple_pos: Vector2 = Vector2.ZERO

onready var _charging_shoot_attack_behavior: ShootingAttackBehavior = $ChargingShootAttackBehavior
onready var maple_shoot_attack_behavior: Node2D = $MapleShootAttackBehavior
onready var COOLDOWN: float = _charging_shoot_attack_behavior.cooldown
var current_projectiles_cooldown: float = 0.0

# =========================== Extension =========================== #
func respawn() -> void:
    .respawn()
    current_projectiles_cooldown = 0.0

    _charging_shoot_attack_behavior.reset()
    maple_shoot_attack_behavior.reset()

func _ready() -> void:
    _charging_shoot_attack_behavior.init(self )
    maple_shoot_attack_behavior.init(self )
    
    register_attack_behavior(_charging_shoot_attack_behavior)
    register_attack_behavior(maple_shoot_attack_behavior)

func _physics_process(delta: float) -> void:
    current_projectiles_cooldown -= Utils.physics_one(delta)

    if _move_locked and current_projectiles_cooldown <= 0.0 and !dead:
        current_projectiles_cooldown = COOLDOWN
        maple_pos = _charging_shoot_attack_behavior.global_position
        _charging_shoot_attack_behavior.shoot()
        
        maple_shoot_attack_behavior.other_pos = maple_pos
        maple_shoot_attack_behavior.shoot()
