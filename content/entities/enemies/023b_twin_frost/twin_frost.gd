extends Boss

onready var _spread_shooting_attack_behavior: ShootingAttackBehavior = $"SpreadAttackBehavior"
onready var _spread_shooting_attack_behavior2: ShootingAttackBehavior = $"%SpreadAttackBehavior2"

var _attack_times: int = 0
var _can_attack: bool = false

# =========================== Extension =========================== #
func _ready() -> void:
    _spread_shooting_attack_behavior.init(self )
    _spread_shooting_attack_behavior2.init(self )

    register_attack_behavior(_spread_shooting_attack_behavior)
    register_attack_behavior(_spread_shooting_attack_behavior2)

func shoot() -> void:
    .shoot()
    _attack_times += 1
    if _attack_times % 2 == 0: _can_attack = true

func _physics_process(_delta) -> void:
    if _can_attack and _current_state == -1:
        _can_attack = false
        _spread_shooting_attack_behavior.shoot()
    
    if _can_attack and _current_state == 0:
        _can_attack = false
        _spread_shooting_attack_behavior2.shoot()

# =========================== Method =========================== #
func fa_change_state(boss: Boss) -> void:
    var _new_state: int = boss._current_state
    SoundManager.play(change_state_sound, 0, 0, true)
    _current_state = _new_state
    _current_movement_behavior = _states[_new_state][2]
    _current_attack_behavior = _states[_new_state][3]
    on_state_changed(_new_state)
