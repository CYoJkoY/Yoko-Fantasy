extends "res://ui/menus/ingame/ingame_main_menu.gd"

# ui_job
const BUTTON_SHOW_JOB = preload("res://mods-unpacked/Yoko-Fantasy/extensions/jobs/button_show_job_scene.tscn")

onready var h_container: HBoxContainer = _items_container.get_node("HBoxContainer")
onready var sort_inventory_but: SortInventoryButton = h_container.get_node("Sort_Inventory_button")

# =========================== Extension =========================== #
func _ready() -> void:
    _fantasy_job_button_display()

func _on_OptionsButton_pressed() -> void:
    var focus_emulator: FocusEmulator = Utils.fa_get_menu_focus_emulator(player_index)
    if RunData.is_coop_run and focus_emulator != null:
        _fantasy_open_pause_options(focus_emulator)
        return

    emit_signal("options_button_pressed")

# =========================== Custom =========================== #
func _fantasy_job_button_display() -> void:
    var ButtonShowJobInstance: Node = BUTTON_SHOW_JOB.instance()
    var before_sort_index: int = sort_inventory_but.get_index()
    h_container.add_child(ButtonShowJobInstance)
    h_container.move_child(ButtonShowJobInstance, before_sort_index)
    ButtonShowJobInstance.current_scene = $"MarginContainer/VBoxContainer"
    ButtonShowJobInstance.global_scene = self

    if !_items_container.authorize_sorting: ButtonShowJobInstance.hide()

func _fantasy_open_pause_options(focus_emulator: FocusEmulator) -> void:
    var menus: Control = get_parent()
    var options = menus.get_node("MenuOptions")

    options.show()
    _fantasy_init_pause_options(options, focus_emulator)
    hide()
    menus._current_page = options
    menus.emit_signal("menu_page_switched", self, options)

func _fantasy_init_pause_options(options, focus_emulator: FocusEmulator) -> void:
    options.focus_before_created = _resume_button
    options.lb_texture.player_index = focus_emulator.player_index
    options.rb_texture.player_index = focus_emulator.player_index
    Utils.fa_focus_menu_control(options.get_node("%Audio_but"), player_index)

    options.adjust_buttons_font_size()
    options.master_slider.set_value(ProgressData.settings.volume.master)
    options.sound_slider.set_value(ProgressData.settings.volume.sound)
    options.music_slider.set_value(ProgressData.settings.volume.music)
    options.init_values_from_progress_data()
