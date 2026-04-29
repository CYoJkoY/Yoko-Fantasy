extends DoubleKeyValueEffect

enum EnemyFutureStats {
    HP = 0,
    SPEED = 1,
    DAMAGE = 2,
    ARMOR = 3
}

export(String) var trigger_enemy_name = ""
export(String) var future_target_enemy_name = ""
export(EnemyFutureStats) var future_stat = EnemyFutureStats.HP

# =========================== Extension =========================== #
static func get_id() -> String:
    return "fantasy_on_target_enemy_killed_buff_future_target_enemy"

func apply(player_index: int) -> void:
    if custom_key == "": return

    var effects: Dictionary = RunData.get_player_effects(player_index)
    effects[custom_key_hash].append([key_hash, key2_hash, value, future_stat, value2, future_target_enemy_name])

func unapply(player_index: int) -> void:
    if custom_key == "": return

    var effects: Dictionary = RunData.get_player_effects(player_index)
    effects[custom_key_hash].erase([key_hash, key2_hash, value, future_stat, value2, future_target_enemy_name])

func get_args(_player_index: int) -> Array:
    var str_future_stat: String = ""
    match future_stat:
        EnemyFutureStats.HP: str_future_stat = tr("STAT_MAX_HP")
        EnemyFutureStats.SPEED: str_future_stat = tr("STAT_SPEED").replace("%", "")
        EnemyFutureStats.DAMAGE: str_future_stat = tr("STAT_DAMAGE")
        EnemyFutureStats.ARMOR: str_future_stat = tr("STAT_ARMOR")
    
    return [tr(trigger_enemy_name), tr(future_target_enemy_name), str(value), str_future_stat, str(value2)]

func serialize() -> Dictionary:
    var serialized: Dictionary =.serialize()
    serialized.trigger_enemy_name = trigger_enemy_name
    serialized.future_target_enemy_name = future_target_enemy_name
    serialized.future_stat = future_stat
    return serialized

func deserialize_and_merge(serialized: Dictionary) -> void:
    .deserialize_and_merge(serialized)
    trigger_enemy_name = serialized.trigger_enemy_name
    future_target_enemy_name = serialized.future_target_enemy_name
    future_stat = serialized.future_stat
