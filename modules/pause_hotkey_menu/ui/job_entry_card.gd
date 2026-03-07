extends PanelContainer

var _job_name_label: Label = null
var _job_tier_label: Label = null
var _job_desc_label: Label = null

var _pending_job_name: String = ""
var _pending_job_desc: String = ""
var _pending_tier: int = 0


func _ready() -> void:
	_cache_nodes()
	_apply_pending()


func setup(job_name: String, job_desc: String, tier: int) -> void:
	_pending_job_name = job_name
	_pending_job_desc = job_desc
	_pending_tier = tier
	_apply_pending()


func _cache_nodes() -> void:
	if !is_instance_valid(_job_name_label):
		_job_name_label = get_node_or_null("HBoxContainer/ContentContainer/JobNameLabel")
	if !is_instance_valid(_job_tier_label):
		_job_tier_label = get_node_or_null("HBoxContainer/ContentContainer/JobTierLabel")
	if !is_instance_valid(_job_desc_label):
		_job_desc_label = get_node_or_null("HBoxContainer/ContentContainer/JobDescLabel")


func _apply_pending() -> void:
	_cache_nodes()
	if !is_instance_valid(_job_name_label) or !is_instance_valid(_job_tier_label) or !is_instance_valid(_job_desc_label):
		return

	_job_name_label.text = _pending_job_name
	_job_name_label.rect_scale = Vector2(1.18, 1.18)
	_job_tier_label.text = "T%s" % str(_pending_tier)
	_job_desc_label.text = _pending_job_desc
