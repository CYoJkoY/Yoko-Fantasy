extends Effect


export(String) var description_key: String = ""
export(String, MULTILINE) var description_text: String = ""
export(String) var job_id: String = ""
export(int) var job_stage: int = 0
export(int) var job_pending_tier: int = 0
export(int) var job_family: int = 0
export(int) var job_tier: int = 0
var job_id_hash: int = Keys.empty_hash


func duplicate(subresources := false) -> Resource:
	var duplication = .duplicate(subresources)

	if job_id_hash == Keys.empty_hash and job_id != "":
		job_id_hash = Keys.generate_hash(job_id)

	duplication.job_id_hash = job_id_hash
	return duplication


static func get_id() -> String:
	return "fantasy_job_select"


func _generate_hashes() -> void:
	._generate_hashes()

	if job_id != "":
		job_id_hash = Keys.generate_hash(job_id)


func apply(player_index: int) -> void:
	_ensure_job_hash()
	var effects: Dictionary = RunData.get_player_effects(player_index)
	Utils.fantasy_normalize_effect_keys(effects)
	var duplicate_apply: bool = _is_duplicate_apply(effects)

	effects[Utils.fantasy_job_stage_hash] = job_stage
	effects[Utils.fantasy_job_pending_tier_hash] = job_pending_tier
	effects[Utils.fantasy_job_family_hash] = job_family

	if job_tier == 1:
		effects[Utils.fantasy_job_tier1_id_hash] = job_id_hash
	elif job_tier == 2:
		effects[Utils.fantasy_job_tier2_id_hash] = job_id_hash

	if duplicate_apply:
		return

	if _apply_job_runtime_bonuses(effects, 1):
		_request_runtime_stats_refresh(player_index)


func unapply(player_index: int) -> void:
	_ensure_job_hash()
	var effects: Dictionary = RunData.get_player_effects(player_index)
	Utils.fantasy_normalize_effect_keys(effects)
	if _apply_job_runtime_bonuses(effects, -1):
		_request_runtime_stats_refresh(player_index)


func get_text(_player_index: int, _colored: bool = true) -> String:
	if text_key != "":
		var translated_key: String = text_key.to_upper()
		var translated_text: String = tr(translated_key)
		if translated_text != translated_key:
			return translated_text
	if description_text != "":
		return description_text
	if description_key != "":
		return tr(description_key.to_upper())
	return ""


func serialize() -> Dictionary:
	var serialized: Dictionary = .serialize()
	serialized.description_key = description_key
	serialized.description_text = description_text
	serialized.job_id = job_id
	serialized.job_stage = job_stage
	serialized.job_pending_tier = job_pending_tier
	serialized.job_family = job_family
	serialized.job_tier = job_tier

	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)

	description_key = serialized.description_key if "description_key" in serialized else ""
	description_text = serialized.description_text if "description_text" in serialized else ""
	job_id = serialized.job_id if "job_id" in serialized else ""
	job_stage = int(serialized.job_stage) if "job_stage" in serialized else 0
	job_pending_tier = int(serialized.job_pending_tier) if "job_pending_tier" in serialized else 0
	job_family = int(serialized.job_family) if "job_family" in serialized else 0
	job_tier = int(serialized.job_tier) if "job_tier" in serialized else 0

	job_id_hash = Keys.generate_hash(job_id) if job_id != "" else Keys.empty_hash


func _is_duplicate_apply(effects: Dictionary) -> bool:
	_ensure_job_hash()
	if job_id_hash == Keys.empty_hash:
		return false

	if job_tier == 1:
		return Utils.fantasy_hash_equals(int(Utils.fantasy_get_effect_value(effects, Utils.fantasy_job_tier1_id_hash, 0)), job_id_hash)
	if job_tier == 2:
		return Utils.fantasy_hash_equals(int(Utils.fantasy_get_effect_value(effects, Utils.fantasy_job_tier2_id_hash, 0)), job_id_hash)

	return false


func _apply_job_runtime_bonuses(effects: Dictionary, bonus_sign: int) -> bool:
	var changed: bool = false
	var bonuses: Array = _get_job_runtime_bonuses()
	for bonus in bonuses:
		if !(bonus is Array) or bonus.size() < 2:
			continue

		var bonus_key_hash: int = int(bonus[0])
		var bonus_value: int = int(bonus[1]) * bonus_sign
		if effects.has(bonus_key_hash):
			effects[bonus_key_hash] += bonus_value
		else:
			effects[bonus_key_hash] = bonus_value
		changed = true

	changed = _apply_job_runtime_special_bonuses(effects, bonus_sign) or changed

	return changed


func _get_job_runtime_bonuses() -> Array:
	match job_id:
		"swordsman_t1":
			return [
				[Keys.stat_melee_damage_hash, 4],
				[Keys.generate_hash("gain_stat_melee_damage"), 25],
			]
		"archer_t1":
			return [
				[Keys.stat_ranged_damage_hash, 2],
				[Keys.stat_range_hash, 25],
				[Keys.no_melee_weapons_hash, 1],
			]
		"mage_t1":
			return [
				[Keys.stat_elemental_damage_hash, 2],
				[Keys.generate_hash("gain_stat_elemental_damage"), 25],
			]
		"summoner_t1":
			return [
				[Keys.structure_percent_damage_hash, 35],
				[Keys.structure_attack_speed_hash, 35],
			]
		"tank_t1":
			return [
				[Keys.stat_armor_hash, 5],
				[Keys.gain_stat_armor_hash, 25],
			]
		"nurse_t1":
			return [
				[Keys.stat_hp_regeneration_hash, 5],
				[Keys.stat_lifesteal_hash, 5],
			]
		"accountant_t1":
			return [
				[Keys.stat_harvesting_hash, 8],
				[Keys.items_price_hash, -8],
			]
		"musician_t1":
			return [
				[Keys.stat_luck_hash, 20],
			]
		"botanist_t1":
			return [
				[Keys.trees_hash, 4],
				[Keys.neutral_gold_drops_hash, 100],
			]
		"blacksmith_t1":
			return [
				[Utils.fantasy_job_blacksmith_tier3_upgrade_hash, 1],
			]
		"economist_t2":
			return [
				[Keys.items_price_hash, -15],
				[Keys.reroll_price_hash, -50],
			]
		"prophet_t2":
			return [
				[Keys.free_rerolls_hash, 3],
				[Keys.stat_luck_hash, 25],
				[Keys.stat_percent_damage_hash, -10],
				[Keys.stat_attack_speed_hash, -10],
			]
		"walker_t2":
			return [
				[Keys.stat_speed_hash, 5],
			]
		"dual_blade_master_t2":
			return [
				[Keys.stat_attack_speed_hash, 25],
				[Utils.fantasy_job_dual_blade_skip_cooldown_chance_hash, 15],
			]
		"holy_blade_master_t2":
			return [
				[Utils.stat_fantasy_holy_hash, 5],
			]
		"wandering_samurai_t2":
			return [
				[Keys.stat_range_hash, 50],
				[Keys.gain_stat_attack_speed_hash, -25],
			]
		"melee_assassin_t2":
			return [
				[Keys.stat_crit_chance_hash, 10],
				[Keys.stat_range_hash, -50],
			]
		"divine_bow_master_t2":
			return [
				[Keys.piercing_hash, 1],
				[Keys.piercing_damage_hash, 25],
				[Keys.stat_attack_speed_hash, -20],
			]
		"ranged_assassin_t2":
			return [
				[Keys.stat_crit_chance_hash, 10],
				[Keys.generate_hash("gain_stat_percent_damage"), -33],
			]
		"gunner_t2":
			return [
				[Keys.explosion_damage_hash, 35],
				[Keys.explosion_size_hash, 60],
				[Keys.stat_attack_speed_hash, -25],
			]
		"firearms_master_t2":
			return [
				[Keys.stat_percent_damage_hash, -100],
			]
		"holy_taoist_t2":
			return [
				[Keys.stat_elemental_damage_hash, 5],
			]
		"abyss_believer_t2":
			return [
				[Keys.stat_curse_hash, 10],
			]
		"enchanter_t2":
			return []
		"fire_mage_t2":
			return [
				[Keys.can_burn_enemies_hash, 1],
				[Keys.burning_cooldown_reduction_hash, 50],
			]
		"thunder_mage_t2":
			return []
		"dark_mage_t2":
			return [
				[Keys.stat_curse_hash, 5],
				[Keys.enemy_health_hash, 15],
			]
		"engineer_t2":
			return [
				[Keys.stat_engineering_hash, 6],
			]
		"modifier_t2":
			return [
				[Keys.stat_percent_damage_hash, 20],
			]
		"drive_knight_t2":
			return [
				[Keys.stat_speed_hash, 5],
			]
		"temple_guard_t2":
			return [
				[Keys.consumable_heal_hash, 3],
			]
		"land_lord_t2":
			return [
				[Keys.map_size_hash, 25],
				[Keys.pickup_range_hash, 50],
			]
		"treasure_hunter_t2":
			return [
				[Keys.extra_loot_aliens_hash, 1],
				[Keys.recycling_gains_hash, 50],
			]
		"perfumer_t2":
			return []
		"spirit_caller_t2":
			return [
				[Keys.projectiles_hash, 1],
				[Keys.stat_percent_damage_hash, -50],
			]
		"missionary_t2":
			return [
				[Utils.stat_fantasy_holy_hash, 5],
			]

	return []


func _apply_job_runtime_special_bonuses(effects: Dictionary, bonus_sign: int) -> bool:
	var changed: bool = false

	match job_id:
		"blacksmith_t1":
			# Cleanup legacy entry from previous implementation to avoid upgrading non-tier-III weapons.
			var legacy_entry: Array = [Keys.stat_harvesting_hash, 0]
			var legacy_upgrade_effects: Array = effects.get(Keys.upgrade_random_weapon_hash, [])
			if legacy_upgrade_effects.has(legacy_entry):
				legacy_upgrade_effects.erase(legacy_entry)
				effects[Keys.upgrade_random_weapon_hash] = legacy_upgrade_effects
				changed = true
		"walker_t2":
			var speed_to_attack_speed_link: Array = [Keys.stat_attack_speed_hash, 1, Keys.stat_speed_hash, 1, false]
			changed = _apply_array_effect_entry(effects, Keys.stat_links_hash, speed_to_attack_speed_link, bonus_sign) or changed
		"musician_t1":
			var music_attack_speed_entry: Array = [Utils.fantasy_set_musical_hash, Keys.generate_hash("attack_speed_mod"), 25]
			changed = _apply_array_effect_entry(effects, Keys.weapon_class_bonus_hash, music_attack_speed_entry, bonus_sign) or changed
		"holy_blade_master_t2":
			var holy_to_melee_link: Array = [Keys.stat_melee_damage_hash, 1, Utils.stat_fantasy_holy_hash, 1, false]
			changed = _apply_array_effect_entry(effects, Keys.stat_links_hash, holy_to_melee_link, bonus_sign) or changed
		"wandering_samurai_t2":
			var bonus_above_hp_entry: Array = [50, 90]
			changed = _apply_array_effect_entry(effects, Keys.bonus_damage_against_targets_above_hp_hash, bonus_above_hp_entry, bonus_sign) or changed
		"melee_assassin_t2":
			changed = _apply_crit_damage_weapon_type_bonus(effects, 50, bonus_sign) or changed
		"ranged_assassin_t2":
			changed = _apply_crit_damage_weapon_type_bonus(effects, 100, bonus_sign) or changed
		"firearms_master_t2":
			var gun_damage_bonus_entry: Array = [Keys.generate_hash("set_gun"), Keys.stat_percent_damage_hash, 150]
			changed = _apply_array_effect_entry(effects, Keys.weapon_class_bonus_hash, gun_damage_bonus_entry, bonus_sign) or changed
			var gun_to_ranged_damage_link: Array = [Keys.stat_ranged_damage_hash, 1, Utils.fantasy_job_gun_weapon_count_hash, 1, true]
			changed = _apply_array_effect_entry(effects, Keys.stat_links_hash, gun_to_ranged_damage_link, bonus_sign) or changed
		"holy_taoist_t2":
			var elemental_to_holy_link: Array = [Utils.stat_fantasy_holy_hash, 1, Utils.fantasy_job_elemental_weapon_count_hash, 1, true]
			changed = _apply_array_effect_entry(effects, Keys.stat_links_hash, elemental_to_holy_link, bonus_sign) or changed
		"abyss_believer_t2":
			var extra_curse_enemy_entry: Array = [job_id_hash, 10]
			changed = _apply_array_effect_entry(effects, Utils.fantasy_extra_curse_enemy_hash, extra_curse_enemy_entry, bonus_sign) or changed
			var cursed_enemy_speed_value: int = -30 * bonus_sign
			effects[Utils.fantasy_job_cursed_enemy_base_speed_percent_hash] = int(effects.get(Utils.fantasy_job_cursed_enemy_base_speed_percent_hash, 0)) + cursed_enemy_speed_value
			changed = true
		"enchanter_t2":
			var elemental_damage_scaling_entry: Array = [Keys.stat_elemental_damage_hash, 10]
			changed = _apply_array_effect_entry(effects, Keys.weapon_scaling_stats_hash, elemental_damage_scaling_entry, bonus_sign) or changed
			var elemental_to_attack_speed_link: Array = [Keys.stat_attack_speed_hash, 1, Keys.stat_elemental_damage_hash, 1, false]
			changed = _apply_array_effect_entry(effects, Keys.stat_links_hash, elemental_to_attack_speed_link, bonus_sign) or changed
			var weapon_count_to_elemental_link: Array = [Keys.stat_elemental_damage_hash, -1, Utils.fantasy_job_total_weapon_count_hash, 1, true]
			changed = _apply_array_effect_entry(effects, Keys.stat_links_hash, weapon_count_to_elemental_link, bonus_sign) or changed
		"fire_mage_t2":
			Utils.fantasy_set_effect_value(
				effects,
				Utils.fantasy_job_fire_mage_active_hash,
				int(Utils.fantasy_get_effect_value(effects, Utils.fantasy_job_fire_mage_active_hash, 0)) + bonus_sign
			)
			changed = true
			changed = _apply_burn_chance_bonus(effects, bonus_sign) or changed
		"thunder_mage_t2":
			Utils.fantasy_set_effect_value(
				effects,
				Utils.fantasy_job_thunder_mage_active_hash,
				int(Utils.fantasy_get_effect_value(effects, Utils.fantasy_job_thunder_mage_active_hash, 0)) + bonus_sign
			)
			changed = true
			var thunder_projectile_count: int = bonus_sign
			Utils.fantasy_set_effect_value(
				effects,
				Utils.fantasy_job_thunder_projectile_on_death_hash,
				int(Utils.fantasy_get_effect_value(effects, Utils.fantasy_job_thunder_projectile_on_death_hash, 0)) + thunder_projectile_count
			)
			changed = true
		"dark_mage_t2":
			var curse_to_elemental_link: Array = [Keys.stat_elemental_damage_hash, 1, Keys.stat_curse_hash, 8, false]
			changed = _apply_array_effect_entry(effects, Keys.stat_links_hash, curse_to_elemental_link, bonus_sign) or changed
		"engineer_t2":
			var engineering_scaling_entry: Array = [Keys.stat_engineering_hash, 20]
			changed = _apply_array_effect_entry(effects, Keys.weapon_scaling_stats_hash, engineering_scaling_entry, bonus_sign) or changed
		"modifier_t2":
			var percent_to_structure_link: Array = [Keys.structure_percent_damage_hash, 1, Keys.stat_percent_damage_hash, 1, false]
			changed = _apply_array_effect_entry(effects, Keys.stat_links_hash, percent_to_structure_link, bonus_sign) or changed
		"drive_knight_t2":
			var speed_to_engineering_link: Array = [Keys.stat_engineering_hash, 1, Keys.stat_speed_hash, 2, false]
			changed = _apply_array_effect_entry(effects, Keys.stat_links_hash, speed_to_engineering_link, bonus_sign) or changed
		"temple_guard_t2":
			var elemental_to_armor_link: Array = [Keys.stat_armor_hash, 1, Utils.fantasy_job_elemental_weapon_count_hash, 1, true]
			changed = _apply_array_effect_entry(effects, Keys.stat_links_hash, elemental_to_armor_link, bonus_sign) or changed
		"perfumer_t2":
			var consumable_attack_speed_entry: Array = [Keys.stat_attack_speed_hash, 20, 5]
			var consumable_speed_entry: Array = [Keys.stat_speed_hash, 10, 5]
			var consumable_armor_entry: Array = [Keys.stat_armor_hash, 3, 5]
			changed = _apply_array_effect_entry(effects, Keys.decaying_stats_on_consumable_hash, consumable_attack_speed_entry, bonus_sign) or changed
			changed = _apply_array_effect_entry(effects, Keys.decaying_stats_on_consumable_hash, consumable_speed_entry, bonus_sign) or changed
			changed = _apply_array_effect_entry(effects, Keys.decaying_stats_on_consumable_hash, consumable_armor_entry, bonus_sign) or changed
		"spirit_caller_t2":
			effects[Utils.fantasy_structure_elemental_damage_scale_hash] = int(effects.get(Utils.fantasy_structure_elemental_damage_scale_hash, 0)) + (35 * bonus_sign)
			changed = true
		"missionary_t2":
			var tier_iv_to_holy_bonus: Array = [Utils.stat_fantasy_holy_hash, 1]
			changed = _apply_array_effect_entry(effects, Keys.tier_iv_weapon_effects_hash, tier_iv_to_holy_bonus, bonus_sign) or changed

	return changed


func _apply_crit_damage_weapon_type_bonus(effects: Dictionary, crit_damage_percent: int, bonus_sign: int) -> bool:
	var changed: bool = false
	var crit_damage_delta: float = crit_damage_percent / 100.0
	var melee_bonus_entry: Array = [WeaponType.MELEE, Keys.crit_damage_hash, crit_damage_delta]
	var ranged_bonus_entry: Array = [WeaponType.RANGED, Keys.crit_damage_hash, crit_damage_delta]

	changed = _apply_array_effect_entry(effects, Keys.weapon_type_bonus_hash, melee_bonus_entry, bonus_sign) or changed
	changed = _apply_array_effect_entry(effects, Keys.weapon_type_bonus_hash, ranged_bonus_entry, bonus_sign) or changed
	return changed


func _apply_array_effect_entry(effects: Dictionary, effect_key_hash: int, entry: Array, bonus_sign: int) -> bool:
	var effect_entries: Array = effects.get(effect_key_hash, [])

	if bonus_sign > 0:
		effect_entries.push_back(entry)
		effects[effect_key_hash] = effect_entries
		return true

	if effect_entries.has(entry):
		effect_entries.erase(entry)
		effects[effect_key_hash] = effect_entries
		return true

	effects[effect_key_hash] = effect_entries
	return false


func _apply_burn_chance_bonus(effects: Dictionary, bonus_sign: int) -> bool:
	var burn_chance = Utils.fantasy_get_effect_value(effects, Keys.burn_chance_hash, BurningData.new())
	if !(burn_chance is BurningData):
		burn_chance = BurningData.new()
	var burning_data_resource: Resource = load("res://items/all/scared_sausage/scared_sausage_burning_data.tres")
	if burning_data_resource == null:
		return false
	var burning_data = burning_data_resource.duplicate(true)
	if !(burning_data is BurningData):
		return false
	burning_data._late_init()
	burning_data.is_global_burn = true
	burning_data.duration = 5

	if bonus_sign > 0:
		burn_chance.merge(burning_data)
		Utils.fantasy_set_effect_value(effects, Keys.burn_chance_hash, burn_chance)
		return true

	burn_chance.remove(burning_data)
	Utils.fantasy_set_effect_value(effects, Keys.burn_chance_hash, burn_chance)
	return true


func _request_runtime_stats_refresh(player_index: int) -> void:
	RunData._are_player_stats_dirty[player_index] = true
	Utils.reset_stat_cache(player_index)
	LinkedStats.reset_player(player_index)

	var scene_root: Node = Utils.get_scene_node()
	if scene_root != null and scene_root.has_method("fantasy_force_refresh_player_weapons"):
		scene_root.call_deferred("fantasy_force_refresh_player_weapons", player_index)
	if scene_root != null and scene_root.has_method("on_stats_updated"):
		scene_root.call_deferred("on_stats_updated", player_index)


func _ensure_job_hash() -> void:
	if job_id_hash == Keys.empty_hash and job_id != "":
		job_id_hash = Keys.generate_hash(job_id)
