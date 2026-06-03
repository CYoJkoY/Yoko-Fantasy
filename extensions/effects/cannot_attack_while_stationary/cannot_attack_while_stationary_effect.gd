extends Effect


static func get_id() -> String:
	return "fantasy_cannot_attack_while_stationary"


func apply(player_index: int) -> void:
	var effects: Dictionary = RunData.get_player_effects(player_index)
	effects[key_hash] += value


func unapply(player_index: int) -> void:
	var effects: Dictionary = RunData.get_player_effects(player_index)
	effects[key_hash] -= value


func get_args(_player_index: int) -> Array:
	return []
