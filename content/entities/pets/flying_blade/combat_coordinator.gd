extends Reference
# Combat Coordinator — one per player (stored on the player node via metadata
# by the owning pet). Maintains a cached enemy target list, schedules
# main-blade and satellite attacks through per-role queues with active-slot
# limits, and assigns formation indices so satellites distribute evenly.

const ROLE_MAIN := "main"
const ROLE_SATELLITE := "satellite"

var player_index: int = -1
var players_ref: Array = []
var _target_cache: Array = []
var _sensor_radius: float = 200.0
var _main_queue: Array = []
var _satellite_queue: Array = []
var _active_main: Dictionary = {}
var _active_satellite: Dictionary = {}
var _max_main: int = 0
var _max_satellite: int = 0
var _max_dispatches: int = 2
var _satellites: Array = []

func setup(p_player_index: int, p_players_ref: Array, radius: float) -> void:
    player_index = p_player_index
    players_ref = p_players_ref
    _sensor_radius = max(radius, 96.0)

func configure_attack_limits(max_main: int, max_satellite: int, dispatches: int) -> void:
    _max_main = max(0, max_main) as int
    _max_satellite = max(0, max_satellite) as int
    _max_dispatches = max(1, dispatches) as int

func request_sensor_radius(radius: float) -> void:
    _sensor_radius = max(_sensor_radius, radius)

func refresh_targets() -> void:
    var root = Engine.get_main_loop().get_root()
    if not root:
        return
    var space: Physics2DDirectSpaceState = root.get_world_2d().direct_space_state
    var shape := CircleShape2D.new()
    shape.radius = _sensor_radius
    var query := Physics2DShapeQueryParameters.new()
    query.set_shape(shape)
    query.transform = Transform2D(0, _get_player_position())
    query.collision_layer = Utils.ENEMIES_BIT
    var results := space.intersect_shape(query)
    _target_cache.clear()
    for res in results:
        var body = res.collider
        if is_instance_valid(body) and not body.dead:
            _target_cache.append(body)

func get_targets() -> Array:
    return _target_cache

func enqueue_attack(actor: Node, role: String) -> bool:
    if not is_instance_valid(actor):
        return false
    var active := _get_active(role)
    var actor_id := actor.get_instance_id()
    if active.has(actor_id):
        return true
    _get_queue(role).push_back(actor)
    return true

func release_attack(actor: Node, role: String) -> void:
    _get_active(role).erase(actor.get_instance_id())

func dispatch_attacks() -> void:
    for _i in range(_max_dispatches):
        if not (_dispatch_role(ROLE_MAIN) or _dispatch_role(ROLE_SATELLITE)):
            break

func _dispatch_role(role: String) -> bool:
    var active := _get_active(role)
    if active.size() >= _get_limit(role):
        return false
    var queue := _get_queue(role)
    while not queue.empty():
        var actor = queue.pop_front()
        if not is_instance_valid(actor):
            continue
        var target = actor.get_coordinated_attack_target()
        if not is_instance_valid(target) or target.dead:
            actor.coordinated_attack_failed()
            continue
        active[actor.get_instance_id()] = actor
        actor.begin_coordinated_attack(target)
        return true
    return false

func get_next_cooldown(base_ticks: float, role: String) -> float:
    var count := _satellite_queue.size() if role == ROLE_SATELLITE else _main_queue.size()
    count = clamp(count, 1, 6) as int
    if role == ROLE_SATELLITE:
        return base_ticks * rand_range(0.8, 1.2)
    var max_rand := min(count * base_ticks / 5.0, count * 5.0)
    return rand_range(max(1.0, base_ticks - max_rand), base_ticks + max_rand)

func get_orbit_phase(orbit_speed: float) -> float:
    return (OS.get_ticks_msec() / 1000.0) * orbit_speed * 0.72

func register_satellite(satellite: Node2D) -> void:
    if is_instance_valid(satellite) and not _satellites.has(satellite):
        _satellites.append(satellite)
        _refresh_formations()

func unregister_satellite(satellite: Node2D) -> void:
    var idx := _satellites.find(satellite)
    if idx >= 0:
        _satellites.remove(idx)
        _refresh_formations()

func get_satellites() -> Array:
    var valid: Array = []
    for s in _satellites:
        if is_instance_valid(s):
            valid.append(s)
    return valid

func _refresh_formations() -> void:
    var clean: Array = []
    for s in _satellites:
        if is_instance_valid(s):
            clean.append(s)
    _satellites = clean
    var count := _satellites.size()
    for i in range(count):
        _satellites[i].set_formation(i, count)

func _get_queue(role: String) -> Array:
    return _satellite_queue if role == ROLE_SATELLITE else _main_queue

func _get_active(role: String) -> Dictionary:
    return _active_satellite if role == ROLE_SATELLITE else _active_main

func _get_limit(role: String) -> int:
    var limit := _max_satellite if role == ROLE_SATELLITE else _max_main
    return 9999 if limit <= 0 else limit

func _get_player_position() -> Vector2:
    if player_index >= 0 and player_index < players_ref.size() and is_instance_valid(players_ref[player_index]):
        return players_ref[player_index].global_position
    return Vector2.ZERO
