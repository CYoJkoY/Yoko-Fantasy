extends Effect

export(int) var resonance_min_towers = 3

func apply(_player_index: int) -> void:
	pass

func unapply(_player_index: int) -> void:
	pass

func get_args(_player_index: int) -> Array:
	return [str(resonance_min_towers)]

func serialize() -> Dictionary:
	var serialized = .serialize()
	serialized.resonance_min_towers = resonance_min_towers
	return serialized

func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)
	resonance_min_towers = serialized.get("resonance_min_towers", resonance_min_towers) as int
