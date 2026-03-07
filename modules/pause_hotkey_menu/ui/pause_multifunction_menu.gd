extends PanelContainer

const JOB_SYSTEM = preload("res://mods-unpacked/Yoko-Fantasy/extensions/jobs/job_system.gd")
const JOB_ENTRY_CARD_SCENE = preload("res://mods-unpacked/Yoko-Fantasy/modules/pause_hotkey_menu/ui/job_entry_card.tscn")

var _player_index: int = 0

onready var _title_label: Label = $"%TitleLabel"
onready var _hint_label: Label = $"%HintLabel"
onready var _jobs_container: VBoxContainer = $"%JobsContainer"
onready var _empty_label: Label = $"%EmptyLabel"
onready var _section_label: Label = $"MarginContainer/VBoxContainer/SectionLabel"


func _ready() -> void:
	_title_label.text = "Yoko Multifunction Menu"
	_hint_label.text = "Toggle: F1 / LT"
	_section_label.text = "Players / Selected Jobs"
	refresh_menu()


func set_player_index(player_index: int) -> void:
	_player_index = player_index
	refresh_menu()


func refresh_menu() -> void:
	_clear_job_entries()

	var player_indices: Array = _get_player_indices_for_display()
	var has_any_jobs: bool = false

	for player_idx in player_indices:
		var selected_jobs: Array = JOB_SYSTEM.get_selected_jobs(int(player_idx))
		if !selected_jobs.empty():
			has_any_jobs = true
		_jobs_container.add_child(_create_player_section(int(player_idx), selected_jobs))

	_empty_label.visible = !has_any_jobs
	if _empty_label.visible:
		_empty_label.text = "No job selected yet for all players."


func _create_player_section(player_idx: int, selected_jobs: Array) -> Control:
	var section: PanelContainer = PanelContainer.new()
	section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section.mouse_filter = Control.MOUSE_FILTER_IGNORE
	section.add_stylebox_override("panel", _create_player_section_style(player_idx))

	var margin: MarginContainer = MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_constant_override("margin_left", 12)
	margin.add_constant_override("margin_top", 9)
	margin.add_constant_override("margin_right", 12)
	margin.add_constant_override("margin_bottom", 9)
	section.add_child(margin)

	var section_vbox: VBoxContainer = VBoxContainer.new()
	section_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section_vbox.add_constant_override("separation", 7)
	margin.add_child(section_vbox)

	section_vbox.add_child(_create_player_header(player_idx, selected_jobs))

	var separator: HSeparator = HSeparator.new()
	separator.modulate = Color(1, 1, 1, 0.28)
	section_vbox.add_child(separator)

	if selected_jobs.empty():
		var empty_label: Label = Label.new()
		empty_label.text = "No job selected."
		empty_label.modulate = Color(0.79, 0.82, 0.88, 0.92)
		section_vbox.add_child(empty_label)
		return section

	for selected_job in selected_jobs:
		var job_id: String = str(selected_job.get("job_id", ""))
		var tier: int = int(selected_job.get("tier", 0))
		if job_id == "":
			continue

		var card: Control = JOB_ENTRY_CARD_SCENE.instance()
		section_vbox.add_child(card)
		card.modulate = Color(1, 1, 1, 0.97)
		if card.has_method("setup"):
			var job_name: String = JOB_SYSTEM.get_job_display_name(job_id)
			var job_description: String = JOB_SYSTEM.get_job_display_description(job_id)
			card.call(
				"setup",
				job_name,
				job_description,
				tier
			)

	return section


func _create_player_header(player_idx: int, selected_jobs: Array) -> Control:
	var header: HBoxContainer = HBoxContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_constant_override("separation", 8)

	var player_color: Color = _get_player_tint(player_idx)
	var title_label: Label = Label.new()
	title_label.text = _get_player_header_text(player_idx)
	title_label.add_color_override("font_color", player_color.lightened(0.18))
	title_label.rect_scale = Vector2(1.08, 1.08)
	header.add_child(title_label)

	var count_label: Label = Label.new()
	var selected_count: int = selected_jobs.size()
	count_label.text = "Jobs: %s" % str(selected_count)
	count_label.modulate = Color(0.89, 0.92, 0.97, 0.9)
	header.add_child(count_label)

	return header


func _create_player_section_style(player_idx: int) -> StyleBoxFlat:
	var tint: Color = _get_player_tint(player_idx)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(tint.r * 0.24, tint.g * 0.24, tint.b * 0.24, 0.86)
	style.border_color = Color(tint.r, tint.g, tint.b, 0.93)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return style


func _get_player_tint(player_idx: int) -> Color:
	if RunData.is_coop_run:
		var safe_idx: int = int(clamp(player_idx, 0, 3))
		return CoopService.get_player_color(safe_idx, 1.0)
	return Color(0.58, 0.74, 0.93, 1.0)


func _get_player_header_text(player_idx: int) -> String:
	var header_text: String = "Player %s" % str(player_idx + 1)
	if RunData.is_coop_run and player_idx == _player_index:
		return "%s (Menu Owner)" % header_text
	return header_text


func _get_player_indices_for_display() -> Array:
	var player_count: int = max(RunData.get_player_count(), 1)
	var ordered_indices: Array = []

	if _player_index >= 0 and _player_index < player_count:
		ordered_indices.push_back(_player_index)

	for player_idx in player_count:
		if ordered_indices.has(player_idx):
			continue
		ordered_indices.push_back(player_idx)

	return ordered_indices


func _clear_job_entries() -> void:
	for child in _jobs_container.get_children():
		child.queue_free()
