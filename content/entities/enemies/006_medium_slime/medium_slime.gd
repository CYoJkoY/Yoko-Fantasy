extends "res://mods-unpacked/Yoko-Fantasy/content/entities/enemies/001_little_slime/little_slime.gd"

export(PackedScene) var die_to_spawn
export(int) var nb_spawns_on_death = 4

# =========================== Extension =========================== #
func die(args := Entity.DieArgs.new()) -> void:
    .die(args)

    if args.cleaning_up: return

    var charmed_by = get_charmed_by_player_index()
    var nb_to_spawn: int = nb_spawns_on_death

    for i in nb_to_spawn:
        emit_signal("wanted_to_spawn_an_enemy", die_to_spawn, ZoneService.get_rand_pos_in_area(Vector2(global_position.x, global_position.y), 100), self , charmed_by)
