extends "res://entities/units/player/player.gd"

# decaying_slow_enemy_when_below_hp
var decaying_slow_enemy_when_below_hp_triggers: Dictionary = {}
var _original_non_decaying_slow_speed: Dictionary = {}
var _non_decaying_slow_material: Dictionary = {}

# =========================== Extension =========================== #
func _ready() -> void:
    _fantasy_decaying_slow_enemy_when_below_hp_ready()

func get_damage_value(dmg_value: int, _from_player_index: int, armor_applied := true, dodgeable := true, _is_crit := false, _hitbox: Hitbox = null, _is_burning := false) -> Unit.GetDamageValueResult:
    var result: Unit.GetDamageValueResult =.get_damage_value(dmg_value, _from_player_index, armor_applied, dodgeable, _is_crit, _hitbox, _is_burning)
    result = _fantasy_damage_clamp(result)

    return result

func _on_LoseHealthTimer_timeout() -> void:
    if _fantasy_lose_hp_per_second_min_hp(): return
    ._on_LoseHealthTimer_timeout()

func take_damage(value: int, args: TakeDamageArgs) -> Array:
    var take_damage_array: Array =.take_damage(value, args)
    _fantasy_damage_reflect(take_damage_array[0], args)
    _fantasy_decaying_slow_enemy_when_below_hp(take_damage_array[1])
    _fantasy_loss_material_on_hit(take_damage_array[1])

    return take_damage_array

func _on_ItemAttractArea_area_entered(item: Item) -> void:
    ._on_ItemAttractArea_area_entered(item)
    _fantasy_on_soul_entered(item)

func on_consumable_picked_up(consumable_data: ConsumableData) -> void:
    .on_consumable_picked_up(consumable_data)
    _fantasy_dmg_when_pickup_consumable(consumable_data)

# =========================== Custom =========================== #
func _fantasy_damage_clamp(result: Unit.GetDamageValueResult) -> Unit.GetDamageValueResult:
    var effect_items: Array = RunData.get_player_effect(Utils.fantasy_damage_clamp_hash, player_index)
    for effect in effect_items:
        var max_hp: float = Utils.get_stat(Keys.stat_max_hp_hash, player_index)
        var tracking_key_hash: int = effect[0]
        var max_percent: float = effect[2] / 100.0
        var max_taken_dmg: int = int(clamp(result.value, min(effect[1], result.value), max_hp * max_percent))

        RunData.ncl_add_effect_tracking_value(tracking_key_hash, result.value - max_taken_dmg, player_index)
        result.value = max_taken_dmg

    return result

func _fantasy_damage_reflect(full_dmg_value: int, args: TakeDamageArgs) -> void:
    if !is_instance_valid(args.hitbox) or !is_instance_valid(args.hitbox.from): return

    if !(args.hitbox.from is Enemy): return

    var enemy: Enemy = args.hitbox.from
    var effect_items: Array = RunData.get_player_effect(Utils.fantasy_damage_reflect_hash, player_index)
    for effect_item in effect_items:
        var tracking_key_hash: int = effect_item[0]
        var reflect_percent: float = effect_item[1] / 100.0
        var reflect_args: TakeDamageArgs = TakeDamageArgs.new(player_index)
        var percent_damage_bonus: float = 1 + Utils.get_stat(Keys.stat_percent_damage_hash, player_index) / 100.0
        var reflect_damage: int = int(full_dmg_value * reflect_percent * percent_damage_bonus)

        RunData.add_tracked_value(player_index, tracking_key_hash, reflect_damage)
        enemy.take_damage(reflect_damage, reflect_args)

func _fantasy_decaying_slow_enemy_when_below_hp_ready() -> void:
    var effect_items: Array = RunData.get_player_effect(Utils.fantasy_decaying_slow_enemy_when_below_hp_hash, player_index)
    for effect_index in range(effect_items.size()):
        var effect: Array = effect_items[effect_index]
        decaying_slow_enemy_when_below_hp_triggers[effect_index] = effect[3] # Trigger times

func _fantasy_decaying_slow_enemy_when_below_hp(dmg_taken: int) -> void:
    if dmg_taken <= 0: return

    var effect_items: Array = RunData.get_player_effect(Utils.fantasy_decaying_slow_enemy_when_below_hp_hash, player_index)
    for effect_index in range(effect_items.size()):
        var effect: Array = effect_items[effect_index]
        var hp_threshold: float = max_stats.health * effect[0] / 100.0
        var duration: int = effect[1]
        var stat_nb: int = effect[2]

        if current_stats.health >= hp_threshold or decaying_slow_enemy_when_below_hp_triggers[effect_index] <= 0: continue

        decaying_slow_enemy_when_below_hp_triggers[effect_index] -= 1

        TempStats.add_stat(Utils.stat_fantasy_decaying_slow_enemy_hash, stat_nb, player_index) # For main.gd to use
        var enemies: Array = Utils.get_scene_node()._entity_spawner.get_all_enemies(false)
        for enemy in enemies:
            _original_non_decaying_slow_speed[enemy] = enemy.current_stats.speed
            enemy.current_stats.speed += enemy.current_stats.speed * stat_nb / 100.0
            match enemy.sprite.material == enemy.flash_mat:
                true: _non_decaying_slow_material[enemy] = enemy._non_flash_material
                false: _non_decaying_slow_material[enemy] = enemy.sprite.material
            enemy.sprite.material = load("res://mods-unpacked/Yoko-Fantasy/extensions/effects/decaying_slow_enemy_when_below_hp/decaying_slow_enemy_when_below_hp_shader.tres")

        yield (get_tree().create_timer(duration, false), "timeout")
        if cleaning_up: return

        TempStats.remove_stat(Utils.stat_fantasy_decaying_slow_enemy_hash, stat_nb, player_index)
        enemies = Utils.get_scene_node()._entity_spawner.get_all_enemies(false)
        for enemy in enemies:
            if !_original_non_decaying_slow_speed.has(enemy): continue

            enemy.current_stats.speed = _original_non_decaying_slow_speed[enemy]
            enemy.sprite.material = _non_decaying_slow_material[enemy]

        _original_non_decaying_slow_speed = {} # Reset for next
        _non_decaying_slow_material = {} # Reset for next
        break # Once a time when take damage

func _fantasy_loss_material_on_hit(dmg_taken: int) -> void:
    if dmg_taken <= 0: return

    var materials_to_remove: int = RunData.get_player_effect(Utils.fantasy_material_loss_on_hit_hash, player_index)
    if materials_to_remove <= 0: return

    RunData.remove_gold(materials_to_remove, player_index)
    RunData.emit_signal("stat_removed", Keys.stat_materials_hash, materials_to_remove, -15.0, player_index)

func _fantasy_dmg_when_pickup_consumable(consumable_data: ConsumableData) -> void:
    var effect_items: Array = RunData.get_player_effect(Utils.fantasy_dmg_when_pickup_consumable_hash, player_index)
    if effect_items.empty(): return

    for effect_item in effect_items:
        var consumable_id: int = effect_item[0]

        if consumable_data.my_id_hash != consumable_id: continue

        var enemies: Array = Utils.get_scene_node()._entity_spawner.get_all_enemies(false)

        if enemies.empty(): return

        enemies.shuffle()

        var max_num: int = effect_item[1]
        var scaling_stats: Array = effect_item[2]
        var base_damage: int = effect_item[3]
        var tracked_key: int = effect_item[4]
        var damage_color: Color = effect_item[5]
        var total_damage: int = Utils.ncl_get_dmg_with_scaling_stats(base_damage, scaling_stats, player_index)
        var damage_args: TakeDamageArgs = Utils.ncl_create_custom_damage_args(player_index, damage_color)

        var processed_count = 0
        for i in range(min(max_num, enemies.size())):
            var enemy: Enemy = enemies[i]

            if !is_instance_valid(enemy) or enemy.dead: continue

            var take_damage_array: Array = enemy.take_damage(total_damage, damage_args)
            RunData.add_tracked_value(player_index, tracked_key, take_damage_array[1])
            processed_count += 1

            if processed_count >= max_num: break

func _fantasy_lose_hp_per_second_min_hp() -> bool:
    var lose_hp_per_second_min_hp: int = RunData.get_player_effect(Utils.fantasy_lose_hp_per_second_min_hp_hash, player_index)
    if lose_hp_per_second_min_hp <= 0: return false

    _take_damage_args.dodgeable = false
    _take_damage_args.armor_applied = false
    _take_damage_args.bypass_invincibility = true
    _take_damage_args.from = self
    var lose_hp_per_second = RunData.get_player_effect(Keys.lose_hp_per_second_hash, player_index)
    if current_stats.health <= lose_hp_per_second + lose_hp_per_second_min_hp: lose_hp_per_second = current_stats.health - lose_hp_per_second_min_hp

    if lose_hp_per_second > 0: var _dmg_taken: Array = take_damage(lose_hp_per_second, _take_damage_args)
    elif lose_hp_per_second == 0: pass
    else: var _healed: int = on_healing_effect(-lose_hp_per_second)
    
    return true

func _fantasy_on_soul_entered(item: Item) -> void:
    if !(item is Consumable): return

    var consumable_data: ConsumableData = item.consumable_data
    if consumable_data.my_id_hash != Utils.consumable_fantasy_soul_hash: return

    if item.attracted_by == null:
        item.attracted_by = self
        item.set_physics_process(true)

# =========================== Method =========================== #
func fa_on_soul_effect(damage_to_add: int, speed_to_add: int) -> void:
    var timer: SceneTreeTimer = get_tree().create_timer(2.0, false)
    var _e: int = timer.connect("timeout", self , "fa_on_soul_effect_timer_timeout", [damage_to_add, speed_to_add])

func fa_on_soul_effect_timer_timeout(damage_to_add: int, speed_to_add: int) -> void:
    Utils.ncl_quiet_add_stat(Utils.stat_fantasy_soul_hash, -1, player_index)
    TempStats.remove_stat(Keys.stat_percent_damage_hash, damage_to_add, player_index)
    TempStats.remove_stat(Keys.stat_attack_speed_hash, speed_to_add, player_index)
