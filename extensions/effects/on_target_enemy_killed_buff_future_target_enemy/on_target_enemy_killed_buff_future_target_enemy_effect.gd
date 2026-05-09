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
export(String) var tracking_key = ""
var tracking_key_hash: int = Keys.empty_hash

# =========================== Extension =========================== #
func duplicate(subresources := false) -> Resource:
    var duplication =.duplicate(subresources)
    
    if tracking_key_hash == Keys.empty_hash and tracking_key != "":
        tracking_key_hash = Keys.generate_hash(tracking_key)

    duplication.tracking_key_hash = tracking_key_hash

    return duplication

static func get_id() -> String:
    return "fantasy_on_target_enemy_killed_buff_future_target_enemy"

func _generate_hashes() -> void:
    ._generate_hashes()
    tracking_key_hash = Keys.generate_hash(tracking_key)

func apply(player_index: int) -> void:
    if custom_key == "": return

    var effects: Dictionary = RunData.get_player_effects(player_index)
    effects[custom_key_hash].append([key_hash, key2_hash, value, future_stat, value2, tracking_key_hash])

func unapply(player_index: int) -> void:
    if custom_key == "": return

    var effects: Dictionary = RunData.get_player_effects(player_index)
    effects[custom_key_hash].erase([key_hash, key2_hash, value, future_stat, value2, tracking_key_hash])

func get_args(_player_index: int) -> Array:
    var str_future_stat: String = ""
    match future_stat:
        Utils.FANTASY_ENEMY_HP: str_future_stat = tr("STAT_MAX_HP")
        Utils.FANTASY_ENEMY_SPEED: str_future_stat = tr("STAT_SPEED").replace("%", "")
        Utils.FANTASY_ENEMY_DAMAGE: str_future_stat = tr("STAT_DAMAGE")
        Utils.FANTASY_ENEMY_ARMOR: str_future_stat = tr("STAT_ARMOR")
    
    var tracking_value: int = RunData.ncl_get_effect_tracking_value(tracking_key_hash, _player_index)
    var tracking: String = Utils.ncl_create_tracking("STATS_GAINED", tracking_value)

    return [tr(trigger_enemy_name), tr(future_target_enemy_name), str(value), str_future_stat, str(value2), tracking]

func serialize() -> Dictionary:
    var serialized: Dictionary =.serialize()
    serialized.trigger_enemy_name = trigger_enemy_name
    serialized.future_target_enemy_name = future_target_enemy_name
    serialized.future_stat = future_stat
    serialized.tracking_key = tracking_key
    return serialized

func deserialize_and_merge(serialized: Dictionary) -> void:
    .deserialize_and_merge(serialized)
    trigger_enemy_name = serialized.trigger_enemy_name as String
    future_target_enemy_name = serialized.future_target_enemy_name as String
    future_stat = serialized.future_stat as int
    tracking_key = serialized.tracking_key as String
    tracking_key_hash = Keys.generate_hash(serialized.tracking_key)
