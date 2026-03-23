extends Boss

onready var _mage_circle_attack_behavior: Node2D = $"%MageCircleAttackBehavior"

# =========================== Extension =========================== #
func _ready() -> void:
    _mage_circle_attack_behavior.init(self )

    register_attack_behavior(_mage_circle_attack_behavior)

func shoot() -> void:
    .shoot()
    if _current_state != 0: return

    for i in 3: _mage_circle_attack_behavior.shoot()

# =========================== Method =========================== #
func fa_change_state(boss: Boss) -> void:
    if dead: return

    var _new_state: int = boss._current_state
    if _new_state <= _current_state: return

    SoundManager.play(change_state_sound, 0, 0, true)
    _current_state = _new_state
    _current_movement_behavior = _states[_new_state][2]
    _current_attack_behavior = _states[_new_state][3]
    on_state_changed(_new_state)

func fa_died_change_state(boss: Boss, args: Entity.DieArgs = Utils.default_die_args) -> void:
    if args.cleaning_up: return

    var _new_state: int = clamp(boss._current_state + 1, 0, _states.size() - 1) as int
    if _new_state <= _current_state: return

    SoundManager.play(change_state_sound, 0, 0, true)
    _current_state = _new_state
    _current_movement_behavior = _states[_new_state][2]
    _current_attack_behavior = _states[_new_state][3]
    on_state_changed(_new_state)
