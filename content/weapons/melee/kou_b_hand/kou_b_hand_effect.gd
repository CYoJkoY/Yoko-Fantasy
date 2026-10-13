extends NullEffect

export(int) var impact_radius = 64
export(float) var self_loss_percent = 50.0
export(float) var boss_loss_percent = 10.0


static func get_id() -> String:
    return "fantasy_kou_b_hand"


func get_args(_player_index: int) -> Array:
    return [str(value), str(impact_radius), str(self_loss_percent)]


func serialize() -> Dictionary:
    var serialized: Dictionary = .serialize()
    serialized.impact_radius = impact_radius
    serialized.self_loss_percent = self_loss_percent
    serialized.boss_loss_percent = boss_loss_percent
    return serialized


func deserialize_and_merge(serialized: Dictionary) -> void:
    .deserialize_and_merge(serialized)
    impact_radius = serialized.impact_radius
    self_loss_percent = serialized.self_loss_percent
    boss_loss_percent = serialized.boss_loss_percent
