extends "res://entities/units/target_behavior/lootworm_target_behavior.gd"

# =========================== Extension =========================== #
func init(parent: Node) -> Node:
    .init(parent)
    var _error: int = _entity_spawner.connect("enemy_spawned", self , "fa_on_plant_enemy_spawned")
    return self

func update_target():
    if _fantasy_update_target_plant_enemy(): return
    if _fantasy_update_cannot_damage_tree(): return
    .update_target()

func on_gold_spawned():
    if fa_cleanup_previous_plant_enemy_target(): return
    .on_gold_spawned()

func on_neutral_spawned(entity: Entity):
    if fa_cleanup_previous_plant_enemy_target(): return
    .on_neutral_spawned(entity)

# =========================== Custom =========================== #    
func _fantasy_update_target_plant_enemy() -> bool:
    var min_dist_squared: int = Utils.LARGE_NUMBER
    var enemy_list: Array = _entity_spawner.plant_enemies

    if _parent.current_target != null:
        if _parent.current_target is Gold and _parent.current_target.is_connected("picked_up", self , "on_gold_picked_up_by_player"):
            _parent.current_target.disconnect("picked_up", self , "on_gold_picked_up_by_player")
        elif _parent.current_target is Neutral and _parent.current_target.is_connected("died", self , "on_dead_tree"):
            _parent.current_target.disconnect("died", self , "on_dead_tree")
        elif _parent.current_target is Enemy and _parent.current_target.is_connected("died", self , "fa_on_dead_plant_enemy"):
            _parent.current_target.disconnect("died", self , "fa_on_dead_plant_enemy")
    _parent.current_target = null

    for enemy in enemy_list:
        if enemy.dead: continue

        var dist_squared = global_position.distance_squared_to(enemy.global_position)
        if dist_squared < min_dist_squared:
            min_dist_squared = dist_squared
            _parent.current_target = enemy

    if _parent.current_target != null and !_parent.current_target.is_connected("died", self , "fa_on_dead_plant_enemy"):
        var _error = _parent.current_target.connect("died", self , "fa_on_dead_plant_enemy")
        emit_signal("target_found", self )
        return true
    return false

func _fantasy_update_cannot_damage_tree() -> bool:
    if !RunData.get_player_effect_bool(Utils.fantasy_cannot_damage_tree_hash, _parent.player_index): return false

    if _parent.current_target != null and _parent.current_target is Neutral and _parent.current_target.is_connected("died", self , "on_dead_tree"):
        _parent.current_target.disconnect("died", self , "on_dead_tree")
        _parent.current_target = null

    fa_update_target_gold()
    return true

# =========================== Method =========================== #
func fa_cleanup_previous_plant_enemy_target() -> bool:
    if !(_parent.current_target is Enemy) or !Utils.plant_enemies_ids.has(_parent.current_target.enemy_id_hash): return false
    
    _parent.current_target.disconnect("died", self , "fa_on_dead_plant_enemy")
    _parent.current_target = null
    return true

func fa_on_plant_enemy_spawned(enemy: Enemy) -> void:
    if !Utils.plant_enemies_ids.has(enemy.enemy_id_hash): return

    if _parent.current_target == null: return

    if _parent.current_target is Gold and _parent.current_target.is_connected("picked_up", self , "on_gold_picked_up_by_player"):
        _parent.current_target.disconnect("picked_up", self , "on_gold_picked_up_by_player")
    elif _parent.current_target is Neutral and _parent.current_target.is_connected("died", self , "on_dead_tree"):
        _parent.current_target.disconnect("died", self , "on_dead_tree")
    elif _parent.current_target is Enemy and _parent.current_target.is_connected("died", self , "fa_on_dead_plant_enemy"):
        _parent.current_target.disconnect("died", self , "fa_on_dead_plant_enemy")
    _parent.current_target = null

func fa_on_dead_plant_enemy(_entity: Entity, _die_args: Entity.DieArgs) -> void:
    if _parent.current_target != null: _parent.current_target.disconnect("died", self , "fa_on_dead_plant_enemy")
    _parent.current_target = null

func fa_update_target_gold() -> void:
    var min_dist_squared: int = Utils.LARGE_NUMBER
    var active_golds: Array = _main._active_golds

    for gold in active_golds:
        if gold.already_picked_up: continue

        var dist_squared = global_position.distance_squared_to(gold.global_position)
        if dist_squared < min_dist_squared:
            min_dist_squared = dist_squared
            _parent.current_target = gold

    if _parent.current_target != null:
        var _error = _parent.current_target.connect("picked_up", self , "on_gold_picked_up_by_player")
        emit_signal("target_found", self )
    else: _parent.current_target = self
