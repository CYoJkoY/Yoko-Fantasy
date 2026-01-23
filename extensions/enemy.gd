extends "res://entities/units/enemies/enemy.gd"

# Stat_Holy
var _holy_health_reduction_applied: bool = false
var _original_max_health: int = 0
var _original_current_health: int = 0

# =========================== Extension =========================== #
func init(zone_min_pos: Vector2, zone_max_pos: Vector2, p_players_ref: Array = [], entity_spawner_ref = null) -> void:
    .init(zone_min_pos, zone_max_pos, p_players_ref, entity_spawner_ref)
    _fantasy_apply_holy_effects()

func respawn() -> void:
    .respawn()
    _fantasy_apply_holy_effects()

func get_damage_value(dmg_value: int, from_player_index: int, armor_applied: = true, dodgeable: = true, is_crit: = false, hitbox: Hitbox = null, is_burning: = false) -> GetDamageValueResult:
    var dmg_value_result = .get_damage_value(dmg_value, from_player_index, armor_applied, dodgeable, is_crit, hitbox, is_burning)
    dmg_value_result = _fantasy_apply_holy_damage_bonus(dmg_value_result, from_player_index)

    return dmg_value_result

# =========================== Custom =========================== #
func _fantasy_apply_holy_effects() -> void:
    if not _holy_health_reduction_applied:
        _original_max_health = max_stats.health
        _original_current_health = current_stats.health
    
    var total_holy: int = 0
    for i in range(players_ref.size()):
        total_holy += int(Utils.get_stat(Keys.fantasy_stat_holy_hash, i))
    if total_holy <= 0:
        return
    
    var reduction_factor: float = total_holy / (total_holy + 100.0)
    if reduction_factor <= 0:
        return

    var new_max_health = max(1, int(_original_max_health * reduction_factor))
    var new_current_health = max(1, int(_original_current_health * reduction_factor))
    
    max_stats.health = new_max_health
    current_stats.health = new_current_health
    _holy_health_reduction_applied = true

func _fantasy_apply_holy_damage_bonus(dmg_value_result: GetDamageValueResult, from_player_index: int) -> GetDamageValueResult:
    if fa_is_cursed():
        var holy_stat = Utils.get_stat(Keys.fantasy_stat_holy_hash, from_player_index)
        if holy_stat > 0:
            var bonus_multiplier = 1.0 + (holy_stat * 0.01)
            dmg_value_result.value = int(dmg_value_result.value * bonus_multiplier)
    
    return dmg_value_result

# =========================== Method =========================== #
func fa_is_cursed() -> bool:
    if dead:
        return false
    
    for effect_behavior in effect_behaviors.get_children():
        if effect_behavior is CurseEnemyEffectBehavior:
            return true
    
    return false
