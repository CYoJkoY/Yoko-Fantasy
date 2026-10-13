extends Node2D

const LIFETIME: float = 0.34
const DROPS: Array = [
    preload("res://particles/sprites/particle_11.png"),
    preload("res://particles/sprites/particle_10.png"),
    preload("res://particles/sprites/particle_9.png")
]
const MAX_DROPS: int = 3

var _elapsed: float = 0.0
var _main: Node
var _pool_id: int
var _count: int = 0
var _directions: PoolVector2Array = PoolVector2Array()
var _distances: PoolRealArray = PoolRealArray()
var _sizes: PoolRealArray = PoolRealArray()
var _birth_offsets: PoolVector2Array = PoolVector2Array()
var _durations: PoolRealArray = PoolRealArray()


func _ready() -> void:
    _directions.resize(MAX_DROPS)
    _distances.resize(MAX_DROPS)
    _sizes.resize(MAX_DROPS)
    _birth_offsets.resize(MAX_DROPS)
    _durations.resize(MAX_DROPS)
    set_process(false)


func play(source: Node, main: Node, pool_id: int, strength: float = 1.0) -> void:
    _main = main
    _pool_id = pool_id
    _elapsed = 0.0
    _count = 2 + randi() % 2
    var side: float = -1.0 if randf() < 0.5 else 1.0
    var sprite_rect: Rect2 = source.sprite.get_rect()
    var head_center: Vector2 = source.sprite.to_global(sprite_rect.position + sprite_rect.size * Vector2(0.5, 0.36))
    var head_half_width: float = sprite_rect.size.x * abs(source.sprite.global_scale.x) * 0.36
    global_position = head_center + Vector2(side * head_half_width, 0.0)
    var angle: float = -PI * 0.25 + rand_range(-0.10, 0.10)
    var companion_side: float = -1.0 if randf() < 0.5 else 1.0
    for i in range(_count):
        var spread: float = 0.0 if i == 0 else (-0.55 if i == 1 else 0.55)
        if _count == 2 and i == 1:
            spread *= companion_side
        spread += rand_range(-0.09, 0.09)
        var direction: Vector2 = Vector2.RIGHT.rotated(angle + spread)
        direction.x *= side
        _directions[i] = direction
        _birth_offsets[i] = Vector2(side * rand_range(0.0, 4.0), rand_range(-4.0, 5.0))
        _durations[i] = rand_range(0.25, 0.30)
        _distances[i] = (rand_range(23.0, 29.0) if i == 0 else rand_range(14.0, 21.0)) * strength
        _sizes[i] = (rand_range(1.10, 1.20) if i == 0 else rand_range(0.65, 0.73)) * strength
    set_process(true)
    update()


func _process(delta: float) -> void:
    _elapsed += delta
    if _elapsed >= LIFETIME:
        set_process(false)
        _main.add_node_to_pool(self, _pool_id)
        return
    update()


func _draw() -> void:
    for i in range(_count):
        var age: float = _elapsed - i * 0.018
        var duration: float = _durations[i]
        if age < 0.0 or age >= duration:
            continue
        var progress: float = age / duration
        var travel: float = 1.0 - pow(1.0 - progress, 2.5)
        var offset: Vector2 = _birth_offsets[i] + _directions[i] * (3.0 + _distances[i] * travel)
        offset.y += 3.0 * progress * progress
        var pop: float = smoothstep(0.0, 0.035, age)
        var size: Vector2 = Vector2(lerp(15.0, 12.5, travel), lerp(29.0, 21.0, travel)) * _sizes[i] * pop
        var alpha: float = 1.0 - smoothstep(0.52, 1.0, progress)
        draw_set_transform(offset, _directions[i].angle() - PI * 0.5, Vector2.ONE)
        draw_texture_rect(DROPS[i], Rect2(-size * 0.5, size), false, Color(0.48, 0.85, 1.0, alpha))
