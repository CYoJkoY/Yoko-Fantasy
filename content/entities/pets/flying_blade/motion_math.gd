extends Reference

static func bezier2(a: Vector2, b: Vector2, c: Vector2, t: float) -> Vector2:
    var inv: float = 1.0 - t
    return a * inv * inv + b * 2.0 * inv * t + c * t * t

static func bezier2_tangent(a: Vector2, b: Vector2, c: Vector2, t: float) -> Vector2:
    return (b - a) * 2.0 * (1.0 - t) + (c - b) * 2.0 * t

static func ease_out_cubic(t: float) -> float:
    var inv: float = 1.0 - t
    return 1.0 - inv * inv * inv

static func ease_in_out_cubic(t: float) -> float:
    t = clamp(t, 0.0, 1.0)
    if t < 0.5:
        return 4.0 * t * t * t
    var inv: float = -2.0 * t + 2.0
    return 1.0 - inv * inv * inv * 0.5

static func clamp_to_zone(position: Vector2) -> Vector2:
    var zone_rect: Rect2 = ZoneService.get_current_zone_rect()
    position.x = clamp(position.x, zone_rect.position.x, zone_rect.end.x)
    position.y = clamp(position.y, zone_rect.position.y, zone_rect.end.y)
    return position

static func to_local_direction(context: Node2D, direction: Vector2) -> Vector2:
    if direction.length_squared() <= 0.1:
        return Vector2.RIGHT
    var local_direction: Vector2 = context.to_local(context.global_position + direction) - context.to_local(context.global_position)
    if local_direction.length_squared() <= 0.1:
        return Vector2.RIGHT
    return local_direction.normalized()
