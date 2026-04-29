extends "res://global/entity_spawner.gd"

const PROJECTILE_SHADER = preload("res://resources/shaders/hue_shift_shadermat.tres")

# EFFECT: gain_stat_every_killed_enemies
var gain_stat_ever_killed_enemies_killed_count: Array = [0, 0, 0, 0]

# EFFECT: fantasy_lootworm
var plant_enemies: Array = []
var plant_enemies_ids: Array = [
    "fantasy_tree_spirit",
    "fantasy_vine_stranger",
    "fantasy_flower_spirit"
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

func on_enemy_charmed(enemy: Entity) -> void:
    .on_enemy_charmed(enemy)
    if plant_enemies.has(enemy): plant_enemies.erase(enemy)
    _fantasy_charm_enemy_with_detect_ability(enemy)

# =========================== Custom =========================== #
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
    effects[kill_count_hash][enemy_id] = effects[kill_count_hash].get(enemy_id, 0) + 1

# =========================== Method =========================== #
func fa_add_plant_enemy_on_enemy_respawned(enemy: Enemy) -> void:
    if !plant_enemies_ids.has(enemy.enemy_id): return

    plant_enemies.append(enemy)
