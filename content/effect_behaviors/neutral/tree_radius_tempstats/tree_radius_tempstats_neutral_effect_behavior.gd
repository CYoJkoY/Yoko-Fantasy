extends UnitEffectBehavior

var tempstats: Array = []
var radius: int = 0
var range_rate: float = 0.0
var player_indexes: Array = []

onready var collision: CollisionShape2D = $"%Collision"

# =========================== Extension =========================== #
func init(tree: Unit, stat: int, stat_num: int, _radius: int, _range_rate: float, player_index: int) -> UnitEffectBehavior:
    _parent = tree
    tempstats.append([stat, stat_num])
    radius = _radius
    range_rate = _range_rate
    player_indexes.append(player_index)
    return self

func _ready() -> void:
    fa_update_collision_radius()

func get_bonus_damage(_hitbox: Hitbox, _from_player_index: int) -> int:
    return 0

func on_burned(_burning_data: BurningData, _from_player_index: int) -> void:
	pass

func update_target() -> void:
	pass

# =========================== Method =========================== #
func fa_add_temp_stat(stat: int, stat_num: int, player_index: int) -> void:
    tempstats.append([stat, stat_num])
    player_indexes.append(player_index)

func fa_update_collision_radius() -> void:
    var total_radius: int = 0
    for player_index in player_indexes: total_radius += Utils.ncl_get_range_with_detection(radius, range_rate, player_index)
    collision.shape.radius = total_radius / player_indexes.size()

func fa_on_Range_body_entered(body: Node) -> void:
    var player_index: int = body.player_index

    if !player_indexes.has(player_index): return

    for tempstat in tempstats:
        var stat: int = tempstat[0]
        var stat_num: int = tempstat[1]
        TempStats.add_stat(stat, stat_num, player_index)

func fa_on_Range_body_exited(body: Node) -> void:
    var player_index: int = body.player_index

    if !player_indexes.has(player_index): return

    # Check dead to avoid excessive reduction from cleanup;
    # Check _pending_die to ensure proper handling when the tree dies
    if _parent.dead and !_parent._pending_die: return

    for tempstat in tempstats:
        var stat: int = tempstat[0]
        var stat_num: int = tempstat[1]
        TempStats.remove_stat(stat, stat_num, player_index)
