extends Enemy

# =========================== Extension =========================== #
func die(args := Utils.default_die_args) -> void:
	.die(args)

	if args.enemy_killed_by_player and args.killed_by_player_index >= 0 and args.killed_by_player_index < players_ref.size() and is_instance_valid(players_ref[args.killed_by_player_index]):
		RunData.add_stat(Utils.stat_fantasy_holy_hash, 1, args.killed_by_player_index)
