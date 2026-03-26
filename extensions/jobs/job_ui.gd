extends PanelContainer

var job_data: UpgradeData = null

onready var _job_description = $"%JobDescription"

# =========================== Extension =========================== #
func set_job(p_job_data: UpgradeData, player_index: int) -> void:
    show()
    job_data = p_job_data
    _job_description.set_item(p_job_data, player_index)
    var category_text: String = ""

    match p_job_data.upgrade_id_hash:
        Utils.job_fantasy_elemental_hash: category_text = "JOB_ELEMENTAL"
        Utils.job_fantasy_engineering_hash: category_text = "JOB_ENGINEERING"
        Utils.job_fantasy_melee_hash: category_text = "JOB_MELEE"
        Utils.job_fantasy_ranged_hash: category_text = "JOB_RANGED"
        Utils.job_fantasy_universal_hash: category_text = "JOB_UNIVERSAL"

    match p_job_data.stage:
        0: _job_description._category.text = tr(category_text).format(["I"])
        1: _job_description._category.text = tr(category_text).format(["II"])

    var stylebox_color = get_stylebox("panel").duplicate()
    ItemService.change_panel_stylebox_from_tier(stylebox_color, p_job_data.tier)
    add_stylebox_override("panel", stylebox_color)
