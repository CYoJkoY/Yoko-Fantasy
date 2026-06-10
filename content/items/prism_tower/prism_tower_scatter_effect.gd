extends Effect

const ChainTargetService = preload("res://mods-unpacked/Yoko-Fantasy/extensions/services/chain_target_service.gd")

export(int) var base_chain_targets = 3
export(Array) var targets_scaling_stats = [["stat_fantasy_holy", 0.1]]
export(int) var max_chain_targets = 7

func duplicate(subresources: bool = false) -> Resource:
	var duplication = .duplicate(subresources)
	if !targets_scaling_stats.empty():
		targets_scaling_stats = Utils.convert_to_hash_array(targets_scaling_stats)
	duplication.targets_scaling_stats = targets_scaling_stats
	return duplication

func _generate_hashes() -> void:
	._generate_hashes()
	targets_scaling_stats = Utils.convert_to_hash_array(targets_scaling_stats)

func apply(_player_index: int) -> void:
	pass

func unapply(_player_index: int) -> void:
	pass

func get_args(player_index: int) -> Array:
	var targets_text: String = ChainTargetService.get_scaled_target_count_text(
		base_chain_targets,
		targets_scaling_stats,
		player_index,
		max_chain_targets
	)
	return [Text.text(
		"FANTASY_CHAIN_TARGETS_FORMATTED",
		[
			"[color=%s]%s[/color]" % [Utils.SECONDARY_FONT_COLOR_HTML, tr("FANTASY_SCATTER_TARGETS")],
			targets_text
		]
	)]

func serialize() -> Dictionary:
	var serialized = .serialize()
	serialized.base_chain_targets = base_chain_targets
	serialized.targets_scaling_stats = targets_scaling_stats
	serialized.max_chain_targets = max_chain_targets
	return serialized

func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)
	base_chain_targets = serialized.get("base_chain_targets", base_chain_targets) as int
	targets_scaling_stats = Utils.convert_to_hash_array(serialized.get("targets_scaling_stats", targets_scaling_stats))
	max_chain_targets = serialized.get("max_chain_targets", max_chain_targets) as int
