extends "res://entities/units/player/player.gd"

# decaying_slow_enemy_when_below_hp
var decaying_slow_enemy_when_below_hp_triggers: Dictionary = {}
var _non_decaying_slow_material: Dictionary = {}

# =========================== Extension =========================== #
func _ready() -> void:
    _fantasy_decaying_slow_enemy_when_below_hp_ready()

func get_damage_value(dmg_value: int, _from_player_index: int, armor_applied := true, dodgeable := true, _is_crit := false, _hitbox: Hitbox = null, _is_burning := false) -> Unit.GetDamageValueResult:
    var result: Unit.GetDamageValueResult =.get_damage_value(dmg_value, _from_player_index, armor_applied, dodgeable, _is_crit, _hitbox, _is_burning)
    result = _fantasy_damage_clamp(result)

    return result

func take_damage(value: int, args: TakeDamageArgs) -> Array:
    var take_damage_array: Array =.take_damage(value, args)
    _fantasy_damage_reflect(take_damage_array[0], args)
    _fantasy_decaying_slow_enemy_when_below_hp(take_damage_array[1])

    return take_damage_array

# =========================== Custom =========================== #
func _fantasy_damage_clamp(result: Unit.GetDamageValueResult) -> Unit.GetDamageValueResult:
    var effect_items: Array = RunData.get_player_effect(Utils.fantasy_damage_clamp_hash, player_index)
    for effect in effect_items:
        var max_hp: float = Utils.get_stat(Keys.stat_max_hp_hash, player_index)
        var tracking_key_hash: int = effect[0]
        var max_percent: float = effect[2] / 100.0
        var max_taken_dmg: int = int(clamp(result.value, effect[1], max_hp * max_percent))

        RunData.ncl_add_effect_tracking_value(tracking_key_hash, result.value - max_taken_dmg, player_index)
        result.value = max_taken_dmg

    return result

func _fantasy_damage_reflect(full_dmg_value: int, args: TakeDamageArgs) -> void:
    if !args.hitbox or !args.hitbox.from \
    or !(args.hitbox.from is Enemy): return

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
    for effect_index in effect_items.size():
        var effect: Array = effect_items[effect_index]
        decaying_slow_enemy_when_below_hp_triggers[effect_index] = effect[3] # Trigger times

func _fantasy_decaying_slow_enemy_when_below_hp(dmg_taken: int) -> void:
    if dmg_taken <= 0: return

    var effect_items: Array = RunData.get_player_effect(Utils.fantasy_decaying_slow_enemy_when_below_hp_hash, player_index)
    for effect_index in effect_items.size():
        var effect: Array = effect_items[effect_index]
        var hp_threshold: float = max_stats.health * effect[0] / 100.0
        var duration: int = effect[1]
        var stat_nb: int = effect[2]

        if current_stats.health >= hp_threshold or decaying_slow_enemy_when_below_hp_triggers[effect_index] <= 0: continue

        decaying_slow_enemy_when_below_hp_triggers[effect_index] -= 1

        TempStats.add_stat(Utils.stat_fantasy_decaying_slow_enemy_hash, stat_nb, player_index) # For main.gd to use
        var enemies: Array = Utils.get_scene_node()._entity_spawner.get_all_enemies(false)
        for enemy in enemies:
            enemy.current_stats.speed += enemy.current_stats.speed * stat_nb / 100.0
            match enemy.sprite.material == enemy.flash_mat:
                true: _non_decaying_slow_material[enemy] = enemy._non_flash_material
                false: _non_decaying_slow_material[enemy] = enemy.sprite.material
            enemy.sprite.material = load("res://mods-unpacked/Yoko-Fantasy/extensions/effects/decaying_slow_enemy_when_below_hp/decaying_slow_enemy_when_below_hp_shader.tres")

        yield (get_tree().create_timer(duration, false), "timeout")
        if cleaning_up: return

        TempStats.set_stat(Utils.stat_fantasy_decaying_slow_enemy_hash, 0, player_index)
        enemies = Utils.get_scene_node()._entity_spawner.get_all_enemies(false)
        for enemy in enemies:
            enemy.current_stats.speed = enemy.max_stats.speed
            enemy.sprite.material = _non_decaying_slow_material[enemy]
        
        _non_decaying_slow_material = {} # Reset for next
        break # Once a time when take damage
