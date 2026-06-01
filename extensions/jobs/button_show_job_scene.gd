extends MyMenuButton

var job_menu_scene = load("res://mods-unpacked/Yoko-Fantasy/extensions/jobs/job_menu.tscn")
var current_scene: Node = null
var global_scene: Node = null

func on_pressed() -> void:
    .on_pressed()

    var job_menu: PanelContainer = global_scene.get_node_or_null("JobMenu")
    if job_menu == null:
        job_menu = job_menu_scene.instance()
        job_menu.hide()
        global_scene.add_child(job_menu)
        job_menu.call_deferred("open_menu", current_scene)
        return

    job_menu.call("open_menu", current_scene)
