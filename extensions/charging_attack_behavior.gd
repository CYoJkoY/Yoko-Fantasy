extends "res://entities/units/enemies/attack_behaviors/charging_attack_behavior.gd"


func init(parent: Node) -> Node:
    .init(parent)
    if !_parent.is_connected("died", self , "_fantasy_on_parent_died"):
        _parent.connect("died", self , "_fantasy_on_parent_died")

    return self


func on_unlock_move_timer_timeout() -> void:
    if !_fantasy_has_live_parent(): return

    .on_unlock_move_timer_timeout()

func reset() -> void:
    .reset()
    _fantasy_restore_parent_state()


# =========================== Custom =========================== #
func _fantasy_on_parent_died(_entity, _die_args) -> void:
    if is_instance_valid(_unlock_move_timer):
        _unlock_move_timer.stop()
    _fantasy_restore_parent_state()


func _fantasy_restore_parent_state() -> void:
    if !is_instance_valid(_parent):
        return

    _parent._can_move = true
    _parent._move_locked = false
    _parent.bonus_speed = 0
    _parent.mass = _original_mass
    _charge_direction = Vector2.ZERO
    if is_instance_valid(_unlock_move_timer):
        _unlock_move_timer.wait_time = charge_duration
    if is_instance_valid(_parent._animation_player):
        _parent._animation_player.playback_speed = _parent._idle_playback_speed


func _fantasy_has_live_parent() -> bool:
    return is_instance_valid(_parent) and !_parent.dead and _parent.is_inside_tree()
