class_name EnemySpeedModifierService
extends Reference

const BASE_SPEED_META: String = "fantasy_enemy_base_speed"
const MODIFIERS_META: String = "fantasy_enemy_speed_modifiers"


static func set_percent_modifier(enemy: Node, source_id, percent: float) -> void:
    set_modifier(enemy, source_id, 0.0, percent)


static func set_modifier(enemy: Node, source_id, flat: float, percent: float) -> void:
    if !_can_modify(enemy):
        return

    _ensure_base_speed(enemy)
    var modifiers: Dictionary = _get_modifiers(enemy)
    modifiers[str(source_id)] = {
        "flat": flat,
        "percent": percent,
    }
    enemy.set_meta(MODIFIERS_META, modifiers)
    _apply(enemy)


static func remove_modifier(enemy: Node, source_id) -> void:
    if !_has_speed_stats(enemy) or !enemy.has_meta(MODIFIERS_META):
        return

    var modifiers: Dictionary = _get_modifiers(enemy)
    modifiers.erase(str(source_id))
    if modifiers.empty():
        var base_speed: int = _get_base_speed(enemy)
        enemy.current_stats.speed = base_speed
        enemy.remove_meta(MODIFIERS_META)
        enemy.remove_meta(BASE_SPEED_META)
        return

    enemy.set_meta(MODIFIERS_META, modifiers)
    _apply(enemy)


static func add_base_speed(enemy: Node, value: int) -> void:
    if !_can_modify(enemy):
        return

    if enemy.has_meta(BASE_SPEED_META) or enemy.has_meta(MODIFIERS_META):
        var base_speed: int = _get_base_speed(enemy) + value
        enemy.set_meta(BASE_SPEED_META, base_speed)
        enemy.max_stats.speed += value
        _apply(enemy)
        return

    enemy.current_stats.speed += value
    enemy.max_stats.speed += value


static func clear_all(enemy: Node) -> void:
    if !_has_speed_stats(enemy):
        return

    if enemy.has_meta(BASE_SPEED_META):
        enemy.current_stats.speed = _get_base_speed(enemy)
    if enemy.has_meta(MODIFIERS_META):
        enemy.remove_meta(MODIFIERS_META)
    if enemy.has_meta(BASE_SPEED_META):
        enemy.remove_meta(BASE_SPEED_META)


static func clear_pooled_state(enemy: Node) -> void:
    if !is_instance_valid(enemy):
        return
    if enemy.has_meta(MODIFIERS_META):
        enemy.remove_meta(MODIFIERS_META)
    if enemy.has_meta(BASE_SPEED_META):
        enemy.remove_meta(BASE_SPEED_META)


static func _can_modify(enemy: Node) -> bool:
    return _has_speed_stats(enemy) and !enemy.get("dead")


static func _has_speed_stats(enemy: Node) -> bool:
    return is_instance_valid(enemy) and enemy.get("current_stats") != null and enemy.get("max_stats") != null


static func _ensure_base_speed(enemy: Node) -> void:
    if !enemy.has_meta(BASE_SPEED_META):
        enemy.set_meta(BASE_SPEED_META, int(enemy.current_stats.speed))


static func _get_base_speed(enemy: Node) -> int:
    if enemy.has_meta(BASE_SPEED_META):
        return int(enemy.get_meta(BASE_SPEED_META))

    return int(enemy.current_stats.speed)


static func _get_modifiers(enemy: Node) -> Dictionary:
    if enemy.has_meta(MODIFIERS_META):
        return enemy.get_meta(MODIFIERS_META)

    return {}


static func _apply(enemy: Node) -> void:
    var speed: float = float(_get_base_speed(enemy))
    var modifiers: Dictionary = _get_modifiers(enemy)

    for source_id in modifiers.keys():
        speed += float(modifiers[source_id].get("flat", 0.0))

    for source_id in modifiers.keys():
        speed *= 1.0 + float(modifiers[source_id].get("percent", 0.0)) / 100.0

    enemy.current_stats.speed = max(1, int(round(speed)))
