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

func get_upgrades(level: int, number: int, old_upgrades: Array, player_index: int) -> Array:
    var upgrades_to_show: Array =.get_upgrades(level, number, old_upgrades, player_index)
    upgrades_to_show = _fantasy_get_jobs(upgrades_to_show, player_index)

    return upgrades_to_show

func get_stat_description_text(stat_hash: int, value: int, player_index: int) -> String:
    var stat_description: String =.get_stat_description_text(stat_hash, value, player_index)
    stat_description = _fantasy_get_stat_description_text(stat_description, stat_hash, value, player_index)

    return stat_description

func get_icon_for_duplicate_shop_item(character: CharacterData, player_items: Array, player_weapons: Array, shop_item: ItemParentData, player_index: int) -> Texture:
    var icon: Texture =.get_icon_for_duplicate_shop_item(character, player_items, player_weapons, shop_item, player_index)
    icon = _fantasy_get_icon_for_limited_shop_item(icon, character, player_items, player_weapons, shop_item, player_index)

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

func _fantasy_get_jobs(upgrades_to_show: Array, player_index: int) -> Array:
    var s1_job: UpgradeData = RunData.fa_get_current_job(0, player_index)
    var s2_job: UpgradeData = RunData.fa_get_current_job(1, player_index)

    var need_add_job: bool = (
        (RunData.current_wave == 5 and s1_job == null) or \
        (RunData.current_wave == 15 and s2_job == null)
    )

    if !need_add_job: return upgrades_to_show

    var s1_job_hash: int = s1_job.upgrade_id_hash if s1_job else Keys.empty_hash
    var s2_job_hash: int = s2_job.upgrade_id_hash if s2_job else Keys.empty_hash
    match [s1_job_hash == Keys.empty_hash, s2_job_hash == Keys.empty_hash]:
        [true, _]: upgrades_to_show = fa_get_jobs(0, 4)
        [false, true]: upgrades_to_show = fa_get_jobs(1, 4, s1_job_hash)

    return upgrades_to_show

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

func _fantasy_get_icon_for_limited_shop_item(icon: Texture, character: CharacterData, _player_items: Array, _player_weapons: Array, shop_item: ItemParentData, _player_index: int) -> Texture:
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
