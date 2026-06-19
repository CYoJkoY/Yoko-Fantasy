extends "res://singletons/debug_service.gd"

const FANTASY_ENEMIES_DIR: String = "res://mods-unpacked/Yoko-Fantasy/content/entities/enemies"

# =========================== Extension =========================== #
func _input(event) -> void:
	if OS.is_debug_build() and event.is_action_pressed("open_debug_menu"):
		if not is_instance_valid(current_debug_menu):
			current_debug_menu = debug_menu.instance()
			current_debug_menu.enemies_directories.append(FANTASY_ENEMIES_DIR)
			if get_tree().current_scene is Main:
				get_tree().current_scene.get_node("UI").add_child(current_debug_menu)
			else:
				get_tree().current_scene.add_child(current_debug_menu)
