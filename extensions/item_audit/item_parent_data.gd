extends "res://items/global/item_parent_data.gd"

func deserialize_and_merge(serialized: Dictionary) -> void:
    if serialized.get("my_id", "") == "item_fantasy_prism_tower":
        # Migrate old saves without modifying their input dictionary.
        serialized = serialized.duplicate(true)
        var ids = {
            "FANTASY_PRISM_TOWER_MAIN": "fantasy_prism_tower",
            "EFFECT_FANTASY_PRISM_TOWER_SCATTER": "fantasy_prism_scatter",
            "FANTASY_PRISM_TOWER_RESONANCE": "fantasy_prism_resonance"
        }
        for effect in serialized.get("effects", []):
            var text = effect.get("text_key", "")
            if ids.has(text) and effect.get("effect_id", "") in ["effect", "turret"]:
                effect.effect_id = ids[text]
    .deserialize_and_merge(serialized)
