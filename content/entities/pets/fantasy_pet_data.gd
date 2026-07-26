extends "res://entities/units/pet/ItemPet.gd"

export(Array, String) var fantasy_affected_player_stats: Array = []
export(Dictionary) var fantasy_affected_player_stat_scopes: Dictionary = {}


func get_fantasy_behaviour_description() -> String:
    var description: String = Text.text(behaviour_description)
    if fantasy_affected_player_stats.empty():
        return description

    var lines: Array = [description, "", Text.text("FANTASY_PET_AFFECTED_PLAYER_STATS")]
    for stat_id in fantasy_affected_player_stats:
        var stat_name: String = tr(stat_id.to_upper()).replace("{0}", "").strip_edges()
        var stat_line: String = "- " + stat_name
        if fantasy_affected_player_stat_scopes.has(stat_id):
            stat_line += " " + Text.text(fantasy_affected_player_stat_scopes[stat_id])
        lines.push_back(stat_line)

    return PoolStringArray(lines).join("\n")
