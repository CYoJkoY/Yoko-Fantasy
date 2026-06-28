class_name LightningChainDescriptionService
extends Reference

static func get_args(
	base_chance: float,
	base_damage: int,
	damage_scaling_stats: Array,
	base_chain_targets: int,
	targets_scaling_stats: Array,
	chain_damage_mult: float,
	arc_crit_chance: float,
	arc_crit_damage: float,
	arc_color: Color,
	player_index: int
) -> Array:
	var chain_damage_text: String = Utils.ncl_get_dmg_text_with_scaling_stats(
		base_damage,
		damage_scaling_stats,
		{
			"player_index": player_index
		}
	)

	var chain_targets_count_text: String = Utils.ncl_get_num_text_with_scaling_stats(
		base_chain_targets,
		targets_scaling_stats,
		{
			"player_index": player_index,
			"show_initial": false
		}
	)

	var chain_targets_text: String = Text.text(
		"FANTASY_CHAIN_TARGETS_FORMATTED",
		[
			"[color=%s]%s[/color]" % [Utils.SECONDARY_FONT_COLOR_HTML, TranslationServer.translate("FANTASY_CHAIN_TARGETS")],
			chain_targets_count_text
		]
	)

	var chain_damage_mult_text: String = ""
	if !is_equal_approx(chain_damage_mult, 1.0):
		chain_damage_mult_text = Text.text(
			"FANTASY_CHAIN_DAMAGE_MULT_FORMATTED",
			[
				"[color=%s]%s[/color]" % [Utils.SECONDARY_FONT_COLOR_HTML, TranslationServer.translate("FANTASY_CHAIN_DAMAGE_MULT")],
				"[color=%s]x%s[/color]" % ["white", str(chain_damage_mult)]
			]
		)

	var chain_crit_text: String = ""
	if arc_crit_chance > 0:
		chain_crit_text = Text.text(
			"CRITICAL_FORMATTED",
			[
				"[color=%s]%s[/color]" % [Utils.SECONDARY_FONT_COLOR_HTML, TranslationServer.translate("CRITICAL")],
				"[color=%s]x%s[/color]" % ["white", str(arc_crit_damage)],
				"[color=%s]%s[/color]" % ["white", str(max(arc_crit_chance * 100.0, 0))]
			]
		)

	return [
		str(int(base_chance * 100)),
		chain_damage_text,
		chain_targets_text,
		chain_damage_mult_text,
		chain_crit_text,
		arc_color.to_html()
	]
