extends Reference

const ENABLE_JOB_SYSTEM: bool = true

const JOB_TRIGGER_WAVE_TIER_1: int = 5
const JOB_TRIGGER_WAVE_TIER_2: int = 15

const JOB_STAGE_NONE: int = 0
const JOB_STAGE_TIER_1_DONE: int = 1
const JOB_STAGE_TIER_2_DONE: int = 2

const JOB_PENDING_NONE: int = 0
const JOB_PENDING_TIER_1: int = 1
const JOB_PENDING_TIER_2: int = 2

const JOB_FAMILY_NONE: int = 0
const JOB_FAMILY_COMMON: int = 1
const JOB_FAMILY_MELEE: int = 2
const JOB_FAMILY_RANGED: int = 3
const JOB_FAMILY_ELEMENTAL: int = 4
const JOB_FAMILY_ENGINEERING: int = 5

const JOB_UPGRADE_PREFIX: String = "fantasy_job_"
const JOB_BASE_PATH: String = "res://mods-unpacked/Yoko-Fantasy/content/upgrades/jobs/"

const TIER_1_FIXED: Array = [
    "swordsman_t1",
    "archer_t1",
    "mage_t1",
    "summoner_t1",
]

const TIER_1_COMMON: Array = [
    "tank_t1",
    "nurse_t1",
    "accountant_t1",
    "musician_t1",
    "botanist_t1",
    "blacksmith_t1",
]

const TIER_2_COMMON: Array = [
    "walker_t2",
    "enchanter_t2",
    "economist_t2",
    "temple_guard_t2",
    "missionary_t2",
    "land_lord_t2",
    "treasure_hunter_t2",
    "prophet_t2",
    "abyss_believer_t2",
    "perfumer_t2",
]

const TIER_2_BY_FAMILY: Dictionary = {
    JOB_FAMILY_MELEE: [
        "dual_blade_master_t2",
        "holy_blade_master_t2",
        "wandering_samurai_t2",
        "melee_assassin_t2",
    ],
    JOB_FAMILY_RANGED: [
        "divine_bow_master_t2",
        "ranged_assassin_t2",
        "gunner_t2",
        "firearms_master_t2",
    ],
    JOB_FAMILY_ELEMENTAL: [
        "fire_mage_t2",
        "thunder_mage_t2",
        "holy_taoist_t2",
        "dark_mage_t2",
    ],
    JOB_FAMILY_ENGINEERING: [
        "engineer_t2",
        "modifier_t2",
        "drive_knight_t2",
        "spirit_caller_t2",
    ],
}


static func get_pending_tier_for_wave(wave: int) -> int:
    if wave == JOB_TRIGGER_WAVE_TIER_1:
        return JOB_PENDING_TIER_1
    if wave == JOB_TRIGGER_WAVE_TIER_2:
        return JOB_PENDING_TIER_2
    return JOB_PENDING_NONE


static func can_queue_pending_tier(player_index: int, pending_tier: int) -> bool:
    var current_stage: int = int(RunData.get_player_effect(Utils.fantasy_job_stage_hash, player_index))

    if pending_tier == JOB_PENDING_TIER_1:
        return current_stage == JOB_STAGE_NONE
    if pending_tier == JOB_PENDING_TIER_2:
        return current_stage == JOB_STAGE_TIER_1_DONE

    return false


static func get_candidate_job_ids(pending_tier: int, player_index: int) -> Array:
    if pending_tier == JOB_PENDING_TIER_1:
        var tier_1_pool: Array = TIER_1_FIXED.duplicate()
        tier_1_pool.append_array(TIER_1_COMMON)
        return tier_1_pool

    if pending_tier == JOB_PENDING_TIER_2:
        var tier_2_pool: Array = TIER_2_COMMON.duplicate()
        var job_family: int = int(RunData.get_player_effect(Utils.fantasy_job_family_hash, player_index))
        if TIER_2_BY_FAMILY.has(job_family):
            tier_2_pool.append_array(TIER_2_BY_FAMILY[job_family])
        return tier_2_pool

    return []


static func get_upgrade_pool_for_player(pending_tier: int, player_index: int) -> Array:
    var pool: Array = []
    var job_ids: Array = get_candidate_job_ids(pending_tier, player_index)

    for job_id in job_ids:
        var upgrade: UpgradeData = load(_get_upgrade_data_path(job_id))
        if upgrade != null:
            pool.push_back(upgrade)

    return pool


static func is_job_upgrade(upgrade_data: UpgradeData) -> bool:
    if upgrade_data == null:
        return false
    return upgrade_data.upgrade_id.begins_with(JOB_UPGRADE_PREFIX)


static func _get_upgrade_data_path(job_id: String) -> String:
    return "%s%s/%s_data.tres" % [JOB_BASE_PATH, job_id, job_id]


static func get_job_name_key(job_id: String) -> String:
    if job_id == "":
        return ""
    return "UPGRADE_FANTASY_JOB_%s" % [job_id.to_upper()]


static func get_job_description_key(job_id: String) -> String:
    if job_id == "":
        return ""
    return "EFFECT_FANTASY_JOB_%s" % [job_id.to_upper()]


static func get_job_display_name(job_id: String) -> String:
    var name_key: String = get_job_name_key(job_id)
    if name_key != "":
        var translated_name: String = Text.text(name_key.to_upper())
        if translated_name != name_key.to_upper():
            return translated_name

    var upgrade_data: UpgradeData = load(_get_upgrade_data_path(job_id))
    if upgrade_data != null and upgrade_data.name != "":
        return upgrade_data.name

    return job_id


static func get_job_display_description(job_id: String) -> String:
    var description_key: String = get_job_description_key(job_id)
    if description_key != "":
        var translated_description: String = Text.text(description_key.to_upper())
        if translated_description != description_key.to_upper():
            return translated_description

    var upgrade_data: UpgradeData = load(_get_upgrade_data_path(job_id))
    if upgrade_data == null:
        return ""

    for effect in upgrade_data.effects:
        if effect == null:
            continue
        if !effect.has_method("get_id"):
            continue
        if effect.call("get_id") != "fantasy_job_select":
            continue

        var fallback_description: String = str(effect.get("description_text"))
        if fallback_description != "":
            return fallback_description

    return ""


static func get_selected_jobs(player_index: int) -> Array:
    var selected_jobs: Array = []
    if player_index < 0:
        return selected_jobs

    var effects: Dictionary = RunData.get_player_effects(player_index)
    if effects.empty():
        return selected_jobs
    if Utils != null and Utils.has_method("fantasy_normalize_effect_keys"):
        Utils.fantasy_normalize_effect_keys(effects)

    var tier_1_job_id: String = get_job_id_from_hash(int(Utils.fantasy_get_effect_value(effects, Utils.fantasy_job_tier1_id_hash, 0)))
    if tier_1_job_id != "":
        selected_jobs.push_back({
            "job_id": tier_1_job_id,
            "tier": 1,
        })

    var tier_2_job_id: String = get_job_id_from_hash(int(Utils.fantasy_get_effect_value(effects, Utils.fantasy_job_tier2_id_hash, 0)))
    if tier_2_job_id != "":
        selected_jobs.push_back({
            "job_id": tier_2_job_id,
            "tier": 2,
        })

    return selected_jobs


static func get_job_id_from_hash(job_id_hash: int) -> String:
    if job_id_hash == 0 or job_id_hash == Keys.empty_hash:
        return ""

    var normalized_job_id_hash: int = Utils.fantasy_hash_to_signed(job_id_hash) if Utils != null and Utils.has_method("fantasy_hash_to_signed") else job_id_hash

    if Keys.hash_to_string.has(normalized_job_id_hash):
        var mapped_job_id: String = str(Keys.hash_to_string[normalized_job_id_hash])
        if mapped_job_id != "":
            return mapped_job_id

    for job_id in get_all_job_ids():
        if _fantasy_hash_equals(Keys.generate_hash(job_id), normalized_job_id_hash):
            return job_id

    return ""


static func _fantasy_hash_equals(hash_value: int, expected_hash: int) -> bool:
    if Utils != null and Utils.has_method("fantasy_hash_equals"):
        return Utils.fantasy_hash_equals(hash_value, expected_hash)
    return hash_value == expected_hash


static func get_all_job_ids() -> Array:
    var all_job_ids: Array = []

    _append_unique_job_ids(all_job_ids, TIER_1_FIXED)
    _append_unique_job_ids(all_job_ids, TIER_1_COMMON)
    _append_unique_job_ids(all_job_ids, TIER_2_COMMON)

    for family in TIER_2_BY_FAMILY.keys():
        _append_unique_job_ids(all_job_ids, TIER_2_BY_FAMILY[family])

    return all_job_ids


static func _append_unique_job_ids(target: Array, source: Array) -> void:
    for job_id in source:
        if target.has(job_id):
            continue
        target.push_back(job_id)
