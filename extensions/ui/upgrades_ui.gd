extends "res://ui/menus/ingame/upgrades_ui.gd"

const UpgradeHooks = preload("res://mods-unpacked/Yoko-Fantasy/extensions/services/upgrade_hooks.gd")

signal fantasy_jobs_processed

# =========================== Extension =========================== #
func _ready() -> void:
	if RunData.is_coop_run != is_coop_ui:
		return

	for player_index in RunData.get_player_count():
		var player_container = _get_player_container(player_index)
		if !player_container.is_connected("fantasy_job_selected", self, "_fantasy_on_job_selected"):
			player_container.connect("fantasy_job_selected", self, "_fantasy_on_job_selected")
		if !player_container.is_connected("fantasy_job_skipped", self, "_fantasy_on_job_skipped"):
			player_container.connect("fantasy_job_skipped", self, "_fantasy_on_job_skipped")

# =========================== Method =========================== #
func show_fantasy_job_options() -> bool:
	return _fantasy_show_next_job_options()

# =========================== Custom =========================== #
func _fantasy_show_next_job_options() -> bool:
	for player_index in RunData.get_player_count():
		var player_container = _get_player_container(player_index)
		if _player_is_choosing[player_index]:
			continue

		var job_selection: Array = RunData.fa_pop_pending_job_selection(player_index)
		if job_selection.empty():
			player_container.call("_fantasy_finish_job_selection_phase")
			continue

		player_container.update_inventory()
		player_container.call("show_fantasy_job_selection", job_selection)
		_update_player_stats(player_index)
		show()
		player_container.focus()
		_player_is_choosing[player_index] = true

	for player_index in RunData.get_player_count():
		if _player_is_choosing[player_index]:
			return true

	return false

func _fantasy_on_job_selected(job_data: UpgradeData, player_index: int) -> void:
	_player_is_choosing[player_index] = false

	UpgradeHooks.fa_handle_selected_upgrade_hooks(job_data, player_index, "fantasy_job")
	RunData.apply_item_effects(job_data, player_index)
	RunData.fa_add_job(job_data, player_index)

	LinkedStats.reset_player(player_index)
	_update_player_stats(player_index)
	if not _fantasy_show_next_job_options():
		emit_signal("fantasy_jobs_processed")

func _fantasy_on_job_skipped(player_index: int) -> void:
	_player_is_choosing[player_index] = false

	LinkedStats.reset_player(player_index)
	_update_player_stats(player_index)
	if not _fantasy_show_next_job_options():
		emit_signal("fantasy_jobs_processed")
