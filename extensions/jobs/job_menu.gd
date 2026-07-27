extends PanelContainer

onready var job_container: VBoxContainer = $"JobCont"
onready var job_tabscontainer: HBoxContainer = $"JobCont/HBoxContainer"

onready var cross_button: Button = $"%CrossButton"
onready var focus_before_created: Control = get_focus_owner()
onready var _item_popup = $"%ItemPopup"

onready var job_player_conts: Array = [
    $"%JobPlayerCont1/VPlayerCont",
    $"%JobPlayerCont2/VPlayerCont",
    $"%JobPlayerCont3/VPlayerCont",
    $"%JobPlayerCont4/VPlayerCont",
]

onready var jobs_conts: Array = [
    $"%JobsCont1",
    $"%JobsCont2",
    $"%JobsCont3",
    $"%JobsCont4",
]

var scene_before_created: Node = null
var _job_ui_1: Array = [null, null, null, null]
var _job_ui_2: Array = [null, null, null, null]
var _job_ui_3: Array = [null, null, null, null]
var _jobs1: Array = [null, null, null, null]
var _jobs2: Array = [null, null, null, null]
var _job_elements_hovered: Array = [null, null, null, null]
var _job_elements_focused: Array = [null, null, null, null]
var job_tab_buts: Array = [null, null, null, null]

# =========================== Extension =========================== #
func _input(event: InputEvent) -> void:
    if self.visible and event.is_action_pressed("ui_cancel"):
        _fantasy_close_menu()

func _ready():
    for player_index in range(RunData.get_player_count()):
        var job_player_cont: VBoxContainer = job_player_conts[player_index]
        _job_ui_1[player_index] = job_player_cont.get_child(0)
        _job_ui_2[player_index] = job_player_cont.get_child(1)
        _job_ui_3[player_index] = job_player_cont.get_child(2)

        var jobs_cont = jobs_conts[player_index]
        _jobs1[player_index] = jobs_cont.get_child(0)
        _jobs2[player_index] = jobs_cont.get_child(1)
        _jobs1[player_index].player_index = player_index
        _jobs2[player_index].player_index = player_index
        _jobs1[player_index]._elements.player_index = player_index
        _jobs2[player_index]._elements.player_index = player_index
        _jobs1[player_index]._label.text = tr("COOP_S1_JOB")
        _jobs2[player_index]._label.text = tr("COOP_S2_JOB")
        _fantasy_connect_inventory_container(_jobs1[player_index])
        _fantasy_connect_inventory_container(_jobs2[player_index])

        job_tab_buts[player_index] = job_tabscontainer.get_child(player_index)
        job_tab_buts[player_index].show()
        job_tab_buts[player_index].text = tr("COOP_PLAYER").format([player_index + 1])

func open_menu(p_scene_before_created: Node = null) -> void:
    scene_before_created = p_scene_before_created
    show()

func show() -> void:
    .show()
    update_jobs()
    focus_before_created = get_focus_owner()
    if scene_before_created != null and is_instance_valid(scene_before_created):
        scene_before_created.hide()
    cross_button.grab_focus()

func update_jobs() -> void:
    var job_uis: Array = [_job_ui_1, _job_ui_2, _job_ui_3]
    for player_index in range(RunData.get_player_count()):
        for job_stage in range(job_uis.size()):
            var job_data: UpgradeData = RunData.fa_get_current_job(job_stage, player_index)
            if job_data:
                job_uis[job_stage][player_index].set_job(job_data, player_index)

        var jobs1: InventoryContainer = _jobs1[player_index]
        var jobs2: InventoryContainer = _jobs2[player_index]
        jobs1._elements.set_elements(ItemService.fa_get_sorted_jobs_for_menu(0))
        jobs2._elements.set_elements(ItemService.fa_get_sorted_jobs_for_menu(1))

func _on_CrossButton_pressed() -> void:
    _fantasy_close_menu()

func _fantasy_close_menu() -> void:
    hide()
    _fantasy_reset_job_popup_state()
    if scene_before_created != null and is_instance_valid(scene_before_created):
        scene_before_created.show()
    if focus_before_created != null and is_instance_valid(focus_before_created):
        focus_before_created.grab_focus()

func _fantasy_connect_inventory_container(container: InventoryContainer) -> void:
    var inventory = container._elements
    inventory.connect("element_hovered", self, "_fantasy_on_job_element_hovered")
    inventory.connect("element_unhovered", self, "_fantasy_on_job_element_unhovered")
    inventory.connect("element_focused", self, "_fantasy_on_job_element_focused")
    inventory.connect("element_unfocused", self, "_fantasy_on_job_element_unfocused")

func _fantasy_on_job_element_hovered(element: InventoryElement) -> void:
    var player_index: int = _fantasy_get_player_index_for_element(element)

    element.grab_focus()
    _job_elements_hovered[player_index] = element
    _job_elements_focused[player_index] = element
    _fantasy_display_job_element(element, player_index)

func _fantasy_on_job_element_unhovered(element: InventoryElement) -> void:
    var player_index: int = _fantasy_get_player_index_for_element(element)
    if _job_elements_hovered[player_index] == element:
        _job_elements_hovered[player_index] = null
        _fantasy_on_job_element_unfocused(element)

func _fantasy_on_job_element_focused(element: InventoryElement) -> void:
    var player_index: int = _fantasy_get_player_index_for_element(element)

    _job_elements_focused[player_index] = element
    _fantasy_display_job_element(element, player_index)

func _fantasy_on_job_element_unfocused(element: InventoryElement) -> void:
    var player_index: int = _fantasy_get_player_index_for_element(element)
    if _job_elements_focused[player_index] == element:
        _job_elements_focused[player_index] = null
        _item_popup.hide()

func _fantasy_display_job_element(element: InventoryElement, player_index: int) -> void:
    var job_data: UpgradeData = element.item
    _item_popup.player_index = player_index
    _item_popup.display_element(element)
    _fantasy_set_job_popup_category(job_data)

func _fantasy_set_job_popup_category(job_data: UpgradeData) -> void:
    var category_text: String = Utils.fa_get_job_category_text(job_data)
    _item_popup._panel._item_description._category.text = category_text

func _fantasy_get_player_index_for_element(element: InventoryElement) -> int:
    if !RunData.is_coop_run:
        return 0

    var player_index: int = FocusEmulatorSignal.get_player_index(element)
    return player_index if player_index >= 0 else element.player_index

func _fantasy_reset_job_popup_state() -> void:
    _item_popup.hide()

    for player_index in range(_job_elements_hovered.size()):
        _job_elements_hovered[player_index] = null
        _job_elements_focused[player_index] = null
