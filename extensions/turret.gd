extends "res://entities/structures/turret/turret.gd"

const TURRET_BASE_SPEED = 225

# =========================== Extension =========================== #
func _physics_process(delta: float) -> void:
    _fantasy_pursue_target(delta)

# =========================== Custom =========================== #
func _fantasy_pursue_target(delta: float) -> void:
    if !get_meta("can_pursue", true) or \
    _current_target.size() <= 0 or \
    !is_instance_valid(_current_target[0]) or \
    !RunData.get_player_effect_bool(Utils.fantasy_turret_can_pursue_target_hash, player_index): return

    var traget_position: Vector2 = _current_target[0].global_position
    global_position = global_position.move_toward(traget_position, TURRET_BASE_SPEED * delta)
