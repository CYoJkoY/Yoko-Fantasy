extends Enemy

export(String, FILE, "*.tscn") var evolution_target_path = ""
var evolution_target: PackedScene = null
export(int) var kills_needed = 5
export(Array, String) var white_list = [
    "fantasy_little_slime", "fantasy_medium_slime",
    "fantasy_big_slime", "fantasy_slime_king"
]

var evovle_args: Entity.DieArgs = Utils.default_die_args
var main: Main = Utils.get_scene_node()

var kill_count: int = 0

# =========================== Extension =========================== #
func _ready() -> void:
    if evolution_target_path: evolution_target = load(evolution_target_path)

func respawn() -> void:
    .respawn()
    kill_count = 0

# =========================== Method =========================== #
func fa_on_DetectionArea_body_entered(body: Enemy) -> void:
    body.connect("died", self , "fa_on_enemy_died")

func fa_on_DetectionArea_body_exited(body: Enemy) -> void:
    body.disconnect("died", self , "fa_on_enemy_died")

func fa_on_ItemAttractArea_area_entered(item: Item) -> void:
    if dead: return

    var should_attract_item: bool = item is Gold
    if !should_attract_item: return

    var item_already_attracted_by_player: bool = item.attracted_by != null
    if item_already_attracted_by_player: return

    item.attracted_by = self

func fa_on_ItemPickUpArea_area_entered(area: Area2D) -> void:
    if dead or !(area is Gold) or !evolution_target_path: return

    var gold: Gold = area
    gold.pickup(-1)
    kill_count += 1
    if kill_count < kills_needed: return

    fa_evolve()

func fa_on_enemy_died(enemy: Enemy, _die_args: Entity.DieArgs) -> void:
    if dead or !evolution_target_path or white_list.has(enemy.enemy_id): return
    
    kill_count += 1
    if kill_count < kills_needed: return
    
    fa_evolve()

func fa_evolve() -> void:
    var charmed_by = get_charmed_by_player_index()

    emit_signal("wanted_to_spawn_an_enemy", evolution_target, global_position, self , charmed_by)
    
    die(evovle_args)
