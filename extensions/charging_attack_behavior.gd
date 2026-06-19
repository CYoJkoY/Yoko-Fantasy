extends "res://entities/units/enemies/attack_behaviors/charging_attack_behavior.gd"


func init(parent: Node) -> Node:
    .init(parent)
    if !_parent.is_connected("died", self , "_fantasy_on_parent_died"):
        _parent.connect("died", self , "_fantasy_on_parent_died")

    return self


func on_unlock_move_timer_timeout() -> void:
    if !_fantasy_has_live_parent(): return

    .on_unlock_move_timer_timeout()


# =========================== Custom =========================== #
func _fantasy_on_parent_died(_entity, _die_args) -> void:
    if is_instance_valid(_unlock_move_timer):
        _unlock_move_timer.stop()


func _fantasy_has_live_parent() -> bool:
    return is_instance_valid(_parent) and !_parent.dead and _parent.is_inside_tree()
