extends ShootingAttackBehavior

var _second_volley_delay: float = 0.0
var _locked_direction: float = 0.0

# ══════════════════════════════════════════ Extension ══════════════════════════════════════════ #
func _ready() -> void:
    set_physics_process(false)

func reset() -> void:
    .reset()
    _second_volley_delay = 0.0
    set_physics_process(false)

func shoot() -> void:
    _locked_direction = (_parent.current_target.global_position - _parent.global_position).angle()
    _current_cd = get_cd()
    _shoot_volley()
    _second_volley_delay = 0.55
    set_physics_process(true)

func _physics_process(delta: float) -> void:
    if _parent.dead or _parent._current_state != -1:
        set_physics_process(false)
        return
    _second_volley_delay -= delta
    if _second_volley_delay <= 0.0:
        set_physics_process(false)
        _shoot_volley()

# ══════════════════════════════════════════ Method ══════════════════════════════════════════ #
func _shoot_volley() -> void:
    for i in range(number_projectiles):
        var angle: float = _locked_direction - projectile_spread + 2.0 * projectile_spread * i / (number_projectiles - 1)
        spawn_projectile(angle, _parent.global_position, projectile_speed)
    _shots_taken += 1
