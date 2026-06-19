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

func _physics_process(delta) -> void:
    if dead: return

    var potential_target_count = players_ref.size() + _entity_spawner_ref.targetable_pets.size()
    if potential_target_count > 1 or collision_layer == Utils.PETS_BIT:
        update_target_timer += delta
        if update_target_timer >= UPDATE_TARGET_DELAY:
            update_target_timer = 0.0
            update_target()

    _current_attack_cd = max(_current_attack_cd - 60 * delta, 0)
    var is_being_knocked_back = get_knockback_value().length_squared() > get_move_input().length_squared()

    if not _hitbox.is_disabled() and is_being_knocked_back:
        _hitbox.disable()
    elif _hitbox.is_disabled() and not is_being_knocked_back:
        _hitbox.enable()

    if _can_attack and _current_state == -1:
        _can_attack = false
        _spread_shooting_attack_behavior.shoot()
    
    if _can_attack and _current_state == 0:
        _can_attack = false
        _spread_shooting_attack_behavior2.shoot()

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

    var _new_state: int = int(clamp(boss._current_state + 1, 0, _states.size() - 1))
    if _new_state <= _current_state: return

    SoundManager.play(change_state_sound, 0, 0, true)
    _current_state = _new_state
    _current_movement_behavior = _states[_new_state][2]
    _current_attack_behavior = _states[_new_state][3]
    on_state_changed(_new_state)
