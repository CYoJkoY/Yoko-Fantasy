extends PanelContainer

const UI_JOB_SCENE = preload("res://mods-unpacked/Yoko-Fantasy/extensions/jobs/job_ui.tscn")

signal stat_focused(stat_button, stat_title, stat_value, player_index)
signal stat_unfocused(player_index)
signal stat_hovered(stat_button, stat_title, stat_value, player_index)
signal stat_unhovered(player_index)

onready var job_container: VBoxContainer = $"JobCont"
onready var job_tabscontainer: HBoxContainer = $"JobCont/HBoxContainer"
onready var stat_container: VBoxContainer = $"%StatCont"
onready var stat_tabscontainer: HBoxContainer = $"%StatCont/HBoxContainer"

onready var stats_button: Button = $"%StatsButton"
onready var cross_button: Button = $"%CrossButton"
onready var focus_before_created: Control = get_focus_owner()
onready var _popup_manager = $"%PopupManager"
onready var _item_popup = $"%ItemPopup"
onready var _stat_popup = $"%StatPopup"
onready var _tween: Tween = $"Tween"

onready var job_player_conts: Array = [
    $"%JobPlayerCont1/VPlayerCont",
    $"%JobPlayerCont2/VPlayerCont",
    $"%JobPlayerCont3/VPlayerCont",
    $"%JobPlayerCont4/VPlayerCont",
]

onready var stat_player_conts: Array = [
    $"%StatPlayerCont1/MarginContainer/VPlayerCont",
    $"%StatPlayerCont2/MarginContainer/VPlayerCont",
    $"%StatPlayerCont3/MarginContainer/VPlayerCont",
    $"%StatPlayerCont4/MarginContainer/VPlayerCont",
]

onready var jobs_conts: Array = [
    $"%JobsCont1",
    $"%JobsCont2",
    $"%JobsCont3",
    $"%JobsCont4",
]

var scene_before_created: Node = null
var _popup_manager_initialized: Array = [false, false, false, false]
var _job_ui_1: Array = [null, null, null, null]
var _job_ui_2: Array = [null, null, null, null]
var _jobs1: Array = [null, null, null, null]
var _jobs2: Array = [null, null, null, null]
var _stat_nodes: Array = [null, null, null, null]
var job_tab_buts: Array = [null, null, null, null]
var stat_tab_buts: Array = [null, null, null, null]

# =========================== Extension =========================== #
func _input(event: InputEvent) -> void:
    if self.visible and event.is_action_pressed("ui_cancel"):
        hide()
        scene_before_created.show()
        focus_before_created.grab_focus()

func _ready():
    for player_index in RunData.get_player_count():
        var job_player_cont: VBoxContainer = job_player_conts[player_index]
        _job_ui_1[player_index] = job_player_cont.get_child(0)
        _job_ui_2[player_index] = job_player_cont.get_child(1)

        var jobs_cont = jobs_conts[player_index]
        _jobs1[player_index] = jobs_cont.get_child(0)
        _jobs2[player_index] = jobs_cont.get_child(1)
        _jobs1[player_index]._label.text = tr("COOP_S1_JOB")
        _jobs2[player_index]._label.text = tr("COOP_S2_JOB")

        var stat_player_cont = stat_player_conts[player_index]
        _stat_nodes[player_index] = stat_player_cont.get_children()

        job_tab_buts[player_index] = job_tabscontainer.get_child(player_index)
        stat_tab_buts[player_index] = stat_tabscontainer.get_child(player_index)
        job_tab_buts[player_index].show()
        stat_tab_buts[player_index].show()
        job_tab_buts[player_index].text = tr("COOP_PLAYER").format([player_index + 1])
        stat_tab_buts[player_index].text = tr("COOP_PLAYER").format([player_index + 1])

        for stat in _stat_nodes[player_index]:
            stat.color_override = ItemService.get_stat(stat.key_hash).color_override
            stat.connect("focused", self , "on_stat_focused")
            stat.connect("unfocused", self , "on_stat_unfocused")
            stat.connect("hovered", self , "on_stat_hovered")
            stat.connect("unhovered", self , "on_stat_unhovered")
            stat.enable_focus()

    show()

func show() -> void:
    .show()
    update_jobs()
    update_stats()
    focus_before_created = get_focus_owner()
    scene_before_created.hide()
    cross_button.grab_focus()

func update_jobs() -> void:
    for player_index in RunData.get_player_count():
        var job_1: UpgradeData = RunData.fa_get_current_job(0, player_index)
        var job_2: UpgradeData = RunData.fa_get_current_job(1, player_index)
        if job_1: _job_ui_1[player_index].set_job(job_1, player_index)
        if job_2: _job_ui_2[player_index].set_job(job_2, player_index)

        var jobs1: InventoryContainer = _jobs1[player_index]
        var jobs2: InventoryContainer = _jobs2[player_index]
        match [job_1, job_2]:
            [null, _]:
                jobs1._elements.set_elements(ItemService.jobs_by_stage[0])
                jobs2._elements.set_elements(ItemService.jobs_by_stage[1])
            [_, null]:
                jobs1._elements.set_elements([job_1])
                jobs2._elements.set_elements(ItemService.fa_get_jobs(1, Utils.LARGE_NUMBER, job_1.upgrade_id_hash))
            [_, _]:
                jobs1._elements.set_elements([job_1])
                jobs2._elements.set_elements([job_2])
        
        if !_popup_manager_initialized[player_index]:
            _popup_manager_initialized[player_index] = true

            _popup_manager.connect_inventory_container(jobs1)
            _popup_manager.connect_inventory_container(jobs2)
            _popup_manager.add_item_popup(_item_popup, player_index)
            
            var _err = connect("stat_focused", _popup_manager, "_on_stat_focused")
            _err = connect("stat_unfocused", _popup_manager, "_on_stat_unfocused")
            _err = connect("stat_hovered", _popup_manager, "_on_stat_hovered")
            _err = connect("stat_unhovered", _popup_manager, "_on_stat_unhovered")
            _popup_manager.add_stat_popup(_stat_popup, player_index)

func update_stats() -> void:
    for player_index in RunData.get_player_count():
        for stat in _stat_nodes[player_index]:
            stat.update_player_stat(player_index)

func _on_StatsButton_pressed() -> void:
    match stat_container.rect_position.y:
        -1080.0:
            job_container.hide()
            _tween.interpolate_property(stat_container, "rect_position",
                                        Vector2(0, -1080), Vector2(0, 0), 0.2,
                                        Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
            _tween.start()

        _:
            _tween.interpolate_property(stat_container, "rect_position",
                                       Vector2(0, 0), Vector2(0, -1080), 0.2,
                                       Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
            _tween.start()
            yield (_tween, "tween_completed")
            job_container.show()

func _on_CrossButton_pressed() -> void:
    hide()
    scene_before_created.show()
    focus_before_created.grab_focus()

func on_stat_focused(stat_button, stat_title, stat_value, player_index) -> void:
    emit_signal("stat_focused", stat_button, stat_title, stat_value, player_index)


func on_stat_unfocused(player_index) -> void:
    emit_signal("stat_unfocused", player_index)


func on_stat_hovered(stat_button, stat_title, stat_value, player_index) -> void:
    emit_signal("stat_hovered", stat_button, stat_title, stat_value, player_index)


func on_stat_unhovered(player_index) -> void:
    emit_signal("stat_unhovered", player_index)
