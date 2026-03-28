extends Boss

export(PackedScene) var pivots_scene = null

onready var COOLDOWN_0 = _attack_behavior.cooldown
var cooldown_0 = 0.0

var pivots: Node2D = null

# =========================== Extension =========================== #
func _physics_process(delta: float) -> void:
    if _current_state != 1: return

    cooldown_0 -= Utils.physics_one(delta)
    if _move_locked and cooldown_0 <= 0.0 and !dead:
        cooldown_0 = COOLDOWN_0
        _attack_behavior.shoot()

func on_state_changed(new_state: int) -> void:
    .on_state_changed(new_state)

    match new_state:
        0:
            pivots = pivots_scene.instance()
            add_child(pivots)
            for child in pivots.get_bullets():
                register_additional_projectile(child)
        1: current_stats.speed = 0

func die(args := Utils.default_die_args) -> void:
    .die(args)

    if pivots != null: pivots.free_pivots()
