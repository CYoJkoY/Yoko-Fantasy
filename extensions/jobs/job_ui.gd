extends PanelContainer

var job_data: UpgradeData = null

onready var _job_description = $"%JobDescription"

# =========================== Extension =========================== #
func set_job(p_job_data: UpgradeData, player_index: int) -> void:
    show()
    job_data = p_job_data
    _job_description.set_item(p_job_data, player_index)
    _job_description._category.text = Utils.fa_get_job_category_text(p_job_data)

    var stylebox_color = get_stylebox("panel").duplicate()
    ItemService.change_panel_stylebox_from_tier(stylebox_color, p_job_data.tier)
    add_stylebox_override("panel", stylebox_color)
