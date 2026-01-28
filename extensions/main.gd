extends "res://main.gd"

var UIHolyScenes = {}
const UI_HOLY_SCENE = preload("res://mods-unpacked/Yoko-Fantasy/content/scenes/ui_entry/ui_holy.tscn")

var UISoulScenes = {}
const UI_SOUL_SCENE = preload("res://mods-unpacked/Yoko-Fantasy/content/scenes/ui_entry/ui_soul.tscn")

# =========================== Extention =========================== #
func _on_EntitySpawner_players_spawned(players: Array) -> void:
    ._on_EntitySpawner_players_spawned(players)
    _fantasy_holy_display()
    _fantasy_soul_display()

func _process(_delta: float) -> void:
    _fantasy_holy_process()
    _fantasy_soul_process()

# =========================== Custom =========================== #
func _fantasy_holy_display() -> void:
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

        var after_gold_index = player_ui.hud_container.get_children().find(player_ui.gold) + 1
        player_ui.hud_container.add_child(UIHolyInstance)
        player_ui.hud_container.move_child(UIHolyInstance, after_gold_index)
        
        UIHolyInstance.update_value(Utils.get_stat(Utils.fantasy_stat_holy_hash, i))

        if not UIHolyInstance.is_connected("mouse_entered", self, "fa_on_UIHoly_mouse_entered"):
            UIHolyInstance.connect("mouse_entered", self, "fa_on_UIHoly_mouse_entered", [Utils.get_stat(Utils.fantasy_stat_holy_hash, i)])
        if not UIHolyInstance.is_connected("mouse_exited", self, "fa_on_UIHoly_mouse_exited"):
            UIHolyInstance.connect("mouse_exited", self, "fa_on_UIHoly_mouse_exited")
        
        UIHolyScenes[_players[i]] = UIHolyInstance

func _fantasy_soul_display() -> void:
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

        var after_gold_index = player_ui.hud_container.get_children().find(player_ui.gold) + 1
        player_ui.hud_container.add_child(UISoulInstance)
        player_ui.hud_container.move_child(UISoulInstance, after_gold_index)
        
        UISoulInstance.update_value(Utils.get_stat(Utils.fantasy_stat_soul_hash, i))
        
        if not UISoulInstance.is_connected("mouse_entered", self, "fa_on_UISoul_mouse_entered"):
            UISoulInstance.connect("mouse_entered", self, "fa_on_UISoul_mouse_entered")
        if not UISoulInstance.is_connected("mouse_exited", self, "fa_on_UISoul_mouse_exited"):
            UISoulInstance.connect("mouse_exited", self, "fa_on_UISoul_mouse_exited")
        
        UISoulScenes[_players[i]] = UISoulInstance

func _fantasy_holy_process() -> void:
    for i in range(_players.size()):
        if _players[i] in UIHolyScenes and \
        is_instance_valid(UIHolyScenes[_players[i]]):
            UIHolyScenes[_players[i]].update_value(Utils.get_stat(Utils.fantasy_stat_holy_hash, i))

func _fantasy_soul_process() -> void:
    for i in range(_players.size()):
        if _players[i] in UISoulScenes and \
        is_instance_valid(UISoulScenes[_players[i]]):
            UISoulScenes[_players[i]].update_value(Utils.get_stat(Utils.fantasy_stat_soul_hash, i))

# =========================== Method =========================== #
func fa_on_UIHoly_mouse_entered(stat_holy: int) -> void :
    if _cleaning_up:
        var damage_bouns: int = stat_holy
        var chance_drop_soul: int = int(stat_holy / (stat_holy + 50.0) * 100)
        var enemy_health_reduction: int = int(stat_holy / (stat_holy + 100.0) * 100)
        _info_popup.display(_ui_bonus_gold, Text.text("FANTASY_INFO_HOLY", [damage_bouns, chance_drop_soul, enemy_health_reduction]))

func fa_on_UIHoly_mouse_exited() -> void :
    _info_popup.hide()

func fa_on_UISoul_mouse_entered() -> void :
    if _cleaning_up:
        var damage_bouns: int = 20
        var attack_speed_bouns: int = 20
        _info_popup.display(_ui_bonus_gold, Text.text("FANTASY_INFO_SOUL", [damage_bouns, attack_speed_bouns]))

func fa_on_UISoul_mouse_exited() -> void :
    _info_popup.hide()
