extends "res://main.gd"

var FaTimers: Array = []

# ui_entry
var UIHolyScenes = {}
const UI_HOLY_SCENE = preload("res://mods-unpacked/Yoko-Fantasy/content/scenes/ui_entry/ui_holy.tscn")
var UISoulScenes = {}
const UI_SOUL_SCENE = preload("res://mods-unpacked/Yoko-Fantasy/content/scenes/ui_entry/ui_soul.tscn")

# =========================== Extension =========================== #
func _on_EntitySpawner_players_spawned(players: Array) -> void:
    ._on_EntitySpawner_players_spawned(players)
    _fantasy_holy_display()
    _fantasy_soul_display()

    _fantasy_start_ui_update_timer()
    _fantasy_start_time_bouns_current_health_damage_timer(players.size())

func _on_EntitySpawner_enemy_respawned(_enemy: Enemy) -> void:
    ._on_EntitySpawner_enemy_respawned(_enemy)
    call_deferred("_fantasy_change_living_cursed_enemy", _enemy, true)

func _on_enemy_died(enemy: Enemy, args: Entity.DieArgs) -> void:
    ._on_enemy_died(enemy, args)
    _fantasy_change_living_cursed_enemy(enemy, false)

func clean_up_room() -> void:
    for timer in FaTimers: timer.stop()
    .clean_up_room()


# =========================== Custom =========================== #
func _fantasy_start_ui_update_timer() -> void:
    var timer = Timer.new()
    timer.wait_time = 0.2
    timer.autostart = true
    timer.connect("timeout", self , "fa_update_all_ui_stats")
    add_child(timer)
    FaTimers.append(timer)

func _fantasy_start_time_bouns_current_health_damage_timer(player_num: int) -> void:
    for player_index in player_num:
        var effect_items: Array = RunData.get_player_effect(Utils.fantasy_time_bouns_current_health_damage_hash, player_index)
        for effect in effect_items:
            var timer: Timer = Timer.new()
            timer.wait_time = effect[0]
            timer.autostart = true
            timer.connect("timeout", self , "fa_time_bouns_current_health_damage", [effect[1] / 100.0, player_index])
            add_child(timer)
            FaTimers.append(timer)

func _fantasy_holy_display() -> void:
    for i in _players.size():
        if _players[i] in UIHolyScenes:
            continue
            
        var UIHolyInstance = UI_HOLY_SCENE.instance()
        match i:
            0, 2: UIHolyInstance.alignment = BoxContainer.ALIGN_BEGIN
            1, 3: UIHolyInstance.alignment = BoxContainer.ALIGN_END
        
        var player_ui = _players_ui[i]
        if !is_instance_valid(player_ui) or !is_instance_valid(player_ui.hud_container):
            continue

        var after_gold_index = player_ui.hud_container.get_children().find(player_ui.gold) + 1
        player_ui.hud_container.add_child(UIHolyInstance)
        player_ui.hud_container.move_child(UIHolyInstance, after_gold_index)
        
        UIHolyInstance.update_value(Utils.get_stat(Utils.stat_fantasy_holy_hash, i))

        if !UIHolyInstance.is_connected("mouse_entered", self , "fa_on_UIHoly_mouse_entered"):
            UIHolyInstance.connect("mouse_entered", self , "fa_on_UIHoly_mouse_entered", [Utils.get_stat(Utils.stat_fantasy_holy_hash, i)])
        if !UIHolyInstance.is_connected("mouse_exited", self , "fa_on_UIHoly_mouse_exited"):
            UIHolyInstance.connect("mouse_exited", self , "fa_on_UIHoly_mouse_exited")
        
        UIHolyScenes[_players[i]] = UIHolyInstance

func _fantasy_soul_display() -> void:
    for i in _players.size():
        if _players[i] in UISoulScenes:
            continue
            
        var UISoulInstance = UI_SOUL_SCENE.instance()
        match i:
            0, 2: UISoulInstance.alignment = BoxContainer.ALIGN_BEGIN
            1, 3: UISoulInstance.alignment = BoxContainer.ALIGN_END
        
        var player_ui = _players_ui[i]
        if !is_instance_valid(player_ui) or !is_instance_valid(player_ui.hud_container):
            continue

        var after_gold_index = player_ui.hud_container.get_children().find(player_ui.gold) + 1
        player_ui.hud_container.add_child(UISoulInstance)
        player_ui.hud_container.move_child(UISoulInstance, after_gold_index)
        
        UISoulInstance.update_value(Utils.get_stat(Utils.stat_fantasy_soul_hash, i))
        
        if !UISoulInstance.is_connected("mouse_entered", self , "fa_on_UISoul_mouse_entered"):
            UISoulInstance.connect("mouse_entered", self , "fa_on_UISoul_mouse_entered")
        if !UISoulInstance.is_connected("mouse_exited", self , "fa_on_UISoul_mouse_exited"):
            UISoulInstance.connect("mouse_exited", self , "fa_on_UISoul_mouse_exited")
        
        UISoulScenes[_players[i]] = UISoulInstance

func _fantasy_holy_process() -> void:
    for i in _players.size():
        if _players[i] in UIHolyScenes and \
        is_instance_valid(UIHolyScenes[_players[i]]):
            UIHolyScenes[_players[i]].update_value(Utils.get_stat(Utils.stat_fantasy_holy_hash, i))

func _fantasy_soul_process() -> void:
    for i in _players.size():
        if _players[i] in UISoulScenes and \
        is_instance_valid(UISoulScenes[_players[i]]):
            UISoulScenes[_players[i]].update_value(Utils.get_stat(Utils.stat_fantasy_soul_hash, i))

func _fantasy_change_living_cursed_enemy(enemy: Enemy, is_add: bool) -> void:
    var num: int = 1 if is_add else -1
    if !enemy._outline_colors.has(Utils.CURSE_COLOR): return

    for player_index in RunData.get_player_count():
        Utils.ncl_quiet_add_stat(Utils.stat_fantasy_living_cursed_enemy_hash, num, player_index)
        LinkedStats.reset_player(player_index)

# =========================== Method =========================== #
func fa_update_all_ui_stats() -> void:
    _fantasy_holy_process()
    _fantasy_soul_process()

func fa_on_UIHoly_mouse_entered(stat_holy: int) -> void:
    if _cleaning_up:
        var damage_bouns: int = stat_holy
        var chance_drop_soul: int = int(stat_holy / (stat_holy + 50.0) * 100)
        var enemy_health_reduction: int = int(stat_holy / (stat_holy + 100.0) * 100)
        _info_popup.display(_ui_bonus_gold, Text.text("FANTASY_INFO_HOLY", [str(damage_bouns), str(chance_drop_soul), str(enemy_health_reduction)]))

func fa_on_UIHoly_mouse_exited() -> void:
    _info_popup.hide()

func fa_on_UISoul_mouse_entered() -> void:
    if _cleaning_up:
        var damage_bouns: int = 20
        var attack_speed_bouns: int = 20
        _info_popup.display(_ui_bonus_gold, Text.text("FANTASY_INFO_SOUL", [str(damage_bouns), str(attack_speed_bouns)]))

func fa_on_UISoul_mouse_exited() -> void:
    _info_popup.hide()

func fa_time_bouns_current_health_damage(bouns: float, player_index: int):
    var enemies: Array = _entity_spawner.get_all_enemies(false)
    for enemy in enemies:
        var enemy_current_hp: int = enemy.current_stats.health
        var enemy_max_hp: int = enemy.max_stats.health

        if enemy_current_hp == 1: continue
        
        var full_dmg_value: int = 0
        if enemy is Boss:
            full_dmg_value += int(enemy_current_hp * bouns / 10.0)
            enemy.current_stats.health -= full_dmg_value
        else:
            full_dmg_value += int(enemy_current_hp * bouns)
            enemy.current_stats.health -= full_dmg_value
        
        enemy.emit_signal("health_updated", enemy, enemy.current_stats.health, enemy_max_hp)
        enemy.emit_signal(
            "took_damage",
            enemy,
            full_dmg_value,
            Vector2.ZERO,
            false,
            false,
            false,
            false,
            TakeDamageArgs.new(player_index),
            HitType.NORMAL,
            false
        )
