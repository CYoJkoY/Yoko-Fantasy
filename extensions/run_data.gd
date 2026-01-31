extends "res://singletons/run_data.gd"

var fa_init_tracked_effects: Dictionary = {}

var fa_tracked_effects: Array= [{}, {}, {}, {}]

# =========================== Extension =========================== #
func reset(restart: bool = false)->void :
    .reset(restart)
    for player_index in fa_tracked_effects.size():
        fa_tracked_effects[player_index] = fa_init_tracking_effects()

func get_state()->Dictionary:
    var state: Dictionary = .get_state()
    state.fa_tracked_effects = fa_tracked_effects.duplicate(true)

    return state

func resume_from_state(state: Dictionary)->void :
    .resume_from_state(state)
    fa_tracked_effects = Utils.convert_to_hash_array(state.fa_tracked_effects.duplicate())

# =========================== Custom =========================== #

# =========================== Methods =========================== #
func fa_init_tracking_effects()->Dictionary:
    return fa_init_tracked_effects.duplicate(true)

func fa_add_effect_tracking_value(fa_tracking_key_hash: int, value: float, player_index: int, index: int = 0) -> void:
    if !fa_tracked_effects[player_index].has(fa_tracking_key_hash):
        print("fa tracking key %s does not exist" % fa_tracking_key_hash)
        return

    if fa_tracked_effects[player_index][fa_tracking_key_hash] is Array:
        fa_tracked_effects[player_index][fa_tracking_key_hash][index] += value as int
    else: 
        fa_tracked_effects[player_index][fa_tracking_key_hash] += value as int

func fa_set_effect_tracking_value(fa_tracking_key_hash: int, value: float, player_index: int, index: int = 0) -> void :
    if !fa_tracked_effects[player_index].has(fa_tracking_key_hash):
        print("fa tracking key %s does not exist" % fa_tracking_key_hash)
        return

    if fa_tracked_effects[player_index][fa_tracking_key_hash] is Array:
        fa_tracked_effects[player_index][fa_tracking_key_hash][index] = value as int
    else: 
        fa_tracked_effects[player_index][fa_tracking_key_hash] = value as int

func fa_get_effect_tracking_value(fa_tracking_key_hash: int, player_index: int, index: int = 0) -> float:
    if !fa_tracked_effects[player_index].has(fa_tracking_key_hash):
        print("fa tracking key %s does not exist" % fa_tracking_key_hash)
        return 0.0
    
    if fa_tracked_effects[player_index][fa_tracking_key_hash] is Array:
        return fa_tracked_effects[player_index][fa_tracking_key_hash][index]
    else:
        return fa_tracked_effects[player_index][fa_tracking_key_hash]
