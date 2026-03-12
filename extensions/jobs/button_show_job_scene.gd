extends MyMenuButton

# job_menu
const JOB_MENU_SCENE = preload("res://mods-unpacked/Yoko-Fantasy/extensions/jobs/job_menu.tscn")

var current_scene: Node = null
var global_scene: Node = null

# =========================== Extension =========================== #
func on_pressed() -> void:
    .on_pressed()

    var job_menu: PanelContainer = global_scene.get_node_or_null("JobMenu")
    if job_menu == null:
        var JobMenuInstance: Node = JOB_MENU_SCENE.instance()
        JobMenuInstance.scene_before_created = current_scene
        global_scene.add_child(JobMenuInstance)
        return

    job_menu.scene_before_created = current_scene
    job_menu.show()
