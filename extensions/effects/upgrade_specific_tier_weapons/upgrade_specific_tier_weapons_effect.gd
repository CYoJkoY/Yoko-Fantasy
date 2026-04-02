extends Effect

enum Tier {COMMON, UNCOMMON, RARE, LEGENDARY, DANGER_4, DANGER_5}

export(Tier) var tier = Tier.COMMON

# =========================== Extension =========================== #
static func get_id() -> String:
    return "fantasy_upgrade_specific_tier_weapons"

func apply(player_index: int) -> void:
    if key_hash == Keys.empty_hash: return

    var effects: Dictionary = RunData.get_player_effects(player_index)
    var effect_items: Array = effects[key_hash]
    for existing_item in effect_items:
        if existing_item[0] == tier:
            existing_item[1] += value
            return

    effect_items.append([tier, value])

func unapply(player_index: int) -> void:
    if key_hash == Keys.empty_hash: return

    var effects: Dictionary = RunData.get_player_effects(player_index)
    var effect_items: Array = effects[key_hash]
    for i in range(effect_items.size()):
        var existing_item: Array = effect_items[i]
        if existing_item[0] == tier:
            existing_item[1] -= value
            if existing_item[1] == 0: effect_items.remove(i)
            return

func get_args(_player_index: int) -> Array:
    var tier_text = "TIER_I"
    if tier == 1: tier_text = "TIER_II"
    elif tier == 2: tier_text = "TIER_III"
    elif tier == 3: tier_text = "TIER_IV"

    return [str(value), tr(tier_text)]

func serialize() -> Dictionary:
    var serialized: Dictionary =.serialize()
    serialized.tier = tier
    
    return serialized

func deserialize_and_merge(serialized: Dictionary) -> void:
    .deserialize_and_merge(serialized)
    tier = serialized.tier as int
