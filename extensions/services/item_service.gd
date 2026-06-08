extends "res://singletons/item_service.gd"

var jobs: Array = []
var jobs_by_stage: Dictionary = {0: [], 1: []}

# =========================== Extension =========================== #
func _ready() -> void:
	_fantasy_get_jobs_by_stage()

func apply_item_effect_modifications(item: ItemParentData, player_index: int) -> ItemParentData:
	var new_item: ItemParentData =.apply_item_effect_modifications(item, player_index)
	new_item = _fantasy_extra_curse_item(new_item, player_index)

	return new_item

func get_stat_description_text(stat_hash: int, value: int, player_index: int) -> String:
	var stat_description: String =.get_stat_description_text(stat_hash, value, player_index)
	stat_description = _fantasy_get_stat_description_text(stat_description, stat_hash, value, player_index)

	return stat_description

func get_icon_for_duplicate_shop_item(character: CharacterData, player_items: Array, player_weapons: Array, shop_item: ItemParentData, player_index: int):
	var icon =.get_icon_for_duplicate_shop_item(character, player_items, player_weapons, shop_item, player_index)
	icon = _fantasy_get_icon_for_limited_shop_item(icon, character, shop_item)

	return icon

func _get_rand_item_for_wave(wave: int, player_index: int, type: int, args: GetRandItemForWaveArgs) -> ItemParentData:
	var item: ItemParentData =._get_rand_item_for_wave(wave, player_index, type, args)
	item = _fantasy_can_spawn_erosion_related_item(item, wave, player_index, type, args)

	return item

# =========================== Custom =========================== #
func _fantasy_extra_curse_item(item: ItemParentData, player_index: int) -> ItemParentData:
	if item.is_cursed: return item

	var effect_items: Array = RunData.get_player_effect(Utils.fantasy_extra_curse_item_hash, player_index)
	for effect in effect_items:
		if !Utils.get_chance_success(effect[1] / 100.0): continue

		RunData.ncl_add_effect_tracking_value(effect[0], 1, player_index)
		return Utils.ncl_curse_item(item, player_index)

	return item

func _fantasy_get_jobs_by_stage() -> void:
	jobs = ProgressData.get_dlc_data("Yoko-Fantasy").jobs
	for job in jobs:
		var job_stage: int = job.stage
		jobs_by_stage[job_stage].append(job)

func _fantasy_get_job_way_order() -> Array:
	return [
		Utils.job_fantasy_elemental_hash,
		Utils.job_fantasy_engineering_hash,
		Utils.job_fantasy_luck_hash,
		Utils.job_fantasy_melee_hash,
		Utils.job_fantasy_ranged_hash,
		Utils.job_fantasy_universal_hash,
	]

func _fantasy_get_stat_description_text(stat_description: String, stat_hash: int, value: int, player_index: int) -> String:
	var stat_name = Keys.hash_to_string[stat_hash].to_upper()
	var stat_sign = "POS_" if value >= 0 else "NEG_"
	var key = "INFO_" + stat_sign + stat_name

	match stat_hash:
		Utils.stat_fantasy_holy_hash:
			var stat_holy: float = Utils.average_all_player_stats(Utils.stat_fantasy_holy_hash)
			var damage_bonus: int = int(stat_holy)
			var chance_drop_soul: int = int(stat_holy / (stat_holy + 50.0) * 100)
			var enemy_health_reduction: int = int(stat_holy / (stat_holy + 100.0) * 100)
			stat_description = Text.text(key, [str(damage_bonus), str(chance_drop_soul), str(enemy_health_reduction)])

		Utils.stat_fantasy_soul_hash:
			var bonus: int = 10 + RunData.get_player_effect(Utils.fantasy_soul_bonus_hash, player_index)
			stat_description = Text.text(key, [str(bonus), str(bonus)])

	return stat_description

func _fantasy_get_icon_for_limited_shop_item(icon, character: CharacterData, shop_item: ItemParentData):
	if icon != null: return icon

	var is_princess: bool = character.my_id_hash == Utils.character_fantasy_princess_hash
	var is_limited_item: bool = shop_item is ItemData and shop_item.max_nb != -1
	if is_princess and is_limited_item: return get_icon(Utils.icon_fantasy_princess_limited_hash).get_data()

	return icon

func _fantasy_can_spawn_erosion_related_item(item: ItemParentData, wave: int, player_index: int, type: int, args: GetRandItemForWaveArgs) -> ItemParentData:
	if type != TierData.ITEMS: return item

	var is_erosion_related: bool = false
	for effect in item.effects:
		if effect.key != "fantasy_erosion_speed" and effect.key != "fantasy_erosion_can_crit": continue

		is_erosion_related = true
		break

	if !is_erosion_related: return item

	var can_spawn: bool = false
	var item_effects: Array = RunData.get_player_effect(Utils.fantasy_erosion_hash, player_index)
	if !item_effects.empty(): can_spawn = true

	if !can_spawn: return _get_rand_item_for_wave(wave, player_index, type, args)

	return item

# =========================== Method =========================== #
func fa_get_jobs(stage: int, number: int = Utils.LARGE_NUMBER, way: int = Keys.empty_hash) -> Array:
	var source = jobs_by_stage.get(stage, [])
	var candidates = source

	if way == Utils.job_fantasy_universal_hash:
		candidates = []
		for job in source:
			if job.upgrade_id_hash != Utils.job_fantasy_universal_hash: continue

			candidates.append(job)

	elif way != Keys.empty_hash:
		candidates = []
		for job in source:
			if job.upgrade_id_hash != way and \
			job.upgrade_id_hash != Utils.job_fantasy_universal_hash: continue

			candidates.append(job)

	var count = min(number, candidates.size())
	candidates.shuffle()
	return candidates.slice(0, count - 1)

func fa_get_sorted_jobs_for_menu(stage: int) -> Array:
	var source: Array = jobs_by_stage.get(stage, [])
	var result: Array = []

	for way_hash in _fantasy_get_job_way_order():
		for job in source:
			if job.upgrade_id_hash != way_hash: continue

			result.append(job)

	return result

func fa_get_job_candidates(stage: int, number: int = Utils.LARGE_NUMBER, guaranteed_way: int = Keys.empty_hash) -> Array:
	var candidates: Array = jobs_by_stage.get(stage, []).duplicate()
	var result: Array = []

	candidates.shuffle()
	if guaranteed_way != Keys.empty_hash:
		var guaranteed_candidates: Array = []
		for job in candidates:
			if job.upgrade_id_hash == guaranteed_way:
				guaranteed_candidates.append(job)

		guaranteed_candidates.shuffle()
		if !guaranteed_candidates.empty():
			result.append(guaranteed_candidates[0])

	for job in candidates:
		if result.has(job): continue

		result.append(job)
		if result.size() >= number: break

	return result

func fa_get_job_candidates_for_player(stage: int, number: int, player_index: int) -> Array:
	if stage == 0:
		return fa_get_job_candidates(0, number)

	var s1_job: UpgradeData = RunData.fa_get_current_job(0, player_index)
	var candidates: Array = []
	if s1_job == null or s1_job.upgrade_id_hash == Utils.job_fantasy_universal_hash:
		candidates = fa_get_jobs(1, Utils.LARGE_NUMBER, Utils.job_fantasy_universal_hash)

	elif Utils.fa_is_damage_job_way(s1_job.upgrade_id_hash) or s1_job.upgrade_id_hash == Utils.job_fantasy_luck_hash:
		return _fantasy_get_mixed_s2_candidates(s1_job.upgrade_id_hash, number, player_index)

	else:
		candidates = fa_get_job_candidates(1, Utils.LARGE_NUMBER)

	return _fantasy_exclude_current_s2_jobs(candidates, number, player_index)

func _fantasy_exclude_current_s2_jobs(candidates: Array, number: int, player_index: int) -> Array:
	var result: Array = []
	var current_jobs: Array = [
		RunData.fa_get_current_job(1, player_index),
		RunData.fa_get_current_job(2, player_index),
	]

	for job in candidates:
		if current_jobs.has(job): continue
		if result.has(job): continue

		result.append(job)
		if result.size() >= number: break

	return result

func _fantasy_get_mixed_s2_candidates(way_hash: int, number: int, player_index: int) -> Array:
	var source: Array = _fantasy_exclude_current_s2_jobs(
		jobs_by_stage.get(1, []).duplicate(),
		Utils.LARGE_NUMBER,
		player_index
	)
	var guaranteed_way_jobs: Array = []
	var random_pool: Array = []

	for job in source:
		if job.upgrade_id_hash == way_hash:
			guaranteed_way_jobs.append(job)
		elif job.upgrade_id_hash == Utils.job_fantasy_universal_hash:
			random_pool.append(job)

	guaranteed_way_jobs.shuffle()

	var result: Array = []
	if !guaranteed_way_jobs.empty():
		result.append(guaranteed_way_jobs[0])

	for job in guaranteed_way_jobs:
		if result.has(job):
			continue
		random_pool.append(job)

	random_pool.shuffle()
	for job in random_pool:
		if result.has(job):
			continue
		result.append(job)
		if result.size() >= number:
			return result

	return result
