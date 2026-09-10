extends ProjectileEffect

export(bool) var target_highest_health = false

static func get_id() -> String:
    return "fantasy_projectile_on_enemy_death"

func apply(player_index: int) -> void:
    RunData.get_player_effect(key_hash, player_index).append(self)

func unapply(player_index: int) -> void:
    var effect_items: Array = RunData.get_player_effect(key_hash, player_index)
    var serialized: Dictionary = serialize()
    for effect in effect_items:
        if effect.serialize() == serialized:
            effect_items.erase(effect)
            return

func get_args(player_index: int) -> Array:
    var damage_text: String = Utils.ncl_get_dmg_text_with_scaling_stats(
        weapon_stats.damage, weapon_stats.scaling_stats, {"player_index": player_index}
    )
    return [str(value), damage_text]

func serialize() -> Dictionary:
    var serialized: Dictionary = .serialize()
    serialized.target_highest_health = target_highest_health
    return serialized

func deserialize_and_merge(serialized: Dictionary) -> void:
    .deserialize_and_merge(serialized)
    target_highest_health = serialized.target_highest_health
