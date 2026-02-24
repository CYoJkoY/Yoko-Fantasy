extends "res://mods-unpacked/Yoko-Fantasy/content/entities/enemies/006_medium_slime/medium_slime.gd"

onready var _shoot_projectiles_behavior: ShootingAttackBehavior = $ShootAttackBehavior
onready var COOLDOWN0: float = _shoot_projectiles_behavior.cooldown
var current_projectiles_cooldown_0: float = 0.0

onready var _slime_trail_attack_behavior: AttackBehavior = $"SlimeTrailAttackBehavior"
onready var COOLDOWN1: float = _slime_trail_attack_behavior.cooldown
var current_slime_trail_cooldown_1: float = 0.0

# =========================== Extension =========================== #
func respawn() -> void:
    .respawn()
    current_projectiles_cooldown_0 = 0.0
    current_slime_trail_cooldown_1 = 0.0

    _shoot_projectiles_behavior.reset()

func _ready() -> void:
    _shoot_projectiles_behavior.init(self )
    _slime_trail_attack_behavior.init(self )

    register_attack_behavior(_shoot_projectiles_behavior)
    register_attack_behavior(_slime_trail_attack_behavior)

func _physics_process(delta) -> void:
    current_projectiles_cooldown_0 -= Utils.physics_one(delta)
    if current_projectiles_cooldown_0 <= 0.0 and !dead:
        current_projectiles_cooldown_0 = COOLDOWN0
        _shoot_projectiles_behavior.shoot()
    
    current_slime_trail_cooldown_1 -= Utils.physics_one(delta)
    if current_slime_trail_cooldown_1 <= 0 and !dead:
        current_slime_trail_cooldown_1 = COOLDOWN1
        _slime_trail_attack_behavior.shoot()
