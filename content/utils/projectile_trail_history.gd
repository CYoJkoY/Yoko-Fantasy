extends Reference

var _positions: PoolVector2Array = PoolVector2Array()
var _head: int = 0
var count: int = 0


func _init(capacity: int = 128) -> void:
    _positions.resize(capacity)


func clear() -> void:
    _head = 0
    count = 0


func push(point: Vector2, min_distance_squared: float = 4.0) -> bool:
    if count > 0 and newest(0).distance_squared_to(point) < min_distance_squared:
        return false
    _head = (_head + _positions.size() - 1) % _positions.size()
    _positions[_head] = point
    count = int(min(count + 1, _positions.size()))
    return true


func newest(index: int) -> Vector2:
    return _positions[(_head + index) % _positions.size()]


func trim_oldest(amount: int) -> void:
    count = int(max(0, count - amount))


func sample(points: Array, spacing: float, world_to_local: Transform2D) -> float:
    if count == 0:
        return 0.0
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
