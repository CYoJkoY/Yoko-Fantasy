extends AnimatedSprite

var _main: Node
var _pool_id: int


func _ready() -> void:
    connect("animation_finished", self, "_finish")


func begin(at: Vector2, angle: float, main: Node, pool_id: int, opacity: float) -> void:
    _main = main
    _pool_id = pool_id
    global_position = at
    rotation = angle
    modulate.a = opacity
    stop()
    frame = 0
    visible = true
    play("default")


func _finish() -> void:
    stop()
    visible = false
    _main.add_node_to_pool(self, _pool_id)
