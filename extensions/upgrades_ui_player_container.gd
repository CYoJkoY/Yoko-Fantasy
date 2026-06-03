extends "res://ui/menus/ingame/upgrades_ui_player_container.gd"

signal fantasy_job_selected(job_data, player_index)
signal fantasy_job_skipped(player_index)

const FANTASY_COOP_JOB_OPTION_COMPACT_HEIGHT: int = 100
const FANTASY_COOP_JOB_OPTION_FULL_HEIGHT: int = 355

var _fantasy_showing_job_selection: bool = false
var _fantasy_job_ui_level: int = 0
var _fantasy_focused_job_option: UpgradeUI = null

# =========================== Extension =========================== #
func _ready() -> void:
    ._ready()
    for upgrade_ui in _get_upgrade_uis():
        upgrade_ui.button.connect("focus_entered", self, "_fantasy_on_job_option_focused", [upgrade_ui])
        upgrade_ui.button.connect("mouse_entered", self, "_fantasy_on_job_option_focused", [upgrade_ui])
        upgrade_ui.button.connect("focus_exited", self, "_fantasy_on_job_option_unfocused", [upgrade_ui])

func _on_RerollButton_pressed() -> void:
    if _fantasy_showing_job_selection:
        _fantasy_skip_job_selection()
        return

    ._on_RerollButton_pressed()

func _on_choose_button_pressed(upgrade: UpgradeData) -> void:
    if _fantasy_showing_job_selection:
        _fantasy_choose_job(upgrade)
        return

    ._on_choose_button_pressed(upgrade)

# =========================== Method =========================== #
func show_fantasy_job_selection(job_selection: Array) -> void:
    _fantasy_hide_checkmark_group()
    _fantasy_showing_job_selection = true
    var job_stage: int = int(job_selection[0])
    _fantasy_job_ui_level = int(job_selection[2])

    var jobs: Array = ItemService.fa_get_job_candidates_for_player(job_stage, 4, player_index)
    var upgrade_uis: Array = _get_upgrade_uis()
    for i in upgrade_uis.size():
        var upgrade_ui = upgrade_uis[i]
        upgrade_ui.visible = i < jobs.size()
        if upgrade_ui.visible:
            upgrade_ui.set_upgrade(jobs[i], player_index)
            _fantasy_set_job_category(upgrade_ui, jobs[i])
            _fantasy_set_job_option_description_visible(upgrade_ui, !RunData.is_coop_run)

    _reroll_price = 0
    _reroll_button.visible = true
    _reroll_button.set_value(0, RunData.get_player_gold(player_index))
    if RunData.is_coop_run:
        _reroll_button.set_text(tr("FANTASY_SKIP_JOB").to_upper())
    else:
        _reroll_button.set_text("      " + tr("FANTASY_SKIP_JOB").to_upper())

    _items_container.hide()
    _upgrades_container.show()

# =========================== Custom =========================== #
func _fantasy_choose_job(job_data: UpgradeData) -> void:
    if _button_pressed: return

    _button_pressed = true
    _button_delay_timer.start()
    _fantasy_remove_job_process_icon()
    _fantasy_clear_job_selection_state()
    emit_signal("fantasy_job_selected", job_data, player_index)

func _fantasy_skip_job_selection() -> void:
    if _button_pressed: return

    _button_pressed = true
    _button_delay_timer.start()
    _fantasy_remove_job_process_icon()
    _fantasy_clear_job_selection_state()
    emit_signal("fantasy_job_skipped", player_index)

func _fantasy_remove_job_process_icon() -> void:
    if _things_to_process_container:
        _things_to_process_container.upgrades.remove_element(_fantasy_job_ui_level)

func _fantasy_clear_job_selection_state() -> void:
    _fantasy_showing_job_selection = false
    _fantasy_job_ui_level = 0
    _fantasy_focused_job_option = null
    for upgrade_ui in _get_upgrade_uis():
        _fantasy_restore_job_option_presentation(upgrade_ui)

func _fantasy_finish_job_selection_phase() -> void:
    _fantasy_clear_job_selection_state()
    _fantasy_hide_checkmark_group()
    _items_container.hide()
    _upgrades_container.hide()

func _fantasy_set_job_category(upgrade_ui: UpgradeUI, job_data: UpgradeData) -> void:
    upgrade_ui._upgrade_description._category.text = Utils.fa_get_job_category_text(job_data)

func _fantasy_on_job_option_focused(upgrade_ui: UpgradeUI) -> void:
    if !_fantasy_showing_job_selection or !RunData.is_coop_run: return

    var upgrade_uis: Array = _get_upgrade_uis()
    for other_upgrade_ui in upgrade_uis:
        if !other_upgrade_ui.visible: continue

        _fantasy_set_job_option_description_visible(other_upgrade_ui, other_upgrade_ui == upgrade_ui)

    _fantasy_focused_job_option = upgrade_ui

func _fantasy_on_job_option_unfocused(upgrade_ui: UpgradeUI) -> void:
    if !_fantasy_showing_job_selection or !RunData.is_coop_run: return
    if _fantasy_focused_job_option != upgrade_ui: return

    _fantasy_focused_job_option = null
    _fantasy_set_job_option_description_visible(upgrade_ui, false)

func _fantasy_set_job_option_description_visible(upgrade_ui: UpgradeUI, p_visible: bool) -> void:
    var description = upgrade_ui._upgrade_description
    if RunData.is_coop_run:
        if !upgrade_ui.has_meta("fantasy_original_rect_min_size_y"):
            upgrade_ui.set_meta("fantasy_original_rect_min_size_y", upgrade_ui.rect_min_size.y)

        upgrade_ui.rect_min_size.y = FANTASY_COOP_JOB_OPTION_FULL_HEIGHT if p_visible else FANTASY_COOP_JOB_OPTION_COMPACT_HEIGHT

    description._vbox_container.visible = p_visible and description.show_details and description.expand_indefinitely
    description._scroll_container.visible = p_visible and description.show_details and !description.expand_indefinitely
    description.get_effects().visible = p_visible
    description.get_weapon_stats().visible = false
    description.get_player_stats(-1).visible = false
    description.get_player_stats(1).visible = false

func _fantasy_restore_job_option_presentation(upgrade_ui: UpgradeUI) -> void:
    if upgrade_ui.has_meta("fantasy_original_rect_min_size_y"):
        upgrade_ui.rect_min_size.y = upgrade_ui.get_meta("fantasy_original_rect_min_size_y")
        upgrade_ui.remove_meta("fantasy_original_rect_min_size_y")

    var description = upgrade_ui._upgrade_description
    description._vbox_container.visible = description.show_details and description.expand_indefinitely
    description._scroll_container.visible = description.show_details and !description.expand_indefinitely
    description.get_effects().visible = description.get_effects().get_child_count() > 0

func _fantasy_hide_checkmark_group() -> void:
    var checkmark_group = get_node_or_null("%CheckmarkGroup")
    if checkmark_group != null:
        checkmark_group.hide()
