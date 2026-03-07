extends "res://singletons/utils.gd"

const ENABLE_YOKO_MANUAL_AIM_COMPAT_FIX: bool = true
const FANTASY_HASH_UINT32_RANGE: int = 4294967296
const FANTASY_HASH_INT32_MAX: int = 2147483647

# Stats
var stat_fantasy_holy_hash: int = Keys.generate_hash("stat_fantasy_holy")
var gain_stat_fantasy_holy_hash: int = Keys.generate_hash("gain_stat_fantasy_holy")
var stat_fantasy_soul_hash: int = Keys.generate_hash("stat_fantasy_soul")
var gain_stat_fantasy_soul_hash: int = Keys.generate_hash("gain_stat_fantasy_soul")
var stat_fantasy_living_cursed_enemy_hash: int = Keys.generate_hash("stat_fantasy_living_cursed_enemy")
var gain_stat_fantasy_living_cursed_enemy_hash: int = Keys.generate_hash("gain_stat_fantasy_living_cursed_enemy")
var stat_fantasy_decaying_slow_enemy_hash: int = Keys.generate_hash("stat_fantasy_decaying_slow_enemy")
var gain_stat_fantasy_decaying_slow_enemy_hash: int = Keys.generate_hash("gain_stat_fantasy_decaying_slow_enemy")

# Effects
var fantasy_original_speed_hash: int = Keys.generate_hash("fantasy_original_speed")
var fantasy_soul_bonus_hash: int = Keys.generate_hash("fantasy_soul_bonus")
var fantasy_time_bonus_current_health_damage_hash: int = Keys.generate_hash("fantasy_time_bonus_current_health_damage")
var fantasy_shop_enter_stat_curse_hash: int = Keys.generate_hash("fantasy_shop_enter_stat_curse")
var fantasy_damage_clamp_hash: int = Keys.generate_hash("fantasy_damage_clamp")
var fantasy_damage_reflect_hash: int = Keys.generate_hash("fantasy_damage_reflect")
var fantasy_curse_all_on_reroll_hash: int = Keys.generate_hash("fantasy_curse_all_on_reroll")
var fantasy_extra_curse_enemy_hash: int = Keys.generate_hash("fantasy_extra_curse_enemy")
var fantasy_crit_overflow_hash: int = Keys.generate_hash("fantasy_crit_overflow")
var fantasy_random_reload_when_pickup_gold_hash: int = Keys.generate_hash("fantasy_random_reload_when_pickup_gold")
var fantasy_erosion_hash: int = Keys.generate_hash("fantasy_erosion")
var fantasy_erosion_can_crit_hash: int = Keys.generate_hash("fantasy_erosion_can_crit")
var fantasy_erosion_speed_hash: int = Keys.generate_hash("fantasy_erosion_speed")
var fantasy_extra_elites_next_wave_hash: int = Keys.generate_hash("fantasy_extra_elites_next_wave")
var fantasy_extra_curse_item_hash: int = Keys.generate_hash("fantasy_extra_curse_item")
var fantasy_gain_temp_stat_every_killed_enemies_hash: int = Keys.generate_hash("fantasy_gain_temp_stat_every_killed_enemies")
var fantasy_decaying_slow_enemy_when_below_hp_hash: int = Keys.generate_hash("fantasy_decaying_slow_enemy_when_below_hp")
var fantasy_job_stage_hash: int = Keys.generate_hash("fantasy_job_stage")
var fantasy_job_pending_tier_hash: int = Keys.generate_hash("fantasy_job_pending_tier")
var fantasy_job_family_hash: int = Keys.generate_hash("fantasy_job_family")
var fantasy_job_tier1_id_hash: int = Keys.generate_hash("fantasy_job_tier1_id")
var fantasy_job_tier2_id_hash: int = Keys.generate_hash("fantasy_job_tier2_id")
var fantasy_job_blacksmith_tier3_upgrade_hash: int = Keys.generate_hash("fantasy_job_blacksmith_tier3_upgrade")
var fantasy_job_dual_blade_skip_cooldown_chance_hash: int = Keys.generate_hash("fantasy_job_dual_blade_skip_cooldown_chance")
var fantasy_job_elemental_weapon_count_hash: int = Keys.generate_hash("fantasy_job_elemental_weapon_count")
var fantasy_job_gun_weapon_count_hash: int = Keys.generate_hash("fantasy_job_gun_weapon_count")
var fantasy_job_musical_weapon_count_hash: int = Keys.generate_hash("fantasy_job_musical_weapon_count")
var fantasy_job_has_musical_weapon_hash: int = Keys.generate_hash("fantasy_job_has_musical_weapon")
var fantasy_job_total_weapon_count_hash: int = Keys.generate_hash("fantasy_job_total_weapon_count")
var fantasy_cursed_enemy_speed_percent_hash: int = Keys.generate_hash("fantasy_cursed_enemy_speed_percent")
var fantasy_job_cursed_enemy_base_speed_percent_hash: int = Keys.generate_hash("fantasy_job_cursed_enemy_base_speed_percent")
var fantasy_job_thunder_projectile_on_death_hash: int = Keys.generate_hash("fantasy_job_thunder_projectile_on_death")
var fantasy_job_dark_mage_kill_counter_hash: int = Keys.generate_hash("fantasy_job_dark_mage_kill_counter")
var fantasy_job_fire_mage_active_hash: int = Keys.generate_hash("fantasy_job_fire_mage_active")
var fantasy_job_thunder_mage_active_hash: int = Keys.generate_hash("fantasy_job_thunder_mage_active")
var fantasy_structure_elemental_damage_scale_hash: int = Keys.generate_hash("fantasy_structure_elemental_damage_scale")
var fantasy_set_elemental_hash: int = Keys.generate_hash("set_elemental")
var fantasy_set_gun_hash: int = Keys.generate_hash("set_gun")
var fantasy_set_music_hash: int = Keys.generate_hash("set_music")
var fantasy_set_musical_hash: int = Keys.generate_hash("set_musical")

# Consumables
var consumable_fantasy_soul_hash: int = Keys.generate_hash("consumable_fantasy_soul")


func get_focus_emulator(player_index: int, root = get_scene_node()) -> FocusEmulator:
	var base_focus: FocusEmulator = .get_focus_emulator(player_index, root)
	if is_instance_valid(base_focus):
		return base_focus

	var scene_root: Node = root
	if scene_root == null:
		scene_root = get_scene_node()
	if scene_root == null:
		return null

	var direct_focus: Node = scene_root.get_node_or_null("FocusEmulator")
	if direct_focus is FocusEmulator:
		return direct_focus as FocusEmulator

	var recursive_focus: Node = scene_root.find_node("FocusEmulator", true, false)
	if recursive_focus is FocusEmulator:
		return recursive_focus as FocusEmulator

	return null


func is_manual_aim(player_index: int) -> bool:
	if !ENABLE_YOKO_MANUAL_AIM_COMPAT_FIX:
		return .is_manual_aim(player_index)

	var is_manual = _manual_aim_cache[player_index]
	if is_manual != null:
		return is_manual

	var uses_gamepad: bool = is_player_using_gamepad(player_index)
	var is_gamepad_pressed: bool = uses_gamepad and get_player_rjoy_vector(player_index).length_squared() > 0.05
	var allow_mouse_for_player: bool = !RunData.is_coop_run or (player_index == 0 and !uses_gamepad)
	var is_mouse_pressed: bool = allow_mouse_for_player and Input.is_mouse_button_pressed(BUTTON_LEFT)

	if ProgressData.settings.manual_aim_on_mouse_press:
		is_manual = is_mouse_pressed or is_gamepad_pressed
	elif ProgressData.settings.manual_aim:
		# Keep console behavior, but avoid always-on manual aim on PC.
		is_manual = true if Utils.on_console else (is_mouse_pressed or is_gamepad_pressed)
	else:
		is_manual = false

	_manual_aim_cache[player_index] = is_manual
	return is_manual


func fantasy_hash_to_signed(hash_value: int) -> int:
	if hash_value > FANTASY_HASH_INT32_MAX:
		return hash_value - FANTASY_HASH_UINT32_RANGE
	return hash_value


func fantasy_hash_to_unsigned(hash_value: int) -> int:
	if hash_value < 0:
		return hash_value + FANTASY_HASH_UINT32_RANGE
	return hash_value


func fantasy_hash_equals(hash_value: int, expected_hash: int) -> bool:
	return fantasy_hash_to_signed(hash_value) == fantasy_hash_to_signed(expected_hash)


func fantasy_normalize_effect_keys(effects: Dictionary) -> bool:
	var key_additions: Array = []
	for raw_key in effects.keys():
		if !(raw_key is int):
			continue

		var key_as_int: int = int(raw_key)
		var signed_key: int = fantasy_hash_to_signed(key_as_int)
		var unsigned_key: int = fantasy_hash_to_unsigned(key_as_int)
		if signed_key != key_as_int and !effects.has(signed_key):
			key_additions.push_back([signed_key, effects[raw_key]])
		if unsigned_key != key_as_int and !effects.has(unsigned_key):
			key_additions.push_back([unsigned_key, effects[raw_key]])

	if key_additions.empty():
		return false

	for key_addition in key_additions:
		effects[key_addition[0]] = key_addition[1]

	return true


func fantasy_get_effect_value(effects: Dictionary, effect_hash: int, default_value = 0):
	if effects.has(effect_hash):
		return effects[effect_hash]

	var unsigned_hash: int = fantasy_hash_to_unsigned(effect_hash)
	if unsigned_hash != effect_hash and effects.has(unsigned_hash):
		return effects[unsigned_hash]

	return default_value


func fantasy_set_effect_value(effects: Dictionary, effect_hash: int, value) -> void:
	effects[effect_hash] = value

	var signed_hash: int = fantasy_hash_to_signed(effect_hash)
	if signed_hash != effect_hash:
		effects[signed_hash] = value

	var unsigned_hash: int = fantasy_hash_to_unsigned(effect_hash)
	if unsigned_hash != effect_hash:
		effects[unsigned_hash] = value


func sync_fantasy_job_weapon_count_effects(player_index: int) -> bool:
	if player_index < 0 or player_index >= RunData.get_player_count():
		return false

	var effects: Dictionary = RunData.get_player_effects(player_index)
	if effects.empty():
		return false

	var elemental_weapon_count: int = _fantasy_count_weapons_in_set(player_index, fantasy_set_elemental_hash)
	var gun_weapon_count: int = _fantasy_count_weapons_in_set(player_index, fantasy_set_gun_hash)
	var musical_weapon_count: int = _fantasy_count_weapons_in_set(player_index, fantasy_set_musical_hash)
	var total_weapon_count: int = RunData.get_player_weapons_ref(player_index).size()

	var changed: bool = false
	changed = _fantasy_set_effect_count(effects, fantasy_job_elemental_weapon_count_hash, elemental_weapon_count) or changed
	changed = _fantasy_set_effect_count(effects, fantasy_job_gun_weapon_count_hash, gun_weapon_count) or changed
	changed = _fantasy_set_effect_count(effects, fantasy_job_musical_weapon_count_hash, musical_weapon_count) or changed
	changed = _fantasy_set_effect_count(effects, fantasy_job_has_musical_weapon_hash, 1 if musical_weapon_count > 0 else 0) or changed
	changed = _fantasy_set_effect_count(effects, fantasy_job_total_weapon_count_hash, total_weapon_count) or changed

	if changed:
		RunData._are_player_stats_dirty[player_index] = true
		reset_stat_cache(player_index)
		LinkedStats.reset_player(player_index)

	return changed


func _fantasy_set_effect_count(effects: Dictionary, effect_hash: int, value: int) -> bool:
	var old_value: int = int(effects.get(effect_hash, 0))
	if old_value == value:
		return false
	effects[effect_hash] = value
	return true


func _fantasy_count_weapons_in_set(player_index: int, set_hash: int) -> int:
	var count: int = 0
	var player_weapons: Array = RunData.get_player_weapons_ref(player_index)

	for weapon in player_weapons:
		if weapon == null:
			continue
		if weapon.get("sets") == null:
			continue

		var weapon_sets: Array = weapon.sets
		for weapon_set in weapon_sets:
			if weapon_set == null:
				continue
			if int(weapon_set.my_id_hash) == set_hash:
				count += 1
				break

	return count
