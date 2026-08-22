class_name ChainTargetService
extends Reference

static func get_scaled_target_count(
	base_targets: int,
	targets_scaling_stats: Array,
	player_index: int,
	max_targets: int = -1
) -> int:
	var target_count: int = Utils.ncl_get_num_with_scaling_stats(base_targets, targets_scaling_stats, player_index)
	if max_targets > 0:
		target_count = int(min(target_count, max_targets))
	return int(max(1, target_count))

static func get_scaled_target_count_text(
	base_targets: int,
	targets_scaling_stats: Array,
	player_index: int,
	max_targets: int = -1
) -> String:
	var target_count: int = get_scaled_target_count(base_targets, targets_scaling_stats, player_index, max_targets)
	var color: String = Utils.ncl_get_signed_col(target_count, base_targets)
	return "[color=%s]%s[/color] (%s)" % [
		color,
		str(target_count),
		WeaponService.get_scaling_stats_icon_text(targets_scaling_stats)
	]

static func collect_nearby_enemies(
	main: Main,
	center: Vector2,
	excluded: Array,
	radius: float,
	max_count: int
) -> Array:
	var result: Array = []
	if main == null or main._entity_spawner == null:
		return result

	var candidates: Array = main._entity_spawner.get_all_enemies(false)
	var excluded_ids: Dictionary = {}
	var selected_ids: Dictionary = {}
	var radius_squared: float = radius * radius
	for enemy in excluded:
		if is_instance_valid(enemy):
			excluded_ids[enemy.get_instance_id()] = true

	for _i in range(max_count):
		var best: Node = null
		var best_dist_squared: float = radius_squared
		for enemy in candidates:
			if !_is_valid_enemy(enemy):
				continue
			var enemy_id: int = enemy.get_instance_id()
			if excluded_ids.has(enemy_id) or selected_ids.has(enemy_id):
				continue
			var dist_squared: float = enemy.global_position.distance_squared_to(center)
			if dist_squared <= best_dist_squared:
				best = enemy
				best_dist_squared = dist_squared
		if best == null:
			break
		result.push_back(best)
		selected_ids[best.get_instance_id()] = true

	return result

static func _is_valid_enemy(node: Node) -> bool:
	return is_instance_valid(node) and node is Enemy and !node.dead
