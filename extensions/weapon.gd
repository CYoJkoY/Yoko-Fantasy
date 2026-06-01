extends "res://weapons/weapon.gd"


func should_shoot() -> bool:
	if _fantasy_cannot_attack_while_stationary():
		return false

	return .should_shoot()


func _fantasy_cannot_attack_while_stationary() -> bool:
	if RunData.get_player_effect(Utils.fantasy_cannot_attack_while_stationary_hash, player_index) <= 0:
		return false

	if _parent == null:
		return false

	var current_movement = _parent.get("_current_movement")
	if !(current_movement is Vector2):
		return false

	return current_movement == Vector2.ZERO
