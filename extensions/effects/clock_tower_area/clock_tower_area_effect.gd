extends DoubleValueEffect

enum LineType { RADIUS, STRUCTURE_SPAWN, STRUCTURE_ATTACK_SPEED, ENEMY_SLOW, STRUCTURE_DISABLED, AREA }

export(LineType) var line_type = LineType.AREA
export(int) var base_range = 350
export(int) var range_rate = 65

# =========================== Extension =========================== #
static func get_id() -> String:
	return "fantasy_clock_tower_area"

func get_text(player_index: int, colored: bool = true) -> String:
	if line_type == LineType.AREA:
		return ""

	return .get_text(player_index, colored)

func apply(player_index: int) -> void:
	if line_type != LineType.AREA:
		return
	if custom_key == "": return

	var effects = RunData.get_player_effects(player_index)
	effects[custom_key_hash].append([value, value2])

func unapply(player_index: int) -> void:
	if line_type != LineType.AREA:
		return
	if custom_key == "": return

	var effects = RunData.get_player_effects(player_index)
	effects[custom_key_hash].erase([value, value2])

func get_args(player_index: int) -> Array:
	var effect_base_range: int = value if line_type == LineType.AREA else base_range
	var effect_range_rate: float = value2 / 100.0 if line_type == LineType.AREA else range_rate / 100.0
	var text_args: Dictionary = Utils.fa_get_clock_tower_area_text_args(effect_base_range, effect_range_rate, player_index)

	match line_type:
		LineType.AREA:
			return [
				text_args["range_text"],
				text_args["structure_attack_speed_text"],
				text_args["holy_scaling_text"],
				text_args["enemy_slow_text"],
				text_args["engineering_scaling_text"],
			]
		LineType.RADIUS:
			return [text_args["range_text"]]
		LineType.STRUCTURE_ATTACK_SPEED:
			return [text_args["structure_attack_speed_text"], text_args["holy_scaling_text"]]
		LineType.ENEMY_SLOW:
			return [text_args["enemy_slow_text"], text_args["engineering_scaling_text"]]
		_:
			return []
