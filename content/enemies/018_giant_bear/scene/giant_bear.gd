extends Enemy

var current_projectiles_cooldown: float = 0.0

onready var _charging_shoot_attack_behavior = $ChargingShootAttackBehavior

const STAND_SPRITE = preload("res://mods-unpacked/Yoko-Fantasy/content/enemies/018_giant_bear/scene/giant_bear_stand.webp")
const STAND_FOUR_SPRITE = preload("res://mods-unpacked/Yoko-Fantasy/content/enemies/018_giant_bear/scene/giant_bear_stand_four.webp")
const SPRINT_SPRITE = preload("res://mods-unpacked/Yoko-Fantasy/content/enemies/018_giant_bear/scene/giant_bear_sprint.webp")

func respawn()->void :
    .respawn()
    current_projectiles_cooldown = 0.0


func _ready()->void :
    _charging_shoot_attack_behavior.init(self)
    
    _all_attack_behaviors.push_back(_charging_shoot_attack_behavior)


func _physics_process(delta: float)->void :
    current_projectiles_cooldown = max(0.0, current_projectiles_cooldown - Utils.physics_one(delta))
 
    if bonus_speed > 0 and current_projectiles_cooldown <= 0.0 and not dead:
        current_projectiles_cooldown = _charging_shoot_attack_behavior.cooldown
        _charging_shoot_attack_behavior.shoot()
        sprite.texture = STAND_SPRITE
        _collision.position.y = -16
        _hurtbox.position.y = 11
        _hitbox.position.y = 26
    
    if _animation_player.current_animation == "idle" and \
    bonus_speed <= 0 and not dead:
        sprite.texture = STAND_FOUR_SPRITE
        _collision.position.y = -43
        _hurtbox.position.y = -16
        _hitbox.position.y = -1
