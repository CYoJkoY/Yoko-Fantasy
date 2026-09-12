extends Effect

static func get_id() -> String:
    return "fantasy_curse_per_accuracy_loss"

func get_args(player_index: int) -> Array:
    var accuracy_text: String = tr("EFFECT_ACCURACY").format(["%"]).strip_edges()
    return ["-1", accuracy_text, str(value), tr("STAT_CURSE"), str(Utils.fa_get_curse_accuracy_loss(value, player_index))]
