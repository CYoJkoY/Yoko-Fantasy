extends "res://ui/menus/shop/inventory_container.gd"

# ui_job
onready var h_container = $"HBoxContainer"
const BUTTON_SHOW_JOB = preload("res://mods-unpacked/Yoko-Fantasy/extensions/jobs/button_show_job_scene.tscn")

# =========================== Extension =========================== #
func _ready() -> void:
    _fantasy_job_button_display()

# =========================== Custom =========================== #
func _fantasy_job_button_display() -> void:
    var ButtonShowJobInstance: Node = BUTTON_SHOW_JOB.instance()
    var before_sort_index: int = $"%Sort_Inventory_button".get_index()
    h_container.add_child(ButtonShowJobInstance)
    h_container.move_child(ButtonShowJobInstance, before_sort_index)

    if !authorize_sorting and is_instance_valid(ButtonShowJobInstance): ButtonShowJobInstance.hide()
