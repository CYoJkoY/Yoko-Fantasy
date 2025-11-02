extends "res://mods-unpacked/Yoko-Fantasy/content/enemies/001_little_slime/scene/little_slime.gd"

export (PackedScene) var die_to_spawn

export (int) var nb_spawns_on_death = 4

func die(args: = Entity.DieArgs.new())->void :
	.die(args)

	if args.cleaning_up:
		return 

	var charmed_by = get_charmed_by_player_index()
	var nb_to_spawn: int = nb_spawns_on_death
	var nb_of_enemies_stat: int = RunData.sum_all_player_effects("number_of_enemies")

	if nb_of_enemies_stat < 0:
		var nb_to_remove: int = nb_of_enemies_stat / - 20
		nb_to_spawn = int(max(nb_to_spawn, nb_to_spawn - nb_to_remove))

	for i in nb_to_spawn:
		emit_signal("wanted_to_spawn_an_enemy", die_to_spawn, ZoneService.get_rand_pos_in_area(Vector2(global_position.x, global_position.y), 100), self, charmed_by)
