extends "res://ui/menus/run/end_run.gd"

# ui_job
const BUTTON_SHOW_JOB = preload("res://mods-unpacked/Yoko-Fantasy/extensions/jobs/button_show_job_scene.tscn")

onready var h_container: HBoxContainer = _items_container.get_node("HBoxContainer")
onready var sort_inventory_but: OptionButton = h_container.get_node("Sort_Inventory_button")

# =========================== Extension =========================== #
func _ready() -> void:
    _fantasy_job_button_display()

# =========================== Custom =========================== #
func _fantasy_job_button_display() -> void:
    var ButtonShowJobInstance: Node = BUTTON_SHOW_JOB.instance()
    var before_sort_index: int = sort_inventory_but.get_index()
    h_container.add_child(ButtonShowJobInstance)
    h_container.move_child(ButtonShowJobInstance, before_sort_index)
    ButtonShowJobInstance.current_scene = $"MarginContainer/VBoxContainer"
    ButtonShowJobInstance.global_scene = self

    if !_items_container.authorize_sorting and is_instance_valid(ButtonShowJobInstance): ButtonShowJobInstance.hide()
