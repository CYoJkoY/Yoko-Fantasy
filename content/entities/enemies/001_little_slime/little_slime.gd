extends Enemy

export(String, FILE, "*.tscn") var evolution_target_path
var evolution_target_scene: Resource = null
export(int) var kills_needed = 5
export(Array, String) var white_list = [
        "fantasy_little_slime", "fantasy_medium_slime",
        "fantasy_big_slime", "fantasy_slime_king"
    ]

var evovle_args: Entity.DieArgs = Utils.default_die_args

var kill_count: int = 0

# =========================== Extension =========================== #
func _ready() -> void:
    evovle_args.cleaning_up = true
    
    if evolution_target_path != "": evolution_target_scene = load(evolution_target_path) # Avoid Cycle Load
    
func respawn() -> void:
    .respawn()
    kill_count = 0

# =========================== Method =========================== #
func fa_on_DetectionArea_body_entered(body: Enemy) -> void:
    if !body.is_connected("died", self , "fa_on_enemy_died"):
        body.connect("died", self , "fa_on_enemy_died")

func fa_on_DetectionArea_body_exited(body: Enemy) -> void:
    if !body.is_connected("died", self , "fa_on_enemy_died"):
        body.disconnect("died", self , "fa_on_enemy_died")

func fa_on_ItemAttractArea_area_entered(item: Item) -> void:
    if dead: return

    var should_attract_item: bool = item is Gold
    if !should_attract_item: return

    var item_already_attracted_by_player: bool = item.attracted_by != null
    if item_already_attracted_by_player: return

    item.attracted_by = self

func _on_ItemPickUpArea_area_entered(area: Area2D) -> void:
    if dead: return

    if !(area is Gold): return

    var gold: Gold = area
    gold.pickup(-1)
    kill_count += 1
    if kill_count < kills_needed: return

    fa_evolve()

func fa_on_enemy_died(enemy: Enemy, die_args: DieArgs) -> void:
    if die_args.cleaning_up or dead: return
    
    if white_list.has(enemy.enemy_id): return
    
    kill_count += 1
    if kill_count < kills_needed: return
    
    fa_evolve()

func fa_evolve() -> void:
    if !evolution_target_scene: return

    var charmed_by = get_charmed_by_player_index()

    emit_signal("wanted_to_spawn_an_enemy", evolution_target_scene, global_position, self , charmed_by)
    
    die(evovle_args)
