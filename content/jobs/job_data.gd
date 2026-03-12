extends UpgradeData

enum Stage {S1, S2}

export(Stage) var stage = Stage.S1

# =========================== Extension =========================== #
func serialize() -> Dictionary:
    var serialized =.serialize()
    serialized.upgrade_id = upgrade_id
    serialized.stage = stage

    return serialized

func deserialize_and_merge(serialized: Dictionary) -> void:
    .deserialize_and_merge(serialized)
    upgrade_id = serialized.upgrade_id as String
    upgrade_id_hash = Keys.generate_hash(serialized.upgrade_id) as int
    stage = serialized.stage as int
