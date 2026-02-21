extends "res://mods-unpacked/Yoko-Fantasy/content/entities/enemies/006_medium_slime/scene/medium_slime.gd"

onready var _shoot_projectiles_behavior: ShootingAttackBehavior = $ShootAttackBehavior
onready var COOLDOWN: float = _shoot_projectiles_behavior.cooldown
var current_projectiles_cooldown: float = 0.0

onready var _slime_trail_attack_behavior: AttackBehavior = $"SlimeTrailAttackBehavior"
onready var COOLDOWN_2: float = _slime_trail_attack_behavior.cooldown
var current_slime_trail_cooldown_2: float = 0.0

# =========================== Extension =========================== #
func _ready() -> void:
    _shoot_projectiles_behavior.init(self )
    _slime_trail_attack_behavior.init(self )

    _all_attack_behaviors.append(_shoot_projectiles_behavior)
    _all_attack_behaviors.append(_slime_trail_attack_behavior)

func _physics_process(delta) -> void:
    current_projectiles_cooldown = max(0.0, current_projectiles_cooldown - Utils.physics_one(delta))
    if current_projectiles_cooldown <= 0.0 and not dead:
        current_projectiles_cooldown = COOLDOWN
        _shoot_projectiles_behavior.shoot()
    
    current_slime_trail_cooldown_2 = max(0.0, current_slime_trail_cooldown_2 - Utils.physics_one(delta))
    if current_slime_trail_cooldown_2 <= 0 and !dead:
        current_slime_trail_cooldown_2 = COOLDOWN_2
        _slime_trail_attack_behavior.shoot()
