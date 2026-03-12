extends "res://entities/structures/turret/turret.gd"

const TURRET_BASE_SPEED = 225

var can_pursue: bool = false

# =========================== Extension =========================== #
func _ready() -> void:
    _fantasy_can_pursue(self )

func _physics_process(delta: float) -> void:
    _fantasy_pursue_target(delta)

# =========================== Custom =========================== #
func _fantasy_can_pursue(turret: Turret) -> void:
    can_pursue = !(
        turret is WanderingBot or \
        turret is Garden
    )


func _fantasy_pursue_target(delta: float) -> void:
    if !can_pursue or \
    _current_target.size() <= 0 or \
    !is_instance_valid(_current_target[0]) or \
    !RunData.get_player_effect_bool(Utils.fantasy_turret_can_pursue_target_hash, player_index): return

    var traget_position: Vector2 = _current_target[0].global_position
    global_position = global_position.move_toward(traget_position, TURRET_BASE_SPEED * delta)
