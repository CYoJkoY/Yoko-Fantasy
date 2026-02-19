extends "res://main.gd"

var FaTimers: Array = []

# ui_entry
var UIHolyScenes = {}
const UI_HOLY_SCENE = preload("res://mods-unpacked/Yoko-Fantasy/content/ui_entry/ui_holy.tscn")
var UISoulScenes = {}
const UI_SOUL_SCENE = preload("res://mods-unpacked/Yoko-Fantasy/content/ui_entry/ui_soul.tscn")

# =========================== Extension =========================== #
func _on_EntitySpawner_players_spawned(players: Array) -> void:
    ._on_EntitySpawner_players_spawned(players)
    _fantasy_holy_display()
    _fantasy_soul_display()

    _fantasy_start_ui_update_timer()
    _fantasy_start_time_bonus_current_health_damage_timer()

func _on_EntitySpawner_enemy_respawned(_enemy: Enemy) -> void:
    ._on_EntitySpawner_enemy_respawned(_enemy)
    call_deferred("_fantasy_change_living_cursed_enemy", _enemy, true)
    _fantasy_decaying_slow_enemy(_enemy)

func _on_enemy_died(enemy: Enemy, args: Entity.DieArgs) -> void:
    ._on_enemy_died(enemy, args)
    _fantasy_change_living_cursed_enemy(enemy, false)

func on_gold_picked_up(gold: Node, player_index: int) -> void:
    .on_gold_picked_up(gold, player_index)
    if player_index >= 0:
        _fantasy_random_reload_when_pickup_gold(player_index)

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

func _fantasy_start_time_bonus_current_health_damage_timer() -> void:
    for player_index in _players.size():
        var effect_items: Array = RunData.get_player_effect(Utils.fantasy_time_bonus_current_health_damage_hash, player_index)
        for effect in effect_items:
            var timer: Timer = Timer.new()
            timer.wait_time = effect[1]
            timer.autostart = true
            timer.connect("timeout", self , "fa_time_bonus_current_health_damage", [effect[2] / 100.0, player_index, effect[0]])
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
            UIHolyInstance.connect("mouse_entered", self , "fa_on_UIHoly_mouse_entered", [Utils.average_all_player_stats(Utils.stat_fantasy_holy_hash)])
        if !UIHolyInstance.is_connected("mouse_exited", self , "fa_on_UIHoly_mouse_exited"):
            UIHolyInstance.connect("mouse_exited", self , "fa_on_UIHoly_mouse_exited")
        
        UIHolyScenes[_players[i]] = UIHolyInstance

func _fantasy_soul_display() -> void:
    for i in _players.size():
        var effects: Dictionary = RunData.get_player_effects(i)
        effects[Utils.stat_fantasy_soul_hash] = 0
        RunData._are_player_stats_dirty[i] = true
        Utils.reset_stat_cache(i)

        if _players[i] in UISoulScenes: continue
            
        var UISoulInstance = UI_SOUL_SCENE.instance()
        match i:
            0, 2: UISoulInstance.alignment = BoxContainer.ALIGN_BEGIN
            1, 3: UISoulInstance.alignment = BoxContainer.ALIGN_END
        
        var player_ui = _players_ui[i]
        if !is_instance_valid(player_ui) or !is_instance_valid(player_ui.hud_container): continue

        var after_gold_index = player_ui.hud_container.get_children().find(player_ui.gold) + 1
        player_ui.hud_container.add_child(UISoulInstance)
        player_ui.hud_container.move_child(UISoulInstance, after_gold_index)
        
        UISoulInstance.update_value(RunData.get_stat(Utils.stat_fantasy_soul_hash, i))
        
        if !UISoulInstance.is_connected("mouse_entered", self , "fa_on_UISoul_mouse_entered"):
            UISoulInstance.connect("mouse_entered", self , "fa_on_UISoul_mouse_entered", [i])
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
            UISoulScenes[_players[i]].update_value(RunData.get_stat(Utils.stat_fantasy_soul_hash, i))

func _fantasy_change_living_cursed_enemy(enemy: Enemy, is_add: bool) -> void:
    var num: int = 1 if is_add else -1
    if !enemy._outline_colors.has(Utils.CURSE_COLOR): return

    for player_index in _players.size():
        Utils.ncl_quiet_add_stat(Utils.stat_fantasy_living_cursed_enemy_hash, num, player_index)
        LinkedStats.reset_player(player_index)

func _fantasy_random_reload_when_pickup_gold(player_index: int) -> void:
    var random_weapon: Weapon = Utils.get_rand_element(_players[player_index].current_weapons)
    var effect_items: Array = RunData.get_player_effect(Utils.fantasy_random_reload_when_pickup_gold_hash, player_index)

    for effect_item in effect_items:
        var chance: float = effect_item[1] / 100.0

        if !Utils.get_chance_success(chance): continue

        var tracking_key_hash: int = effect_item[0]
        RunData.ncl_add_effect_tracking_value(tracking_key_hash, 1, player_index)

        random_weapon._current_cooldown = 0
        random_weapon.tween_animation.interpolate_property(
            random_weapon.sprite, "self_modulate",
            Color("#3E68DA"), Color.white, 0.48,
            Tween.TRANS_SINE, Tween.EASE_IN_OUT
        )
        random_weapon.tween_animation.start()
        
func _fantasy_decaying_slow_enemy(enemy: Enemy) -> void:
    # For decaying slow new enemy
    for player_index in _players.size():
        var stat_nb: float = TempStats.get_stat(Utils.stat_fantasy_decaying_slow_enemy_hash, player_index)
        if stat_nb == 0: continue

        var player: Player = _players[player_index]
        enemy.current_stats.speed += int(enemy.current_stats.speed * stat_nb / 100.0)
        match enemy.sprite.material == enemy.flash_mat:
            true: player._non_decaying_slow_material[enemy] = enemy._non_flash_material
            false: player._non_decaying_slow_material[enemy] = enemy.sprite.material
        enemy.sprite.material = load("res://mods-unpacked/Yoko-Fantasy/extensions/effects/decaying_slow_enemy_when_below_hp/decaying_slow_enemy_when_below_hp_shader.tres")

# =========================== Method =========================== #
func fa_update_all_ui_stats() -> void:
    _fantasy_holy_process()
    _fantasy_soul_process()

func fa_on_UIHoly_mouse_entered(stat_holy: int) -> void:
    if _cleaning_up:
        var damage_bonus: int = stat_holy
        var chance_drop_soul: int = int(stat_holy / (stat_holy + 50.0) * 100)
        var enemy_health_reduction: int = int(stat_holy / (stat_holy + 100.0) * 100)
        _info_popup.display(_ui_bonus_gold, Text.text("FANTASY_INFO_HOLY", [str(damage_bonus), str(chance_drop_soul), str(enemy_health_reduction)]))

func fa_on_UIHoly_mouse_exited() -> void:
    _info_popup.hide()

func fa_on_UISoul_mouse_entered(player_index: int) -> void:
    if _cleaning_up:
        var bonus: int = 20 + RunData.get_player_effect(Utils.fantasy_soul_bonus_hash, player_index)
        _info_popup.display(_ui_bonus_gold, Text.text("FANTASY_INFO_SOUL", [str(bonus), str(bonus)]))

func fa_on_UISoul_mouse_exited() -> void:
    _info_popup.hide()

func fa_time_bonus_current_health_damage(bonus: float, player_index: int, tracking_key_hash: int):
    var enemies: Array = _entity_spawner.get_all_enemies(false)
    for enemy in enemies:
        var enemy_current_hp: int = enemy.current_stats.health
        var enemy_max_hp: int = enemy.max_stats.health

        if enemy_current_hp == 1: continue
        
        var full_dmg_value: int = 0
        if enemy is Boss:
            full_dmg_value += int(enemy_current_hp * bonus / 10.0)
            enemy.current_stats.health -= full_dmg_value
        else:
            full_dmg_value += int(enemy_current_hp * bonus)
            enemy.current_stats.health -= full_dmg_value
        
        RunData.add_tracked_value(player_index, tracking_key_hash, full_dmg_value)
        enemy.emit_signal("health_updated", enemy, enemy.current_stats.health, enemy_max_hp)

        var time_bonus_args: TakeDamageArgs = TakeDamageArgs.new(player_index)
        enemy.emit_signal(
            "took_damage",
            enemy,
            full_dmg_value,
            Vector2.ZERO,
            false,
            false,
            false,
            false,
            time_bonus_args,
            HitType.NORMAL,
            false
        )
