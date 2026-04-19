extends "res://singletons/item_service.gd"

var jobs_by_stage: Dictionary = {0: [], 1: []}

# =========================== Extension =========================== #
func _ready() -> void:
    _fantasy_get_jobs_by_stage()

func get_consumable_to_drop(unit: Unit, item_chance: float) -> ConsumableData:
    var consumable: ConsumableData =.get_consumable_to_drop(unit, item_chance)
    consumable = _fantasy_get_soul_to_drop(consumable)
    
    return consumable

func get_consumable_for_tier(tier: int = Tier.COMMON) -> ConsumableData:
    var consumable: ConsumableData =.get_consumable_for_tier(tier)
    consumable = _fantasy_get_soul_to_drop(consumable)

    return consumable

func apply_item_effect_modifications(item: ItemParentData, player_index: int) -> ItemParentData:
    var new_item: ItemParentData =.apply_item_effect_modifications(item, player_index)
    new_item = _fantasy_extra_curse_item(new_item, player_index)

    return new_item

func get_upgrades(level: int, number: int, old_upgrades: Array, player_index: int) -> Array:
    var upgrades_to_show: Array =.get_upgrades(level, number, old_upgrades, player_index)
    upgrades_to_show = _fantasy_get_jobs(upgrades_to_show, level, player_index)

    return upgrades_to_show

func get_stat_description_text(stat_hash: int, value: int, player_index: int) -> String:
    var stat_description: String =.get_stat_description_text(stat_hash, value, player_index)
    stat_description = _fantasy_get_stat_description_text(stat_description, stat_hash, value, player_index)

    return stat_description

# =========================== Custom =========================== #
func _fantasy_get_soul_to_drop(consumable: ConsumableData) -> ConsumableData:
    var stat_holy: float = Utils.average_all_player_stats(Utils.stat_fantasy_holy_hash)
    var chance_drop_soul: float = 0.01
    var chance_drop_soul_bonus: float = stat_holy / (stat_holy + 50.0) if stat_holy > 0 else -1.0
    if consumable == null and Utils.get_chance_success(chance_drop_soul * (1.0 + chance_drop_soul_bonus)):
        consumable = get_element(consumables, Utils.consumable_fantasy_soul_hash)
    elif consumable != null and consumable.my_id_hash == Utils.consumable_fantasy_soul_hash:
        consumable = get_consumable_for_tier(Tier.COMMON)
    
    return consumable

func _fantasy_extra_curse_item(item: ItemParentData, player_index: int) -> ItemParentData:
    if item.is_cursed: return item

    var effect_items: Array = RunData.get_player_effect(Utils.fantasy_extra_curse_item_hash, player_index)
    for effect in effect_items:
        if !Utils.get_chance_success(effect[1] / 100.0): continue

        RunData.ncl_add_effect_tracking_value(effect[0], 1, player_index)
        return Utils.ncl_curse_item(item, player_index)

    return item

func _fantasy_get_jobs_by_stage() -> void:
    for upgrade in upgrades:
        var job_stage = upgrade.get("stage")
        if job_stage != null: jobs_by_stage[job_stage].append(upgrade)

func _fantasy_get_jobs(upgrades_to_show: Array, level: int, player_index: int) -> Array:
    var s1_job: UpgradeData = RunData.fa_get_current_job(0, player_index)
    var s2_job: UpgradeData = RunData.fa_get_current_job(1, player_index)

    var need_add_job: bool = (
        (RunData.current_wave == 5 and s1_job == null) or \
        (RunData.current_wave == 15 and s2_job == null)
    )

    if !need_add_job:
        var has_job: bool = false
        for upgrade in upgrades_to_show:
            if upgrade.get("stage") == null: continue

            upgrades_to_show.erase(upgrade)
            has_job = true

        if has_job: upgrades_to_show = get_upgrades(level, 4, upgrades_to_show, player_index)

        return upgrades_to_show

    var s1_job_hash: int = s1_job.upgrade_id_hash if s1_job else Keys.empty_hash
    var s2_job_hash: int = s2_job.upgrade_id_hash if s2_job else Keys.empty_hash
    match [s1_job_hash == Keys.empty_hash, s2_job_hash == Keys.empty_hash]:
        [true, _]: return fa_get_jobs(0, 4)
        [false, true]: return fa_get_jobs(1, 4, s1_job_hash)

    return upgrades_to_show

func _fantasy_get_stat_description_text(stat_description: String, stat_hash: int, value: int, player_index: int) -> String:
    var stat_name = Keys.hash_to_string[stat_hash].to_upper()
    var stat_sign = "POS_" if value >= 0 else "NEG_"
    var key = "INFO_" + stat_sign + stat_name

    match stat_hash:
        Utils.stat_fantasy_holy_hash:
            var stat_holy: float = Utils.average_all_player_stats(Utils.stat_fantasy_holy_hash)
            var damage_bonus: int = stat_holy as int
            var chance_drop_soul: int = (stat_holy / (stat_holy + 50.0) * 100) as int
            var enemy_health_reduction: int = (stat_holy / (stat_holy + 100.0) * 100) as int
            stat_description = Text.text(key, [str(damage_bonus), str(chance_drop_soul), str(enemy_health_reduction)])

        Utils.stat_fantasy_soul_hash:
            var bonus: int = 10 + RunData.get_player_effect(Utils.fantasy_soul_bonus_hash, player_index)
            stat_description = Text.text(key, [str(bonus), str(bonus)])

    return stat_description

# =========================== Method =========================== #
func fa_get_jobs(stage: int, number: int = Utils.LARGE_NUMBER, way: int = Keys.empty_hash) -> Array:
    var source = jobs_by_stage.get(stage, [])
    var candidates = source

    if way != Keys.empty_hash and way != Utils.job_fantasy_universal_hash:
        candidates = []
        for upgrade in source:
            if upgrade.upgrade_id_hash != way and \
            upgrade.upgrade_id_hash != Utils.job_fantasy_universal_hash: continue

            candidates.append(upgrade)

    var count = min(number, candidates.size())
    candidates.shuffle()
    return candidates.slice(0, count - 1)
