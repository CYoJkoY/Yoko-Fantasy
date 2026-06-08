extends "res://global/entity_spawner.gd"

const PROJECTILE_SHADER = preload("res://resources/shaders/hue_shift_shadermat.tres")

# EFFECT: gain_stat_every_killed_enemies
var gain_stat_ever_killed_enemies_killed_count: Array = [0, 0, 0, 0]

# EFFECT: cannot_damage_tree
var plant_enemies: Array = []

# EFFECT: clock_tower_area
var _fantasy_clock_tower_structure_spawn_counts: Dictionary = {}
var _fantasy_clock_tower_starting_offsets: Array = [
    Vector2(-1, -181), #↑
    Vector2(157, -92), #↗
    Vector2(158, 92), #↘
    Vector2(1, 183),  #↓
    Vector2(-157, 95), #↙
    Vector2(-158, -90), #↖
]

# =========================== Extension =========================== #
func _ready() -> void:
    var _err: int = connect("enemy_respawned", self , "fa_add_plant_enemy_on_enemy_respawned")

func _on_enemy_died(enemy: Node2D, _args: Entity.DieArgs) -> void:
    ._on_enemy_died(enemy, _args)
    if !_cleaning_up:
        _fantasy_gain_stat_every_killed_enemies()
        if plant_enemies.has(enemy): plant_enemies.erase(enemy)
        _fantasy_target_enemy_killed(enemy, _args)
        if enemy._outline_colors.has(Utils.CURSE_COLOR): _fantasy_cursed_kill_healing(_args)

func on_enemy_charmed(enemy: Entity) -> void:
    .on_enemy_charmed(enemy)
    if plant_enemies.has(enemy): plant_enemies.erase(enemy)
    _fantasy_charm_enemy_with_detect_ability(enemy)

func spawn_entity_birth(
    type: int,
    scene: PackedScene,
    pos: Vector2,
    data: Resource = null,
    player_index: = - 1,
    source = null,
    charmed_by: = - 1
    ) -> void:
    if type == EntityType.STRUCTURE:
        pos = _fantasy_get_clock_tower_structure_pos(player_index, pos)

    .spawn_entity_birth(type, scene, pos, data, player_index, source, charmed_by)

# =========================== Custom =========================== #
func _fantasy_get_clock_tower_structure_pos(player_index: int, fallback_pos: Vector2) -> Vector2:
    var clock_tower_areas: Array = RunData.get_player_effect(Utils.fantasy_clock_tower_area_hash, player_index)
    if clock_tower_areas.empty():
        return fallback_pos

    var clock_tower_area: Array = clock_tower_areas[0]
    var base_range: int = clock_tower_area[0]
    var range_rate: float = clock_tower_area[1] / 100.0
    var radius: float = Utils.fa_get_clock_tower_area_radius(base_range, range_rate, player_index)
    var center_pos: Vector2 = ZoneService.get_map_center()
    var angle: float = rand_range(0.0, TAU)
    var spawn_count: int = _fantasy_clock_tower_structure_spawn_counts.get(player_index, 0)

    if spawn_count < 6:
        var visual_scale: float = radius / 236.0
        _fantasy_clock_tower_structure_spawn_counts[player_index] = spawn_count + 1
        return center_pos + _fantasy_clock_tower_starting_offsets[spawn_count] * visual_scale

    _fantasy_clock_tower_structure_spawn_counts[player_index] = spawn_count + 1
    return center_pos + Vector2.RIGHT.rotated(angle) * radius

func _fantasy_gain_stat_every_killed_enemies() -> void:
    for player_index in RunData.get_player_count():
        var effect_items: Array = RunData.get_player_effect(Utils.fantasy_gain_stat_every_killed_enemies_hash, player_index)
        gain_stat_ever_killed_enemies_killed_count[player_index] += 1
        for effect in effect_items:
            var value: int = effect[0]
            var stat: int = effect[1]
            var stat_nb: int = effect[2]
            var is_temp: bool = effect[3]

            if gain_stat_ever_killed_enemies_killed_count[player_index] % value != 0: continue

            if is_temp: TempStats.add_stat(stat, stat_nb, player_index)
            else: RunData.add_stat(stat, stat_nb, player_index)

            # Update when hit_protection first added
            if stat == Keys.hit_protection_hash:
                _main._players[player_index]._hit_protection += stat_nb

func _fantasy_charm_enemy_with_detect_ability(enemy: Enemy) -> void:
    for attack_behavior in enemy._all_attack_behaviors:
        if !("custom_collision_mask" in attack_behavior): continue

        attack_behavior.custom_collision_mask = Utils.PET_PROJECTILES_BIT
        var new_shader: Resource = PROJECTILE_SHADER.duplicate()
        new_shader.set_shader_param("hue", Utils.CHARM_COLOR.h)
        attack_behavior.custom_sprite_material = new_shader

func _fantasy_target_enemy_killed(enemy: Enemy, args: Entity.DieArgs) -> void:
    var player_index: int = args.killed_by_player_index
    if player_index < 0 or player_index == RunData.DUMMY_PLAYER_INDEX: return

    var effects: Dictionary = RunData.get_player_effects(player_index)
    var enemy_id: int = enemy.enemy_id_hash
    var kill_count_hash: int = Utils.fantasy_target_enemy_killed_hash
    var target_enemy_killed: Dictionary = effects[kill_count_hash]
    target_enemy_killed[enemy_id] = target_enemy_killed.get(enemy_id, 0) + 1

    var effect_items: Array = effects[Utils.fantasy_on_target_enemy_killed_buff_future_target_enemy_hash]
    for effect_item in effect_items:
        var trigger_enemy_id: int = effect_item[0]
        var target_enemy_id: int = effect_item[1]
        var trigger_need_num: int = effect_item[2]
        var future_stat: int = effect_item[3]
        var stat_num: int = effect_item[4]
        var tracking_key: int = effect_item[5]

        if trigger_enemy_id != enemy_id: continue

        var trigger_enemy_killed: int = target_enemy_killed[trigger_enemy_id]
        var if_trigger: bool = trigger_enemy_killed % trigger_need_num == 0

        if !if_trigger: continue
        
        RunData.ncl_add_effect_tracking_value(tracking_key, stat_num, player_index)

        var target_enemy_buffed: Dictionary = effects[Utils.fantasy_buff_future_target_enemy_hash]
        if !target_enemy_buffed.has(target_enemy_id):
            target_enemy_buffed[target_enemy_id] = [0, 0, 0, 0]
            target_enemy_buffed[target_enemy_id][future_stat] = stat_num
        else: target_enemy_buffed[target_enemy_id][future_stat] += stat_num

func _fantasy_cursed_kill_healing(args: Entity.DieArgs) -> void:
    var player_index: int = args.killed_by_player_index
    if player_index < 0 or player_index == RunData.DUMMY_PLAYER_INDEX: return

    var cursed_kill_healing_effects: Array = RunData.get_player_effect(Utils.fantasy_cursed_kill_healing_hash, player_index)
    for cursed_kill_healing in cursed_kill_healing_effects:
        if cursed_kill_healing[0] <= 0: continue

        RunData.emit_signal("healing_effect", cursed_kill_healing[0], player_index, Keys.empty_hash)
        RunData.ncl_add_effect_tracking_value(cursed_kill_healing[1], cursed_kill_healing[0], player_index)

# =========================== Method =========================== #
func fa_add_plant_enemy_on_enemy_respawned(enemy: Enemy) -> void:
    if !Utils.plant_enemies_ids.has(enemy.enemy_id_hash): return

    plant_enemies.append(enemy)
