extends Reference
# Combat Coordinator — optimized version with weak references and signal-based lifecycle.

const ROLE_MAIN := "main"
const ROLE_SATELLITE := "satellite"

var player_index: int = -1
var players_ref: Array = []

# 使用 WeakRef 存储敌人，防止因强引用导致敌人节点无法被GC回收
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
    if not root: return
    
    var space: Physics2DDirectSpaceState = root.get_world_2d().direct_space_state
    var shape := CircleShape2D.new()
    shape.radius = _sensor_radius
    var query := Physics2DShapeQueryParameters.new()
    query.set_shape(shape)
    query.transform = Transform2D(0, _get_player_position())
    query.collision_layer = Utils.ENEMIES_BIT
    
    var results := space.intersect_shape(query)
    
    # 清空旧缓存
    _target_cache.clear()
    
    # 仅存储弱引用，不持有强引用
    for res in results:
        var body = res.collider
        if body: # 基础非空检查
            _target_cache.append(weakref(body))

func get_targets() -> Array:
    # 返回有效目标的实时列表，移除已死亡的弱引用
    var valid_targets: Array = []
    for wr in _target_cache:
        var ref = wr.get_ref()
        # 只有当引用有效且目标未死亡时才返回
        if ref and not ref.dead:
            valid_targets.append(ref)
    return valid_targets

func enqueue_attack(actor: Node, role: String) -> bool:
    # 假设调用者保证了 actor 的即时有效性，减少防御性检查
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
        # 简单的健壮性检查，如果 actor 已经 free，跳过即可
        if not is_instance_valid(actor):
            continue
            
        var target = actor.get_coordinated_attack_target()
        if not target or target.dead: # target 现在是强引用或有效对象，直接检查 dead
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
    if not _satellites.has(satellite):
        _satellites.append(satellite)
        # 关键重构：使用信号自动清理，避免轮询检查 is_instance_valid
        if not satellite.is_connected("tree_exiting", self, "_on_satellite_exiting"):
            satellite.connect("tree_exiting", self, "_on_satellite_exiting", [satellite], CONNECT_ONESHOT)
        _refresh_formations()

func unregister_satellite(satellite: Node2D) -> void:
    var idx := _satellites.find(satellite)
    if idx >= 0:
        _satellites.remove(idx)
        # 清理队列中可能存在的该卫星引用
        _satellite_queue.erase(satellite)
        _refresh_formations()

func _on_satellite_exiting(satellite: Node2D) -> void:
    # 信号回调：卫星正在被移除，执行注销逻辑
    unregister_satellite(satellite)

func get_satellites() -> Array:
    # 过滤列表，虽然理论上 tree_exiting 会处理，但以防万一做一次安全清理
    var clean_satellites = []
    for s in _satellites:
        if is_instance_valid(s):
            clean_satellites.append(s)
    if clean_satellites.size() != _satellites.size():
        _satellites = clean_satellites
        _refresh_formations()
    return _satellites

func _refresh_formations() -> void:
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
