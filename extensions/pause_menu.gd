extends "res://ui/menus/ingame/pause_menu.gd"

const ENABLE_YOKO_PAUSE_MULTI_MENU: bool = true
const YOKO_PAUSE_MULTI_MENU_SCENE = preload("res://mods-unpacked/Yoko-Fantasy/modules/pause_hotkey_menu/ui/pause_multifunction_menu.tscn")
const YOKO_HOTKEY_HINT_TEXT_KEY: String = "YOKO_PAUSE_HOTKEY_HINT"
const YOKO_HOTKEY_HINT_FALLBACK_TEXT: String = "Hotkey Menu: F1 / LT"
const YOKO_HOTKEY_HINT_FALLBACK_POS: Vector2 = Vector2(24, 14)
const YOKO_HOTKEY_HINT_OFFSET_FROM_RESUME: Vector2 = Vector2(0, -150)

var _yoko_pause_multi_menu: Control = null
var _yoko_hotkey_hint_label: Label = null
var _yoko_ignore_next_pause_request: bool = false
var _yoko_prev_f1_pressed: bool = false


func _ready() -> void:
	pause_mode = Node.PAUSE_MODE_PROCESS
	_yoko_setup_base_pause_ready()
	_yoko_setup_pause_multi_menu()
	_yoko_setup_hotkey_hint()
	_yoko_patch_menu_options_back_button()
	_yoko_ensure_menu_options_focus_back_target()
	set_process(false)
	call_deferred("_yoko_update_hotkey_hint_layout")


func _input(event: InputEvent) -> void:
	if !ENABLE_YOKO_PAUSE_MULTI_MENU:
		._input(event)
		return

	if get_tree().paused:
		if _yoko_is_options_visible() and _yoko_is_back_event(event):
			_yoko_on_menu_options_back_pressed()
			get_viewport().set_input_as_handled()
			return

		if _yoko_is_back_event(event):
			if codex_is_opened and _yoko_is_codex_visible():
				return
			codex_is_opened = false
			_yoko_mark_pause_close_for_reentry_guard()
			_yoko_hide_pause_multi_menu()
			.manage_back()
			_yoko_update_hotkey_hint_layout()
			get_viewport().set_input_as_handled()
			return

	._input(event)


func _process(_delta: float) -> void:
	if !ENABLE_YOKO_PAUSE_MULTI_MENU:
		return
	if !get_tree().paused:
		_yoko_prev_f1_pressed = false
		return

	_yoko_ensure_menu_options_focus_back_target()

	var f1_just_pressed: bool = _yoko_is_f1_hotkey_just_pressed_now()
	var lt_just_pressed: bool = _yoko_is_lt_hotkey_just_pressed_now()
	if !f1_just_pressed and !lt_just_pressed:
		return
	if codex_is_opened and _yoko_is_codex_visible():
		return

	_yoko_toggle_pause_multi_menu()
	_yoko_update_hotkey_hint_layout()


func _notification(what: int) -> void:
	if what != NOTIFICATION_RESIZED:
		return
	_yoko_update_hotkey_hint_layout()


func _yoko_setup_base_pause_ready() -> void:
	if is_instance_valid(_main_menu):
		if !_main_menu.is_connected("resume_button_pressed", self, "on_resume_button_pressed"):
			_main_menu.connect("resume_button_pressed", self, "on_resume_button_pressed")
		if !_main_menu.is_connected("codex_button_pressed", self, "on_codex_button_pressed"):
			_main_menu.connect("codex_button_pressed", self, "on_codex_button_pressed")

	if is_instance_valid(_menus):
		if !_menus.is_connected("codex_closed", self, "on_codex_closed"):
			_menus.connect("codex_closed", self, "on_codex_closed")

	if is_instance_valid(_focus_emulator):
		_focus_emulator.player_index = -1
		_focus_emulator.set_process_input(false)

	set_process_input(false)


func pause(player_index: int) -> void:
	if _yoko_ignore_next_pause_request and !get_tree().paused:
		return

	codex_is_opened = false
	.pause(player_index)
	set_process(true)
	_yoko_prev_f1_pressed = Input.is_key_pressed(KEY_F1) or Input.is_physical_key_pressed(KEY_F1)
	_yoko_ensure_menu_options_focus_back_target()
	_yoko_sync_pause_multi_menu_player()
	_yoko_hide_pause_multi_menu()
	_yoko_update_hotkey_hint_layout()


func unpause() -> void:
	_yoko_hide_pause_multi_menu()
	set_process(false)
	_yoko_prev_f1_pressed = false
	.unpause()


func _yoko_setup_pause_multi_menu() -> void:
	if !ENABLE_YOKO_PAUSE_MULTI_MENU:
		return
	if is_instance_valid(_yoko_pause_multi_menu):
		return

	_yoko_pause_multi_menu = YOKO_PAUSE_MULTI_MENU_SCENE.instance()
	add_child(_yoko_pause_multi_menu)
	_yoko_pause_multi_menu.hide()
	_yoko_sync_pause_multi_menu_player()


func _yoko_setup_hotkey_hint() -> void:
	if is_instance_valid(_yoko_hotkey_hint_label):
		return

	_yoko_hotkey_hint_label = Label.new()
	_yoko_hotkey_hint_label.name = "YokoHotkeyHint"
	_yoko_hotkey_hint_label.text = _yoko_get_hotkey_hint_text()
	_yoko_hotkey_hint_label.set_anchors_and_margins_preset(Control.PRESET_TOP_LEFT)
	_yoko_hotkey_hint_label.rect_position = YOKO_HOTKEY_HINT_FALLBACK_POS
	_yoko_hotkey_hint_label.modulate = Color(0.92, 0.95, 1.0, 0.92)
	_yoko_hotkey_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_yoko_hotkey_hint_label.align = Label.ALIGN_LEFT
	_yoko_hotkey_hint_label.valign = Label.VALIGN_TOP
	_yoko_hotkey_hint_label.autowrap = false

	if is_instance_valid(_main_menu):
		_main_menu.add_child(_yoko_hotkey_hint_label)
	else:
		add_child(_yoko_hotkey_hint_label)

	_yoko_hotkey_hint_label.raise()
	_yoko_update_hotkey_hint_layout()


func _yoko_patch_menu_options_back_button() -> void:
	if !is_instance_valid(_menu_options):
		return

	var back_button: Button = _menu_options.get_node_or_null("%BackButton") as Button
	if !is_instance_valid(back_button):
		return

	if back_button.is_connected("pressed", _menu_options, "_on_BackButton_pressed"):
		back_button.disconnect("pressed", _menu_options, "_on_BackButton_pressed")

	if !back_button.is_connected("pressed", self, "_yoko_on_menu_options_back_pressed"):
		back_button.connect("pressed", self, "_yoko_on_menu_options_back_pressed")

	_yoko_ensure_menu_options_focus_back_target()


func _yoko_on_menu_options_back_pressed() -> void:
	_yoko_ensure_menu_options_focus_back_target()
	if is_instance_valid(_menus):
		_menus.back()
	_yoko_focus_resume_button()


func _yoko_focus_resume_button() -> void:
	var resume_button: Button = _yoko_get_resume_button()
	if is_instance_valid(resume_button):
		resume_button.grab_focus()


func _yoko_ensure_menu_options_focus_back_target() -> void:
	if !is_instance_valid(_menu_options):
		return

	var existing_focus: Object = _menu_options.get("focus_before_created")
	if is_instance_valid(existing_focus):
		return

	var fallback_focus: Control = _yoko_get_resume_button()
	if !is_instance_valid(fallback_focus):
		fallback_focus = get_focus_owner()
	if !is_instance_valid(fallback_focus):
		fallback_focus = _menu_options.get_node_or_null("%BackButton") as Control
	if !is_instance_valid(fallback_focus):
		return

	_menu_options.set("focus_before_created", fallback_focus)


func _yoko_toggle_pause_multi_menu() -> void:
	_yoko_setup_pause_multi_menu()
	if !is_instance_valid(_yoko_pause_multi_menu):
		return

	if _yoko_pause_multi_menu.visible:
		_yoko_pause_multi_menu.hide()
		return

	_yoko_sync_pause_multi_menu_player()
	if _yoko_pause_multi_menu.has_method("refresh_menu"):
		_yoko_pause_multi_menu.call("refresh_menu")

	_yoko_pause_multi_menu.show()
	_yoko_pause_multi_menu.raise()


func _yoko_hide_pause_multi_menu() -> void:
	if !is_instance_valid(_yoko_pause_multi_menu):
		return
	_yoko_pause_multi_menu.hide()


func _yoko_is_pause_multi_menu_visible() -> bool:
	return is_instance_valid(_yoko_pause_multi_menu) and _yoko_pause_multi_menu.visible


func _yoko_is_options_visible() -> bool:
	return is_instance_valid(_menu_options) and _menu_options.visible


func _yoko_sync_pause_multi_menu_player() -> void:
	if !is_instance_valid(_yoko_pause_multi_menu):
		return
	if _yoko_pause_multi_menu.has_method("set_player_index"):
		_yoko_pause_multi_menu.call("set_player_index", _player_index)


func _yoko_update_hotkey_hint_layout() -> void:
	if !is_instance_valid(_yoko_hotkey_hint_label):
		return

	_yoko_hotkey_hint_label.text = _yoko_get_hotkey_hint_text()

	var resume_button: Button = _yoko_get_resume_button()
	if !is_instance_valid(resume_button):
		_yoko_hotkey_hint_label.rect_position = YOKO_HOTKEY_HINT_FALLBACK_POS
		return

	var resume_font: Font = resume_button.get("custom_fonts/font")
	if resume_font != null:
		_yoko_hotkey_hint_label.add_font_override("font", resume_font)

	var target_global: Vector2 = resume_button.rect_global_position + YOKO_HOTKEY_HINT_OFFSET_FROM_RESUME
	_yoko_hotkey_hint_label.rect_global_position = target_global


func _yoko_get_resume_button() -> Button:
	if !is_instance_valid(_main_menu):
		return null
	return _main_menu.get_node_or_null("%ResumeButton") as Button


func _yoko_get_hotkey_hint_text() -> String:
	var translated_text: String = tr(YOKO_HOTKEY_HINT_TEXT_KEY)
	if translated_text == YOKO_HOTKEY_HINT_TEXT_KEY:
		return YOKO_HOTKEY_HINT_FALLBACK_TEXT
	return translated_text


func _yoko_mark_pause_close_for_reentry_guard() -> void:
	_yoko_ignore_next_pause_request = true
	call_deferred("_yoko_clear_pause_reentry_guard")


func _yoko_clear_pause_reentry_guard() -> void:
	_yoko_ignore_next_pause_request = false


func _yoko_is_back_event(event: InputEvent) -> bool:
	if Utils.is_player_cancel_released(event, _player_index) or Utils.is_player_pause_released(event, _player_index):
		return true
	if event.is_action_released("ui_cancel") or event.is_action_released("ui_pause"):
		return true
	return _yoko_is_escape_released(event)


func _yoko_is_escape_released(event: InputEvent) -> bool:
	if !(event is InputEventKey):
		return false

	var key_event := event as InputEventKey
	if key_event.pressed or key_event.echo:
		return false
	if key_event.scancode != KEY_ESCAPE and key_event.physical_scancode != KEY_ESCAPE:
		return false
	return true


func _yoko_is_codex_visible() -> bool:
	if !is_instance_valid(_menus):
		return false
	var codex_node: Node = _menus.get_node_or_null("MenuCodex")
	if !is_instance_valid(codex_node):
		return false
	if codex_node is CanvasItem:
		return (codex_node as CanvasItem).visible
	return false


func _yoko_is_f1_hotkey_just_pressed_now() -> bool:
	var f1_pressed: bool = Input.is_key_pressed(KEY_F1) or Input.is_physical_key_pressed(KEY_F1)
	var just_pressed: bool = f1_pressed and !_yoko_prev_f1_pressed
	_yoko_prev_f1_pressed = f1_pressed
	return just_pressed


func _yoko_is_lt_hotkey_just_pressed_now() -> bool:
	if RunData.is_coop_run and !RunData.is_streamplay_run:
		for player_index in RunData.get_player_count():
			var remapped_device: int = CoopService.get_remapped_player_device(player_index)
			if remapped_device < 0:
				continue
			var mapped_action: String = "ltrigger_%s" % str(remapped_device)
			if InputMap.has_action(mapped_action) and Input.is_action_just_pressed(mapped_action):
				return true
		return false

	return InputMap.has_action("ltrigger") and Input.is_action_just_pressed("ltrigger")
