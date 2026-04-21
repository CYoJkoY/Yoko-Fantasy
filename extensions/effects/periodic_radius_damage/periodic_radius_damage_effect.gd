extends DoubleValueEffect

export(int) var base_cooldown = 180
export(int) var base_damage = 10
export(Array, Array) var scaling_stats = [["stat_fantasy_holy", 1.0]]
export(String) var tracked_key = ""
var tracked_key_hash: int = Keys.empty_hash

# =========================== Extension =========================== #
func duplicate(subresources := false) -> Resource:
	var duplication =.duplicate(subresources)
	if !scaling_stats.empty():
		scaling_stats = Utils.convert_to_hash_array(scaling_stats)
	if tracked_key_hash == Keys.empty_hash and tracked_key != "":
		tracked_key_hash = Keys.generate_hash(tracked_key)

	duplication.scaling_stats = scaling_stats
	duplication.tracked_key_hash = tracked_key_hash

	return duplication

static func get_id() -> String:
	return "fantasy_periodic_radius_damage"

func _generate_hashes() -> void:
	._generate_hashes()
	scaling_stats = Utils.convert_to_hash_array(scaling_stats)
	tracked_key_hash = Keys.generate_hash(tracked_key)

func apply(player_index: int) -> void:
	if key == "": return

	var effects = RunData.get_player_effects(player_index)
	effects[key_hash].append([value, value2, scaling_stats, base_cooldown, base_damage, tracked_key_hash])

func unapply(player_index: int) -> void:
	if key == "": return

	var effects = RunData.get_player_effects(player_index)
	effects[key_hash].erase([value, value2, scaling_stats, base_cooldown, base_damage, tracked_key_hash])

func get_args(player_index: int) -> Array:
	var scaling_dmg: float = Utils.ncl_get_scaling_stats_dmg(scaling_stats, player_index)
	var total_damage: float = base_damage + scaling_dmg
	var dmg_text: String = Utils.ncl_get_dmg_text_with_scaling_stats(total_damage, scaling_stats, base_damage)

	var attack_speed_mod: float = Utils.get_stat(Keys.stat_attack_speed_hash, player_index) / 100.0
	var final_cooldown: float = WeaponService.apply_attack_speed_mod_to_cooldown(base_cooldown, attack_speed_mod)
	var cooldown_text: String = "[color=%s]%s[/color]" % [Utils.ncl_get_signed_col(final_cooldown, base_cooldown, true), final_cooldown / 60.0]

	var range_rate: float = value2 / 100.0
	var total_range: float = Utils.get_stat(Keys.stat_range_hash, player_index) * range_rate + value
	var range_scaling_text: String = Utils.get_scaling_stat_icon_text(Keys.stat_range_hash, range_rate)
	var range_text: String = "[color=%s]%s[/color] (%s)" % [Utils.ncl_get_signed_col(total_range, value), total_range, range_scaling_text]

	return [cooldown_text, range_text, dmg_text]

func serialize() -> Dictionary:
	var serialized: Dictionary =.serialize()
	serialized.base_cooldown = base_cooldown
	serialized.base_damage = base_damage
	serialized.scaling_stats = scaling_stats
	serialized.tracked_key = tracked_key

	return serialized

func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)
	base_cooldown = serialized.base_cooldown
	base_damage = serialized.base_damage
	scaling_stats = Utils.convert_to_hash_array(serialized.get("scaling_stats", [])) as Array
	tracked_key = serialized.tracked_key
	tracked_key_hash = Keys.generate_hash(tracked_key)
