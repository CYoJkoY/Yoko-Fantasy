extends "res://ui/menus/menus.gd"

const FANTASY_TRACKS_OPTION = preload("res://mods-unpacked/Yoko-Fantasy/extensions/ui/fantasy_tracks_option.gd")

# ══════════════════════════════════════════ Extension ══════════════════════════════════════════ #
func _ready() -> void:
    var tracks_option: Node = FANTASY_TRACKS_OPTION.new()
    tracks_option.name = "FantasyTracksOption"
    _menu_choose_options.add_child(tracks_option)
