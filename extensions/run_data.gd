extends "res://singletons/run_data.gd"

signal on_soul_effect(damage_to_add, speed_to_add, player_index)

var fantasy_resumed_from_state_in_shop: bool = false
var fantasy_pending_job_selections: Array = [[], [], [], []]
const FANTASY_JOB_UI_LEVEL_BASE: int = -200000

# =========================== Extension =========================== #
func reset(restart: bool = false) -> void:
    .reset(restart)
    fantasy_resumed_from_state_in_shop = false
    fantasy_pending_job_selections = [[], [], [], []]

func continue_current_run_in_shop() -> void:
    .continue_current_run_in_shop()
    fantasy_resumed_from_state_in_shop = true

func cancel_resume() -> void:
    .cancel_resume()
    fantasy_resumed_from_state_in_shop = false

func update_item_related_effects(player_index: int) -> void:
    _fantasy_add_weapon_sets(player_index)
    _fantasy_update_specific_set_weapon_bonuses(player_index)
    _fantasy_update_limited_item_bonuses(player_index)
    .update_item_related_effects(player_index)

# =========================== Custom =========================== #
func _fantasy_add_weapon_sets(player_index: int) -> void:
    var set_effects: Array = get_player_effect(Utils.fantasy_add_weapon_set_hash, player_index)
    if set_effects.empty(): return

    var weapons: Array = get_player_weapons_ref(player_index)
    var updated_sets: bool = false
    for set_id_hash in set_effects:
        var set_data: SetData = ItemService.get_set(set_id_hash)
        if set_data == null: continue

        for weapon in weapons:
            var has_set: bool = false
            for weapon_set in weapon.sets:
                if weapon_set.my_id_hash == set_id_hash:
                    has_set = true
                    break

            if has_set: continue

            weapon.sets.append(set_data)
            updated_sets = true

    if updated_sets:
        update_sets(player_index)

func _fantasy_update_specific_set_weapon_bonuses(player_index: int) -> void:
    var effects: Dictionary = get_player_effects(player_index)
    var old_specific_set_weapon_bonuses: Dictionary = effects[Utils.fantasy_old_specific_set_weapon_bonuses_hash]

    for stat_hash in old_specific_set_weapon_bonuses:
        assert(stat_hash is int)
        effects[stat_hash] -= old_specific_set_weapon_bonuses[stat_hash]
    
    old_specific_set_weapon_bonuses.clear()

    var weapons: Array = get_player_weapons_ref(player_index)
    var specific_set_weapon_count: Dictionary = {}
    for weapon in weapons: for set in weapon.sets:
        specific_set_weapon_count[set.my_id_hash] = specific_set_weapon_count.get(set.my_id_hash, 0) + 1

    for effect in effects[Utils.fantasy_specific_set_weapon_bonuses_hash]:
        var set_id_hash: int = effect[2]
        var set_count: int = specific_set_weapon_count.get(set_id_hash, 0)
        if set_count == 0: continue

        var stat: int = effect[0]
        var stat_value: int = effect[1]
        var nb_scaled: int = effect[3]
        var bonus: int = int(stat_value * (set_count / float(nb_scaled)))
        if bonus == 0: continue

        old_specific_set_weapon_bonuses[stat] = old_specific_set_weapon_bonuses.get(stat, 0) + bonus
        effects[stat] += bonus

func _fantasy_update_limited_item_bonuses(player_index: int) -> void:
    var effects: Dictionary = get_player_effects(player_index)
    var old_limited_unique_item_bonuses: Dictionary = effects[Utils.fantasy_old_limited_item_bonuses_hash]

    for stat_hash in old_limited_unique_item_bonuses:
        assert(stat_hash is int)
        effects[stat_hash] -= old_limited_unique_item_bonuses[stat_hash]

    old_limited_unique_item_bonuses.clear()

    var items: Array = get_player_items_ref(player_index)
    var limited_item_count: int = 0
    for item in items:
        if !(item is ItemData) or item.max_nb == -1: continue

        limited_item_count += 1

    effects[Utils.fantasy_limited_item_hash] = limited_item_count
    for effect in effects[Utils.fantasy_limited_item_bonuses_hash]:
        var stat: int = effect[0]
        var stat_value: int = effect[1]
        var nb_scaled: float = effect[2]
        var bonus: int = stat_value * int((limited_item_count / nb_scaled))
        if bonus == 0: continue

        old_limited_unique_item_bonuses[stat] = old_limited_unique_item_bonuses.get(stat, 0) + bonus
        effects[stat] += bonus

# =========================== Method =========================== #
func fa_add_job(job: UpgradeData, player_index: int) -> void:
    var job_slot: int = fa_get_next_job_slot(job.stage, player_index)
    if job_slot == -1: return

    players_data[player_index].jobs[job_slot] = job
    update_item_related_effects(player_index)

func fa_get_current_job(job_stage: int, player_index: int) -> UpgradeData:
    return players_data[player_index].jobs.get(job_stage, null)

func fa_get_next_job_slot(job_stage: int, player_index: int) -> int:
    match job_stage:
        0:
            return 0 if !players_data[player_index].jobs.has(0) else -1
        1:
            if !players_data[player_index].jobs.has(1): return 1
            if !players_data[player_index].jobs.has(2): return 2

    return -1

func fa_get_s2_job_count(player_index: int) -> int:
    var count: int = 0
    if players_data[player_index].jobs.has(1): count += 1
    if players_data[player_index].jobs.has(2): count += 1

    return count

func fa_has_s1_job(player_index: int) -> bool:
    return players_data[player_index].jobs.has(0)

func fa_queue_pending_job_selection(player_index: int, job_stage: int, wave: int) -> int:
    var ui_level: int = fa_make_job_ui_level(job_stage, wave)
    fantasy_pending_job_selections[player_index].append([job_stage, wave, ui_level])
    return ui_level

func fa_pop_pending_job_selection(player_index: int) -> Array:
    if fantasy_pending_job_selections[player_index].empty(): return []

    return fantasy_pending_job_selections[player_index].pop_front()

func fa_has_pending_job_selection(player_index: int) -> bool:
    return !fantasy_pending_job_selections[player_index].empty()

func fa_make_job_ui_level(job_stage: int, wave: int) -> int:
    return FANTASY_JOB_UI_LEVEL_BASE - wave * 10 - job_stage

func fa_is_job_ui_level(level: int) -> bool:
    return level <= FANTASY_JOB_UI_LEVEL_BASE
