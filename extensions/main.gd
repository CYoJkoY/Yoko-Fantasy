extends "res://main.gd"

var UIHolyScenes = {}
const UI_HOLY_SCENE = preload("res://mods-unpacked/Yoko-Fantasy/content/scenes/ui_entry/ui_holy.tscn")

var UISoulScenes = {}
const UI_SOUL_SCENE = preload("res://mods-unpacked/Yoko-Fantasy/content/scenes/ui_entry/ui_soul.tscn")

# =========================== Extention =========================== #
func _on_EntitySpawner_players_spawned(players: Array) -> void:
    ._on_EntitySpawner_players_spawned(players)
    _yztato_holy_display()
    _yztato_soul_display()

func _process(_delta: float) -> void:
    _yztato_holy_process()
    _yztato_soul_process()

# =========================== Custom =========================== #
func _yztato_holy_display() -> void:
    for i in range(_players.size()):
        if _players[i] in UIHolyScenes:
            continue
            
        var UIHolyInstance = UI_HOLY_SCENE.instance()
        match i:
            0,2: UIHolyInstance.alignment = BoxContainer.ALIGN_BEGIN
            1,3: UIHolyInstance.alignment = BoxContainer.ALIGN_END
        
        var player_ui = _players_ui[i]
        if !is_instance_valid(player_ui) or !is_instance_valid(player_ui.hud_container):
            continue

        var gold_index = player_ui.hud_container.get_children().find(player_ui.gold)
        player_ui.hud_container.add_child(UIHolyInstance)
        player_ui.hud_container.move_child(UIHolyInstance, gold_index)
        
        UIHolyInstance.update_value(RunData.get_player_effect("fantasy_stat_holy", i))
        UIHolyScenes[_players[i]] = UIHolyInstance

func _yztato_soul_display() -> void:
    for i in range(_players.size()):
        if _players[i] in UISoulScenes:
            continue
            
        var UISoulInstance = UI_SOUL_SCENE.instance()
        match i:
            0,2: UISoulInstance.alignment = BoxContainer.ALIGN_BEGIN
            1,3: UISoulInstance.alignment = BoxContainer.ALIGN_END
        
        var player_ui = _players_ui[i]
        if !is_instance_valid(player_ui) or !is_instance_valid(player_ui.hud_container):
            continue

        var gold_index = player_ui.hud_container.get_children().find(player_ui.gold)
        player_ui.hud_container.add_child(UISoulInstance)
        player_ui.hud_container.move_child(UISoulInstance, gold_index)
        
        RunData.get_player_effect("fantasy_stat_soul", i)
        UISoulScenes[_players[i]] = UISoulInstance

func _yztato_holy_process() -> void:
    for i in range(_players.size()):
        if _players[i] in UIHolyScenes and \
        is_instance_valid(UIHolyScenes[_players[i]]):
            UIHolyScenes[_players[i]].update_value(RunData.get_player_effect("fantasy_stat_holy", i))

func _yztato_soul_process() -> void:
    for i in range(_players.size()):
        if _players[i] in UISoulScenes and \
        is_instance_valid(UISoulScenes[_players[i]]):
            UISoulScenes[_players[i]].update_value(RunData.get_player_effect("fantasy_stat_soul", i))
