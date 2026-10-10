extends DoubleValueEffect

export(int) var base_damage: int = 5
export(Array, Array) var scaling_stats = [["stat_fantasy_holy", 1.0], ["stat_luck", 0.1]]
export(Color) var damage_color: Color = Color("#f6c453")


func duplicate(subresources := false) -> Resource:
	var duplication = .duplicate(subresources)
	if !scaling_stats.empty():
		scaling_stats = Utils.convert_to_hash_array(scaling_stats)
	duplication.scaling_stats = scaling_stats
	return duplication


static func get_id() -> String:
	return "fantasy_tambourine_shockwave"


func _generate_hashes() -> void:
	._generate_hashes()
	scaling_stats = Utils.convert_to_hash_array(scaling_stats)


func get_args(player_index: int) -> Array:
	var blast_stats: MeleeWeaponStats = get_explosion_stats()
	var damage: int = WeaponService.get_explosion_damage(blast_stats, player_index)
	var damage_text: String = "[color=%s]%s[/color]" % [Utils.ncl_get_signed_col(damage, base_damage), str(damage)]
	if damage != base_damage:
		damage_text += " [color=%s]|%s[/color]" % [Utils.GRAY_COLOR_STR, str(base_damage)]
	damage_text += " (" + WeaponService.get_scaling_stats_icon_text(blast_stats.scaling_stats) + ")"
	return [str(value), str(value2), damage_text]


func get_explosion_stats() -> MeleeWeaponStats:
	var blast_stats: MeleeWeaponStats = MeleeWeaponStats.new()
	blast_stats.damage = base_damage
	blast_stats.scaling_stats = scaling_stats
	return blast_stats


func serialize() -> Dictionary:
	var serialized: Dictionary = .serialize()
	serialized.base_damage = base_damage
	serialized.scaling_stats = scaling_stats
	serialized.damage_color = damage_color.to_html()
	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)
	base_damage = serialized.get("base_damage", 5) as int
	scaling_stats = Utils.convert_to_hash_array(serialized.get("scaling_stats", []))
	damage_color = Color(serialized.get("damage_color", "f6c453"))
