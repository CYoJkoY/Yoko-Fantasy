extends Reference

static func build_params_from_effect(
	effect: Effect,
	player_index: int
) -> Dictionary:
	var damage: int = Utils.ncl_get_dmg_with_scaling_stats(effect.value, effect.damage_scaling_stats, player_index)
	var chain_targets: int = Utils.ncl_get_dmg_with_scaling_stats(effect.base_chain_targets, effect.targets_scaling_stats, player_index)

	return {
		"damage": damage,
		"chain_targets": chain_targets,
		"chain_damage_mult": effect.chain_damage_mult,
		"arc_width": effect.arc_width,
		"arc_jaggedness": effect.arc_jaggedness,
		"arc_color": effect.arc_color,
		"arc_glow_color": effect.arc_glow_color,
		"arc_duration": effect.arc_duration,
		"arc_crit_chance": effect.arc_crit_chance,
		"arc_crit_damage": effect.arc_crit_damage,
		"damage_scaling_stats": effect.damage_scaling_stats,
		"arc_scene_path": effect.arc_scene.resource_path
	}

static func build_params_from_array(
	effect_item: Array,
	player_index: int
) -> Dictionary:
	var damage_scaling_stats: Array = effect_item[2]
	var targets_scaling_stats: Array = effect_item[4]
	var base_damage: int = effect_item[1]
	var base_chain_targets: int = effect_item[3]

	return {
		"damage": Utils.ncl_get_dmg_with_scaling_stats(base_damage, damage_scaling_stats, player_index),
		"chain_targets": Utils.ncl_get_dmg_with_scaling_stats(base_chain_targets, targets_scaling_stats, player_index),
		"chain_damage_mult": effect_item[5],
		"arc_width": effect_item[6],
		"arc_jaggedness": effect_item[7],
		"arc_color": Color(effect_item[8]),
		"arc_glow_color": Color(effect_item[9]),
		"arc_duration": effect_item[10],
		"arc_crit_chance": effect_item[11],
		"arc_crit_damage": effect_item[12],
		"damage_scaling_stats": damage_scaling_stats,
		"arc_scene_path": effect_item[13]
	}

static func collect_triggered_hit_params(
	effects: Array,
	effect_items: Array,
	player_index: int
) -> Array:
	var params_list: Array = []

	for effect in effects:
		if effect.get_id() != "fantasy_lightning_chain_on_hit":
			continue
		if !Utils.get_chance_success(effect.base_chance):
			continue

		params_list.push_back(build_params_from_effect(effect, player_index))

	for effect_item in effect_items:
		var chance: float = effect_item[0]
		if !Utils.get_chance_success(chance):
			continue

		params_list.push_back(build_params_from_array(effect_item, player_index))

	return params_list

static func spawn_lightning_chain(
	main: Main,
	first_target: Enemy,
	player_index: int,
	damage: int,
	chain_targets: int,
	chain_damage_mult: float,
	arc_width: float,
	arc_jaggedness: float,
	arc_color: Color,
	arc_glow_color: Color,
	arc_duration: float,
	arc_crit_chance: float,
	arc_crit_damage: float,
	parent_effects: Array,
	damage_scaling_stats: Array,
	arc_scene_path: String
) -> int:
	if main == null or !is_instance_valid(first_target):
		return 0

	var arc_pool_id: int = Keys.generate_hash(arc_scene_path)
	var arc: Node = main.get_node_from_pool(arc_pool_id, main._effects)

	if !is_instance_valid(arc):
		arc = load(arc_scene_path).instance()
		main.add_effect(arc)
		arc.set_meta("pool_id", arc_pool_id)

	var chain_enemies: Array = [first_target]
	var all_enemies: Array = main._entity_spawner.get_all_enemies(false)
	var available: Array = all_enemies.duplicate()
	available.erase(first_target)

	var current_pos: Vector2 = first_target.global_position
	for _i in range(chain_targets):
		var next_target = Utils.get_nearest_no_max_no_dist(available, current_pos)
		if next_target == null or !is_instance_valid(next_target) or next_target.dead:
			break

		chain_enemies.append(next_target)
		current_pos = next_target.global_position
		available.erase(next_target)

	return arc.link(
		chain_enemies,
		damage,
		chain_damage_mult,
		player_index,
		arc_width,
		arc_jaggedness,
		arc_color,
		arc_glow_color,
		arc_duration,
		arc_crit_chance,
		arc_crit_damage,
		parent_effects,
		damage_scaling_stats
	)
