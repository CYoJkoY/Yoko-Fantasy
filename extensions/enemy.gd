extends "res://entities/units/enemies/enemy.gd"

# =========================== Extension =========================== #
func init(zone_min_pos: Vector2, zone_max_pos: Vector2, p_players_ref: Array = [], entity_spawner_ref = null) -> void:
    .init(zone_min_pos, zone_max_pos, p_players_ref, entity_spawner_ref)
    _fantasy_extra_curse_enemy()
    _fantasy_holy_reduce_health()
    _fantasy_buff_future_target()
    if Utils.plant_enemies_ids.has(enemy_id_hash): _fantasy_cannot_tree_damage()

func respawn() -> void:
    .respawn()
    _fantasy_extra_curse_enemy()
    _fantasy_holy_reduce_health()
    _fantasy_buff_future_target()
    if Utils.plant_enemies_ids.has(enemy_id_hash): _fantasy_cannot_tree_damage()

func update_target() -> void:
    .update_target()
    if Utils.plant_enemies_ids.has(enemy_id_hash): _fantasy_update_cannot_tree_damage_target()

func is_playing_shoot_animation() -> bool:
    var is_playing_shoot: bool =.is_playing_shoot_animation()
    if Utils.plant_enemies_ids.has(enemy_id_hash): is_playing_shoot = _fantasy_is_playing_shoot_animation_cannot_tree_damage(is_playing_shoot)

    return is_playing_shoot

func _on_Hurtbox_area_entered(hitbox: Area2D) -> void:
    if Utils.plant_enemies_ids.has(enemy_id_hash): _fantasy_cannot_damage_tree(hitbox)
    ._on_Hurtbox_area_entered(hitbox)

func get_stats_value() -> int:
    var value: int =.get_stats_value()
    value = _fantasy_bonus_drop(value)

    return value

func get_damage_value(dmg_value: int, from_player_index: int, armor_applied := true, dodgeable := true, is_crit := false, hitbox: Hitbox = null, is_burning := false) -> GetDamageValueResult:
    var dmg_value_result: GetDamageValueResult =.get_damage_value(dmg_value, from_player_index, armor_applied, dodgeable, is_crit, hitbox, is_burning)
    dmg_value_result = _fantasy_apply_holy_damage_bonus(dmg_value_result)

    return dmg_value_result

# =========================== Custom =========================== #
func _fantasy_holy_reduce_health() -> void:
    var holy_stat: int = int(Utils.average_all_player_stats(Utils.stat_fantasy_holy_hash))
    if holy_stat <= 0: return

    var reduction_factor: float = holy_stat / (holy_stat + 100.0)
    current_stats.health -= int(current_stats.health * reduction_factor)
    max_stats.health = current_stats.health

func _fantasy_apply_holy_damage_bonus(dmg_value_result: GetDamageValueResult) -> GetDamageValueResult:
    if dead: return dmg_value_result

    if _outline_colors.has(Utils.CURSE_COLOR): return dmg_value_result

    var holy_stat: float = Utils.average_all_player_stats(Utils.stat_fantasy_holy_hash)
    if holy_stat <= 0: return dmg_value_result

    var bonus_multiplier: float = 1.0 + (holy_stat / 100.0)
    dmg_value_result.value = int(dmg_value_result.value * bonus_multiplier)
    
    return dmg_value_result

func _fantasy_extra_curse_enemy() -> void:
    if _outline_colors.has(Utils.CURSE_COLOR): return

    for player_index in range(players_ref.size()):
        var effect_items: Array = RunData.get_player_effect(Utils.fantasy_extra_curse_enemy_hash, player_index)
        for effect_item in effect_items:
            var chance: float = effect_item[1] / 100.0
            if !Utils.get_chance_success(chance): continue

            Utils.ncl_curse_enemy(self )
            RunData.ncl_add_effect_tracking_value(effect_item[0], 1, player_index)

func _fantasy_bonus_drop(value: int) -> int:
    for player_index in range(players_ref.size()):
        var effect_items: Array = RunData.get_player_effect(Utils.fantasy_bonus_drop_from_target_hash, player_index)
        for effect_item in effect_items:
            var target_id: int = effect_item[0]
            var bonus_gold: int = effect_item[1]
            if target_id != enemy_id_hash: continue

            value += bonus_gold

    return value

func _fantasy_buff_future_target() -> void:
    for player_index in range(players_ref.size()):
        var target_enemy_buffed: Dictionary = RunData.get_player_effect(Utils.fantasy_buff_future_target_enemy_hash, player_index)
        if !target_enemy_buffed.has(enemy_id_hash): continue

        var bonus_stats: Array = target_enemy_buffed[enemy_id_hash]
        fa_apply_stat_to_both(Utils.FANTASY_ENEMY_HP, bonus_stats[0])
        fa_apply_stat_to_both(Utils.FANTASY_ENEMY_SPEED, bonus_stats[1])
        fa_apply_stat_to_both(Utils.FANTASY_ENEMY_DAMAGE, bonus_stats[2])
        fa_apply_stat_to_both(Utils.FANTASY_ENEMY_ARMOR, bonus_stats[3])

func _fantasy_cannot_tree_damage() -> void:
    for player_index in range(players_ref.size()):
        if !RunData.get_player_effect_bool(Utils.fantasy_cannot_damage_tree_hash, player_index): continue

        _hitbox.ignored_objects.append(players_ref[player_index])

func _fantasy_update_cannot_tree_damage_target() -> void:
    for player_index in range(players_ref.size()):
        if !RunData.get_player_effect_bool(Utils.fantasy_cannot_damage_tree_hash, player_index): continue

        if current_target != players_ref[player_index]: continue

        current_target.disconnect("died", self , "_on_target_died")
        current_target = null
        break

func _fantasy_is_playing_shoot_animation_cannot_tree_damage(is_playing_shoot: bool) -> bool:
    for player_index in range(players_ref.size()):
        if !RunData.get_player_effect_bool(Utils.fantasy_cannot_damage_tree_hash, player_index): continue

        if current_target == null:
            update_target()
            return true

    return is_playing_shoot

func _fantasy_cannot_damage_tree(hitbox: Area2D) -> void:
    if !is_instance_valid(hitbox) or \
    !is_instance_valid(hitbox.from) or \
    hitbox.from.player_index == -1 or \
    hitbox.from.player_index == RunData.DUMMY_PLAYER_INDEX: return

    var player_index: int = hitbox.from.player_index
    if RunData.get_player_effect_bool(Utils.fantasy_cannot_damage_tree_hash, player_index): hitbox.ignored_objects.append(self )

# =========================== Method =========================== #
func fa_apply_stat_to_both(target_stat: int, value: int) -> void:
    match target_stat:
        Utils.FANTASY_ENEMY_HP:
            current_stats.health += value
            max_stats.health += value
        Utils.FANTASY_ENEMY_SPEED:
            current_stats.speed += value
            max_stats.speed += value
        Utils.FANTASY_ENEMY_DAMAGE:
            current_stats.damage += value
            max_stats.damage += value
        Utils.FANTASY_ENEMY_ARMOR:
            current_stats.armor += value
            max_stats.armor += value
