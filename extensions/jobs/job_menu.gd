extends PanelContainer

const UI_JOB_SCENE = preload("res://mods-unpacked/Yoko-Fantasy/extensions/jobs/job_ui.tscn")

var scene_before_created: Node = null

onready var cross_button: Button = $"%cross_button"
onready var focus_before_created: Control = get_focus_owner()
onready var tab_buts: Array = [
    $"%TabBut1",
    $"%TabBut2",
    $"%TabBut3",
    $"%TabBut4",
]

onready var player_conts: Array = [
    $"%VPlayerCont1",
    $"%VPlayerCont2",
    $"%VPlayerCont3",
    $"%VPlayerCont4",
]

func _input(event):
    if event.is_action_pressed("ui_cancel"): _on_cross_button_pressed()

func _ready():
    show()

func show() -> void:
    .show()
    set_jobs()
    focus_before_created = get_focus_owner()
    scene_before_created.hide()
    cross_button.grab_focus()

func set_jobs() -> void:
    for player_index in RunData.get_player_count():
        var player_cont: VBoxContainer = player_conts[player_index]
        var tab_but: Button = tab_buts[player_index]

        tab_but.show()
        tab_but.text = tr("COOP_PLAYER").format([player_index + 1])

        var job_ui_1: PanelContainer = player_cont.get_child(0)
        var job_ui_2: PanelContainer = player_cont.get_child(1)
        var job_1: UpgradeData = RunData.fa_get_current_job(0, player_index)
        var job_2: UpgradeData = RunData.fa_get_current_job(1, player_index)

        if job_1: job_ui_1.set_job(job_1, player_index)
        if job_2: job_ui_2.set_job(job_2, player_index)

func _on_cross_button_pressed() -> void:
    hide()
    scene_before_created.show()
    focus_before_created.grab_focus()
