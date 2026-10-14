extends Node

const FANTASY_TRACKS_ID: String = "Yoko-Fantasy"

var fantasy_tracks_button: CheckButton

# ══════════════════════════════════════════ Extension ══════════════════════════════════════════ #
func _ready() -> void:
    var options = get_parent()
    fantasy_tracks_button = CheckButton.new()
    fantasy_tracks_button.set_script(options.new_tracks_button.get_script())
    fantasy_tracks_button.name = "FantasyTracksButton"
    fantasy_tracks_button.text = "MENU_FANTASY_TRACKS"
    fantasy_tracks_button.add_font_override("font", options.normal_font)
    fantasy_tracks_button.add_stylebox_override("hover_pressed", options.new_tracks_button.get_stylebox("hover_pressed"))
    options.new_tracks_button.get_parent().add_child(fantasy_tracks_button)
    options.all_check_buttons.append(fantasy_tracks_button)
    options.connect("visibility_changed", self, "_fantasy_sync_tracks_button")
    _fantasy_sync_tracks_button()
    fantasy_tracks_button.connect("toggled", self, "_on_FantasyTracksButton_toggled")

# ══════════════════════════════════════════ Custom ══════════════════════════════════════════ #
func _fantasy_sync_tracks_button() -> void:
    fantasy_tracks_button.set_pressed_no_signal(!ProgressData.settings.deactivated_dlc_tracks.has(FANTASY_TRACKS_ID))

func _on_FantasyTracksButton_toggled(button_pressed: bool) -> void:
    if button_pressed:
        ProgressData.settings.deactivated_dlc_tracks.erase(FANTASY_TRACKS_ID)
    elif !ProgressData.settings.deactivated_dlc_tracks.has(FANTASY_TRACKS_ID):
        ProgressData.settings.deactivated_dlc_tracks.append(FANTASY_TRACKS_ID)
    MusicManager.set_shuffled_tracks()
    MusicManager.play()
