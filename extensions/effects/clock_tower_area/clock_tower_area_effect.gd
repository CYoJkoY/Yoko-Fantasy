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
	var text_args: Dictionary = _get_clock_tower_area_text_args(effect_base_range, effect_range_rate, player_index)

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

func _get_clock_tower_area_text_args(effect_base_range: int, effect_range_rate: float, player_index: int) -> Dictionary:
	var total_range: int = int(Utils.fa_get_clock_tower_area_radius(effect_base_range, effect_range_rate, player_index))
	var range_scaling_text: String = _get_scaling_stat_icon_text(Keys.stat_range_hash, effect_range_rate)
	var range_text: String = _get_signed_text(total_range, effect_base_range) + " (" + range_scaling_text + ")"
	var structure_attack_speed: int = Utils.fa_get_clock_tower_structure_attack_speed_bonus(player_index)
	var structure_attack_speed_text: String = _get_signed_text(structure_attack_speed, 0, true)
	var holy_scaling_text: String = _get_scaling_stat_icon_text(Utils.stat_fantasy_holy_hash, 4.0)
	var enemy_slow: int = Utils.fa_get_clock_tower_enemy_speed_percent(player_index)
	var enemy_slow_text: String = _get_signed_text(enemy_slow, 0, false, true)
	var engineering_scaling_text: String = _get_scaling_stat_icon_text(Keys.stat_engineering_hash, -0.5)

	return {
		"range_text": range_text,
		"structure_attack_speed_text": structure_attack_speed_text,
		"holy_scaling_text": holy_scaling_text,
		"enemy_slow_text": enemy_slow_text,
		"engineering_scaling_text": engineering_scaling_text,
	}

func _get_scaling_stat_icon_text(stat_hash: int, scaling: float = 1.0, show_plus_prefix: bool = true, reverse: bool = false) -> String:
	var icon_size: float = 15 * ProgressData.settings.font_size
	var prefix: String = "+" if show_plus_prefix and scaling > 0.0 else ""
	var color: String = Utils.ncl_get_signed_col(scaling, 0, reverse)
	var scaling_text: String = "[color=%s]%s%s%%[/color]" % [color, prefix, str(round(scaling * 100.0))]
	var small_icon: Texture = ItemService.get_stat_small_icon(stat_hash)
	return "%s[img=%sx%s]%s[/img]" % [scaling_text, icon_size, icon_size, small_icon.resource_path]

func _get_signed_text(value_to_show: int, base_value: int = 0, show_plus_prefix: bool = false, reverse: bool = false) -> String:
	var prefix: String = "+" if show_plus_prefix and value_to_show > 0 else ""
	return "[color=%s]%s%s[/color]" % [Utils.ncl_get_signed_col(value_to_show, base_value, reverse), prefix, str(value_to_show)]
