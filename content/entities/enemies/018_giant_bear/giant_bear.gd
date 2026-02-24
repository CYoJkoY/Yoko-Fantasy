extends Enemy

const STAND_SPRITE = preload("res://mods-unpacked/Yoko-Fantasy/content/entities/enemies/018_giant_bear/giant_bear_stand.webp")
const STAND_FOUR_SPRITE = preload("res://mods-unpacked/Yoko-Fantasy/content/entities/enemies/018_giant_bear/giant_bear_stand_four.webp")

onready var _charging_shoot_attack_behavior: ShootingAttackBehavior = $"ChargingShootAttackBehavior"
onready var COOLDOWN: float = _charging_shoot_attack_behavior.cooldown
onready var current_projectiles_cooldown: float = 0.0

# =========================== Extension =========================== #
func respawn() -> void:
    .respawn()
    current_projectiles_cooldown = 0.0

    _charging_shoot_attack_behavior.reset()

func _ready() -> void:
    _charging_shoot_attack_behavior.init(self )
    
    register_attack_behavior(_charging_shoot_attack_behavior)

func _physics_process(delta: float) -> void:
    current_projectiles_cooldown -= Utils.physics_one(delta)
 
    if _move_locked and current_projectiles_cooldown <= 0.0 and !dead:
        current_projectiles_cooldown = COOLDOWN
        _charging_shoot_attack_behavior.shoot()
        sprite.texture = STAND_SPRITE
        _collision.position.y = 10
        _hurtbox.position.y = 11
        _hitbox.position.y = 26

    if _animation_player.current_animation == "idle" and !_move_locked and !dead:
        sprite.texture = STAND_FOUR_SPRITE
        _collision.position.y = -17
        _hurtbox.position.y = -16
        _hitbox.position.y = -1
