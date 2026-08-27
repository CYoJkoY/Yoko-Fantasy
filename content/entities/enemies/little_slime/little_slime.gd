class_name LittleSlime
extends Enemy

export(String, FILE, "*.tscn") var evolution_target_path = ""
var evolution_target: PackedScene = null
export(int) var evovle_needed = 5
export(bool) var can_pick_up_materials: bool = false
export(Array, String) var white_list = [
    "fantasy_little_slime", "fantasy_medium_slime",
    "fantasy_big_slime", "fantasy_slime_king"
]

var evolve_count: int = 0
var _evolution_pending: bool = false
var _is_evolving: bool = false
var _tracked_enemies: Dictionary = {}

# ══════════════════════════════════════════ Extension ══════════════════════════════════════════ #
func _ready() -> void:
    if evolution_target_path: evolution_target = load(evolution_target_path)

func respawn() -> void:
    _disconnect_tracked_enemies()
    .respawn()
    evolve_count = 0
    _evolution_pending = false
    _is_evolving = false

func die(args: = Utils.default_die_args) -> void:
    if dead: return
    _disconnect_tracked_enemies()
    .die(args)

# ══════════════════════════════════════════ Method ══════════════════════════════════════════ #
func fa_on_DetectionArea_body_entered(body: Enemy) -> void:
    if dead or !is_instance_valid(body) or body.dead or white_list.has(body.enemy_id): return

    if !_tracked_enemies.has(body):
        _tracked_enemies[body] = true
    if !body.is_connected("died", self, "fa_on_enemy_died"):
        body.connect("died", self, "fa_on_enemy_died")

func fa_on_DetectionArea_body_exited(body: Enemy) -> void:
    _disconnect_tracked_enemy(body)

func fa_on_ItemAttractArea_area_entered(item: Item) -> void:
    if dead or _evolution_pending or !can_pick_up_materials or !(item is Gold): return

    var item_already_attracted_by_player: bool = item.attracted_by != null
    if item_already_attracted_by_player: return

    item.attracted_by = self
    item.set_physics_process(true)

func fa_on_ItemPickUpArea_area_entered(area: Area2D) -> void:
    if dead or _evolution_pending or !can_pick_up_materials or !(area is Gold): return

    var gold: Gold = area
    var charmed_by: int = get_charmed_by_player_index()

    if charmed_by != -1:
        gold.pickup(charmed_by)
        _count_material_for_evolution()
        return

    gold.pickup(-1)
    var gold_value: int = gold.value + 1 if RunData.bonus_gold > 0 else gold.value
    RunData.add_bonus_gold(gold_value, false)
    _count_material_for_evolution()

func fa_on_enemy_died(enemy: Enemy, _die_args: Entity.DieArgs) -> void:
    _disconnect_tracked_enemy(enemy)
    if dead or _evolution_pending or evolution_target_path == "" or white_list.has(enemy.enemy_id): return

    evolve_count += 1
    _queue_evolution_if_ready()

func fa_evolve() -> void:
    if dead or !_evolution_pending or evolution_target == null: return

    _is_evolving = true
    var charmed_by = get_charmed_by_player_index()

    emit_signal("wanted_to_spawn_an_enemy", evolution_target, global_position, self, charmed_by)

    var evolve_args: Entity.DieArgs = Entity.DieArgs.new()
    evolve_args.enemy_killed_by_player = false
    die(evolve_args)

func _queue_evolution_if_ready() -> void:
    if _evolution_pending or evolve_count < evovle_needed: return
    _evolution_pending = true
    call_deferred("fa_evolve")

func _count_material_for_evolution() -> void:
    if evolution_target == null: return
    evolve_count += 1
    _queue_evolution_if_ready()

func _disconnect_tracked_enemy(enemy: Enemy) -> void:
    _tracked_enemies.erase(enemy)
    if is_instance_valid(enemy) and enemy.is_connected("died", self, "fa_on_enemy_died"):
        enemy.disconnect("died", self, "fa_on_enemy_died")

func _disconnect_tracked_enemies() -> void:
    for enemy in _tracked_enemies.keys():
        _disconnect_tracked_enemy(enemy)
    _tracked_enemies.clear()
