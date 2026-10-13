extends Node2D

const HEARTS: Array = [
    preload("res://particles/sprites/particle_25.png"),
    preload("res://particles/sprites/particle_23.png"),
    preload("res://particles/sprites/particle_24.png")
]
const EMISSION_INTERVAL: float = 0.09
const HEART_LIFETIME: float = 0.68
const LIFETIME: float = HEART_LIFETIME + EMISSION_INTERVAL * 2.0

var _elapsed: float = 0.0
var _main: Node
var _pool_id: int
var _source: Node
var _head_position: Vector2
var _birth_positions: PoolVector2Array = PoolVector2Array()


func _ready() -> void:
    set_process(false)


func play(source: Node, main: Node, pool_id: int) -> void:
    _main = main
    _pool_id = pool_id
    _elapsed = 0.0
    _source = source
    _head_position = _get_head_position(source)
    global_position = _head_position
    _birth_positions.resize(0)
    _birth_positions.append(Vector2.ZERO)
    set_process(true)
    update()


func _process(delta: float) -> void:
    _elapsed += delta
    if _birth_positions.size() < HEARTS.size():
        if is_instance_valid(_source) and not _source.dead and not _source._pending_die:
            _head_position = _get_head_position(_source)
        else:
            _source = null
        while _birth_positions.size() < HEARTS.size() and _elapsed >= _birth_positions.size() * EMISSION_INTERVAL:
            _birth_positions.append(_head_position - global_position)
        if _birth_positions.size() == HEARTS.size():
            _source = null
    if _elapsed >= LIFETIME:
        set_process(false)
        _source = null
        _main.add_node_to_pool(self, _pool_id)
        return
    update()


func _draw() -> void:
    for i in range(_birth_positions.size()):
        var age: float = _elapsed - i * EMISSION_INTERVAL
        if age < 0.0 or age >= HEART_LIFETIME:
            continue
        var progress: float = age / HEART_LIFETIME
        var pop: float = min(age / 0.12, 1.0)
        var size: float = (36.0 if i == 0 else 27.0) * (sin(pop * PI * 0.5) + 0.14 * sin(pop * PI))
        var side: float = 0.0 if i == 0 else (-1.0 if i == 1 else 1.0)
        var offset: Vector2 = _birth_positions[i] + Vector2(side * (10.0 + 13.0 * progress) + sin(progress * PI * 1.5) * 3.0, -progress * 34.0 + abs(side) * 5.0)
        var alpha: float = 1.0 - smoothstep(0.65, 1.0, progress)
        draw_set_transform(offset, side * (0.12 + 0.10 * sin(progress * PI)), Vector2.ONE)
        draw_texture_rect(HEARTS[i], Rect2(Vector2.ONE * -size * 0.5, Vector2.ONE * size), false, Color(1.0, 0.48 + i * 0.06, 0.66 + i * 0.04, alpha))


func _get_head_position(source: Node) -> Vector2:
    return source.sprite.to_global(Vector2(0.0, source.sprite.get_rect().position.y)) + Vector2(0.0, -7.0)
