extends "res://entities/units/player/player.gd"

# =========================== Extension =========================== #
func get_damage_value(dmg_value: int, _from_player_index: int, armor_applied := true, dodgeable := true, _is_crit := false, _hitbox: Hitbox = null, _is_burning := false) -> Unit.GetDamageValueResult:
    var result :=.get_damage_value(dmg_value, _from_player_index, armor_applied, dodgeable, _is_crit, _hitbox, _is_burning)
    result = _fantasy_damage_clamp(result)

    return result

func take_damage(value: int, args: TakeDamageArgs) -> Array:
    var take_damage_array: Array =.take_damage(value, args)
    _fantasy_damage_reflect(take_damage_array[0], args)

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
