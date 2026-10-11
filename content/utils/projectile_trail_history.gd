extends Reference

var _positions: PoolVector2Array = PoolVector2Array()
var _head: int = 0
var count: int = 0
var _distances: Array = []
var _travel: float = 0.0


func _init(capacity: int = 128, cache_distances: bool = false) -> void:
    _positions.resize(capacity)
    if cache_distances:
        _distances.resize(capacity)


func clear() -> void:
    _head = 0
    count = 0
    _travel = 0.0


func push(point: Vector2, min_distance_squared: float = 4.0) -> bool:
    if count > 0:
        var distance_squared: float = _positions[_head].distance_squared_to(point)
        if distance_squared < min_distance_squared:
            return false
        if not _distances.empty():
            _travel += sqrt(distance_squared)
    _head = (_head + _positions.size() - 1) % _positions.size()
    _positions[_head] = point
    if not _distances.empty():
        _distances[_head] = _travel
    count = int(min(count + 1, _positions.size()))
    return true


func newest(index: int) -> Vector2:
    return _positions[(_head + index) % _positions.size()]


func trim_oldest(amount: int) -> void:
    count = int(max(0, count - amount))


func sample(points: Array, spacing: float, world_to_local: Transform2D) -> float:
    if count == 0:
        return 0.0
    if not _distances.empty():
        return _sample_cached(points, spacing, world_to_local)
    var segment: int = 1
    var previous_distance: float = 0.0
    var current_distance: float = newest(0).distance_to(newest(1)) if count > 1 else 0.0
    for i in range(points.size()):
        var distance: float = float(i) * spacing
        while segment < count - 1 and current_distance < distance:
            segment += 1
            previous_distance = current_distance
            current_distance += newest(segment - 1).distance_to(newest(segment))
        var point: Vector2 = newest(0)
        if count > 1:
            var weight: float = clamp((distance - previous_distance) / max(0.0001, current_distance - previous_distance), 0.0, 1.0)
            point = newest(segment - 1).linear_interpolate(newest(segment), weight)
        points[i] = world_to_local.xform(point)
    if segment < count - 1:
        count = segment + 1
    return current_distance


func _sample_cached(points: Array, spacing: float, world_to_local: Transform2D) -> float:
    var capacity: int = _positions.size()
    var segment: int = 1
    var newer: int = _head
    var older: int = (_head + 1) % capacity if count > 1 else _head
    var previous_distance: float = 0.0
    var current_distance: float = _travel - _distances[older]
    for i in range(points.size()):
        var distance: float = float(i) * spacing
        while segment < count - 1 and current_distance < distance:
            segment += 1
            newer = older
            older = (older + 1) % capacity
            previous_distance = current_distance
            current_distance = _travel - _distances[older]
        var weight: float = clamp((distance - previous_distance) / max(0.0001, current_distance - previous_distance), 0.0, 1.0)
        points[i] = world_to_local.xform(_positions[newer].linear_interpolate(_positions[older], weight))
    if segment < count - 1:
        count = segment + 1
    return current_distance
