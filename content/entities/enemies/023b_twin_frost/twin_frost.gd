extends Boss

onready var _attack_behavior_small: Node2D = $"%AttackBehaviorSmall"

# =========================== Extension =========================== #
func _ready() -> void:
    _attack_behavior_small.init(self )

    register_attack_behavior(_attack_behavior_small)

func shoot() -> void:
    .shoot()
    if _current_state == 0:
        for i in 3: _attack_behavior_small.shoot()

# =========================== Method =========================== #
func fa_change_state(boss: Boss) -> void:
    var _new_state: int = boss._current_state
    if _new_state <= _current_state: return

    SoundManager.play(change_state_sound, 0, 0, true)
    _current_state = _new_state
    _current_movement_behavior = _states[_new_state][2]
    _current_attack_behavior = _states[_new_state][3]
    on_state_changed(_new_state)

func fa_died_change_state(boss: Boss, _die_args: Entity.DieArgs = Utils.default_die_args) -> void:
    var _new_state: int = clamp(boss._current_state + 1, 0, _states.size() - 1) as int
    if _new_state <= _current_state: return

    SoundManager.play(change_state_sound, 0, 0, true)
    _current_state = _new_state
    _current_movement_behavior = _states[_new_state][2]
    _current_attack_behavior = _states[_new_state][3]
    on_state_changed(_new_state)
