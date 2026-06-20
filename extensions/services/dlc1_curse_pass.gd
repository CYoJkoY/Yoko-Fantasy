extends Reference

# =========================== Extension =========================== #
func apply(
	original_item: ItemParentData,
	cursed_item: ItemParentData,
	player_index: int,
	turn_randomization_off: bool = false,
	min_modifier: float = 0.0,
	dlc_1_data: Object = null
) -> ItemParentData:
	if original_item == null or cursed_item == null or dlc_1_data == null:
		return cursed_item
	if !has_effect_fantasy(original_item.effects):
		return cursed_item

	return _fantasy_curse_item(original_item, cursed_item, player_index, turn_randomization_off, min_modifier, dlc_1_data)

# =========================== Custom =========================== #
func _fantasy_curse_item(
    _original_item: ItemParentData,
	cursed_item: ItemParentData,
	_player_index: int,
	turn_randomization_off: bool,
	min_modifier: float,
	dlc_1_data: Object
) -> ItemParentData:
	var new_item_data: ItemParentData = cursed_item.duplicate()
	var new_effects: Array = []

	for effect in cursed_item.effects:
		if !is_effect_fantasy(effect):
			new_effects.append(effect)
			continue

		var effect_modifier: float = dlc_1_data._get_cursed_item_effect_modifier(turn_randomization_off, min_modifier)
		var new_effect: Effect = effect.duplicate()
		var id: String = new_effect.get_id()
		var key: int = new_effect.key_hash
		var cskey: int = new_effect.custom_key_hash

		match [id, key, cskey]:
			["fantasy_shop_enter_stat_curse", _, _]:
				new_effect.value = 0 if new_effect.value == 1 else new_effect.value
				new_effect.chance = Utils.ncl_curse_effect_value(new_effect.chance, effect_modifier, {"step": 1})
				new_effect.curse_num = Utils.ncl_curse_effect_value(new_effect.curse_num, effect_modifier, {"step": 1})

			["fantasy_melee_pet", _, _], \
			["fantasy_ranged_pet", _, _]:
				new_effect.weapon_stats = dlc_1_data._boost_weapon_stats_damage(new_effect.weapon_stats, effect_modifier)

			["fantasy_damage_clamp", _, _]:
				new_effect.value2 = Utils.ncl_curse_effect_value(new_effect.value2, effect_modifier, {"is_negative": true, "step": 1})

			["fantasy_erosion", _, _]:
				var new_scaling_stats: Array = new_effect.scaling_stats.duplicate()
				new_effect.scaling_stats = dlc_1_data._boost_scaling_sats(new_scaling_stats, effect_modifier)
				new_effect.chance = Utils.ncl_curse_effect_value(new_effect.chance, effect_modifier)
				new_effect.times = Utils.ncl_curse_effect_value(new_effect.times, effect_modifier)

			["fantasy_dmg_when_pickup_consumable", _, _]:
				new_effect.value2 = Utils.ncl_curse_effect_value(new_effect.value2, effect_modifier, {"process_negative": false, "step": 1})
				var new_dmg_scaling_stats: Array = new_effect.scaling_stats.duplicate()
				new_effect.scaling_stats = dlc_1_data._boost_scaling_sats(new_dmg_scaling_stats, effect_modifier)

			["fantasy_periodic_radius_damage", _, _]:
				new_effect.value2 = Utils.ncl_curse_effect_value(new_effect.value2, effect_modifier, {"process_negative": false, "step": 1})
				new_effect.base_cooldown = Utils.ncl_curse_effect_value(new_effect.base_cooldown, effect_modifier, {"is_negative": true, "step": 1})
				var new_radius_scaling_stats: Array = new_effect.scaling_stats.duplicate()
				new_effect.scaling_stats = dlc_1_data._boost_scaling_sats(new_radius_scaling_stats, effect_modifier)
				new_effect.chance = Utils.ncl_curse_effect_value(new_effect.chance, effect_modifier)
				new_effect.times = Utils.ncl_curse_effect_value(new_effect.times, effect_modifier)

			["fantasy_tree_radius_tempstats", _, _]:
				new_effect.range_rate = Utils.ncl_curse_effect_value(new_effect.range_rate, effect_modifier, {"process_negative": false})

			["fantasy_decaying_slow_enemy_when_below_hp", _, _]:
				new_effect.value2 = Utils.ncl_curse_effect_value(new_effect.value2, effect_modifier)
				new_effect.trigger_times = Utils.ncl_curse_effect_value(new_effect.trigger_times, effect_modifier)

			["fantasy_projectiles_every_x_melee_shoot", _, _]:
				new_effect.projectile_stats = dlc_1_data._boost_weapon_stats_damage(new_effect.projectile_stats, effect_modifier)

			[_, _, Utils.fantasy_curse_all_on_reroll_hash]:
				new_effect.text_key += "_CURSED"
				new_item_data.replaced_by = ItemService.get_element(ItemService.items, new_effect.key_hash)

			[_, _, Utils.fantasy_extra_curse_enemy_hash]:
				var extra_effect: Effect = Effect.new()
				extra_effect.key = "number_of_enemies"
				extra_effect.key_hash = Keys.number_of_enemies_hash
				extra_effect.value = new_effect.value
				new_effects.append(extra_effect)

		new_effects.append(new_effect)

	new_item_data.effects = new_effects
	return new_item_data

# =========================== Method =========================== #
func has_effect_fantasy(effects: Array) -> bool:
	for effect in effects:
		if !is_effect_fantasy(effect):
			continue
		return true
	return false


func is_effect_fantasy(effect: Effect) -> bool:
	return effect.get_id().begins_with("fantasy") or \
		effect.key.begins_with("fantasy") or \
		effect.custom_key.begins_with("fantasy")
