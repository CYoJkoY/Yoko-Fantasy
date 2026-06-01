extends "res://ui/menus/pages/menu_codex.gd"

func _pop():
	var previous_focus: Control = Utils.fa_get_menu_focused_control(self, player_index)
	._pop()
	focus_before_created = previous_focus

func _focus_control(control: Control, player: int = 0) -> void:
	Utils.fa_focus_menu_control(control, player)

func _on_BackButton_pressed() -> void:
	emit_signal("codex_closed")
	animation_tree.set("parameters/conditions/finish", true)
	yield(get_tree().create_timer(0.4), "timeout")
	_focus_control(focus_before_created)
	hide()
	if RunData.is_coop_run:
		Utils._popup = null
	animation_tree.active = false
