extends DoubleKeyValueEffect

enum EnemyFutureStats {
    HP = 0,
    SPEED = 1,
    DAMAGE = 2,
    ARMOR = 3
}

export(String) var trigger_enemy_name = ""
export(String) var future_target_enemy_name = ""
var future_target_enemy_name_hash: int = Keys.empty_hash
export(EnemyFutureStats) var future_stat = EnemyFutureStats.HP

# =========================== Extension =========================== #
func duplicate(subresources := false) -> Resource:
    var duplication =.duplicate(subresources)
    if future_target_enemy_name_hash == Keys.empty_hash and future_target_enemy_name != "":
        future_target_enemy_name_hash = Keys.generate_hash(future_target_enemy_name)
    
    duplication.future_target_enemy_name_hash = future_target_enemy_name_hash

    return duplication

static func get_id() -> String:
    return "fantasy_on_target_enemy_killed_buff_future_target_enemy"

func _generate_hashes() -> void:
    ._generate_hashes()
    future_target_enemy_name_hash = Keys.generate_hash(future_target_enemy_name)

func apply(player_index: int) -> void:
    if custom_key == "": return

    var effects: Dictionary = RunData.get_player_effects(player_index)
    effects[custom_key_hash].append([key_hash, key2_hash, value, future_stat, value2, future_target_enemy_name_hash])

func unapply(player_index: int) -> void:
    if custom_key == "": return

    var effects: Dictionary = RunData.get_player_effects(player_index)
    effects[custom_key_hash].erase([key_hash, key2_hash, value, future_stat, value2, future_target_enemy_name_hash])

func get_args(_player_index: int) -> Array:
    var str_future_stat: String = ""
    match future_stat:
        Utils.FANTASY_ENEMY_HP: str_future_stat = tr("STAT_MAX_HP")
        Utils.FANTASY_ENEMY_SPEED: str_future_stat = tr("STAT_SPEED").replace("%", "")
        Utils.FANTASY_ENEMY_DAMAGE: str_future_stat = tr("STAT_DAMAGE")
        Utils.FANTASY_ENEMY_ARMOR: str_future_stat = tr("STAT_ARMOR")

    return [tr(trigger_enemy_name), tr(future_target_enemy_name), str(value), str_future_stat, str(value2)]

func serialize() -> Dictionary:
    var serialized: Dictionary =.serialize()
    serialized.trigger_enemy_name = trigger_enemy_name
    serialized.future_target_enemy_name = future_target_enemy_name
    serialized.future_stat = future_stat
    return serialized

func deserialize_and_merge(serialized: Dictionary) -> void:
    .deserialize_and_merge(serialized)
    trigger_enemy_name = serialized.trigger_enemy_name as String
    future_target_enemy_name = serialized.future_target_enemy_name as String
    future_target_enemy_name_hash = Keys.generate_hash(future_target_enemy_name) as int
    future_stat = serialized.future_stat as int
