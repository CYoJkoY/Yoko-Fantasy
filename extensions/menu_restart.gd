extends "res://ui/menus/pages/menu_restart.gd"

func init() -> void:
	focus_before_created = Utils.fa_get_menu_focused_control(self, 0)
	Utils.fa_focus_menu_control($Buttons / ConfirmButton, 0)

func _input(event):
	if self.visible and event.is_action_released("ui_cancel"):
		_fantasy_cancel()
		get_tree().set_input_as_handled()

func _on_CancelButton_pressed() -> void:
	_fantasy_cancel()

func _fantasy_cancel() -> void:
	Utils.fa_focus_menu_control(focus_before_created, 0)
	emit_signal("cancel_button_pressed")
