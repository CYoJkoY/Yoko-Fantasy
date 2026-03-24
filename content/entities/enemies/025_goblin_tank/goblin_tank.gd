extends Boss

export(String, FILE, "*.tscn") var die_to_spawn_path = ""
var die_to_spawn: PackedScene = null
export(int) var nb_spawns_on_death = 9

# =========================== Extension =========================== #
func _ready() -> void:
    if die_to_spawn_path != "": die_to_spawn = load(die_to_spawn_path)

func die(args := Utils.default_die_args) -> void:
    .die(args)

    if args.cleaning_up or !die_to_spawn_path: return

    var charmed_by = get_charmed_by_player_index()
    var nb_to_spawn: int = nb_spawns_on_death

    for i in nb_to_spawn:
        emit_signal("wanted_to_spawn_an_enemy", die_to_spawn, ZoneService.get_rand_pos_in_area(Vector2(global_position.x, global_position.y), 100), self , charmed_by)

func on_state_changed(_new_state: int) -> void:
    .on_state_changed(_new_state)

    if _new_state == 0: current_stats.speed = 240
