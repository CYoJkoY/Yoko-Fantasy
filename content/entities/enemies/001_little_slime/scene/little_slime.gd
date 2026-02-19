extends Enemy

export(String, FILE, "*.tscn") var evolution_target_path
export(int) var kills_needed = 5
export(float) var detection_radius = 200.0

onready var detection_area: Area2D = $DetectionArea
onready var detection_collision: CollisionShape2D = $DetectionArea/CollisionShape2D

var kill_count: int = 0
var evolution_target_scene: Resource = null
export(Array, String) var white_list = [
        "fantasy_little_slime", "fantasy_medium_slime",
        "fantasy_big_slime", "fantasy_slime_king"
    ]

# =========================== Extension =========================== #
func _ready() -> void:
    detection_collision.shape.radius = detection_radius
    detection_area.connect("body_entered", self , "fa_connect_to_enemy_death")
    detection_area.connect("body_exited", self , "fa_disconnect_from_enemy_death")
    
    # Avoid Cycle Load
    if evolution_target_path != "":
        evolution_target_scene = load(evolution_target_path)
    
func respawn() -> void:
    .respawn()
    kill_count = 0

# =========================== Method =========================== #
func fa_connect_to_enemy_death(body) -> void:
    if body != self and body.has_signal("died") and \
    not body.is_connected("died", self , "fa_on_enemy_died"):
        body.connect("died", self , "fa_on_enemy_died")

func fa_disconnect_from_enemy_death(body) -> void:
    if body != self and body.has_signal("died") and \
    body.is_connected("died", self , "fa_on_enemy_died"):
        body.disconnect("died", self , "fa_on_enemy_died")

func fa_on_enemy_died(entity: Entity, die_args: DieArgs) -> void:
    if die_args.cleaning_up or dead: return
    
    if entity.enemy_id in white_list: return
    
    kill_count += 1
    if kill_count < kills_needed: return
    
    fa_evolve()

func fa_evolve() -> void:
    if !evolution_target_scene: return

    var charmed_by = get_charmed_by_player_index()

    emit_signal("wanted_to_spawn_an_enemy", evolution_target_scene, global_position, self , charmed_by)
    
    die()
