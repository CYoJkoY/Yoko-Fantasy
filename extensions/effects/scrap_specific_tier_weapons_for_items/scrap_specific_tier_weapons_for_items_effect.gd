extends DoubleValueEffect

enum WeaponTier {I, II, III, IV}

export(WeaponTier) var tier = WeaponTier.I

# =========================== Extension =========================== #
static func get_id() -> String:
    return "fantasy_scrap_weapons_for_items"

func apply(player_index: int) -> void:
    if custom_key == "": return

    var effects = RunData.get_player_effects(player_index)
    effects[custom_key_hash][tier].append([value, value2, key_hash])

func unapply(player_index: int) -> void:
    if custom_key == "": return

    var effects = RunData.get_player_effects(player_index)
    effects[custom_key_hash][tier].erase([value, value2, key_hash])

func get_args(_player_index: int) -> Array:
    var tier_text = "TIER_I"
    if tier == 1: tier_text = "TIER_II"
    elif tier == 2: tier_text = "TIER_III"
    elif tier == 3: tier_text = "TIER_IV"

    return [tr(tier_text), str(value), str(value2), tr(key.to_upper())]

func serialize() -> Dictionary:
    var serialized =.serialize()
    serialized.tier = tier

    return serialized

func deserialize_and_merge(serialized: Dictionary) -> void:
    .deserialize_and_merge(serialized)
    tier = serialized.tier as int
