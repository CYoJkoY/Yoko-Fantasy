extends Node2D

const START_SCALE: Vector2 = Vector2(0.15, 0.85)
const PEAK_SCALE: Vector2 = Vector2(1.25, 1.0)
const END_SCALE: Vector2 = Vector2(1.45, 1.05)
const START_ALPHA: float = 0.40
const PEAK_ALPHA: float = 0.10
const DURATION_IN: float = 0.08
const DURATION_OUT: float = 0.22

var _main: Node = null
var _pool_id: int = Keys.empty_hash

onready var sprite: Sprite = $"Sprite"
onready var tween: Tween = $"Tween"

# =========================== Extension =========================== #
func play(at_position: Vector2, main_node: Node = null, pool_id: int = Keys.empty_hash, visual_scale: float = 1.0) -> void:
    if sprite.texture == null: return

    _main = main_node
    _pool_id = pool_id
    global_position = at_position
    rotation = rand_range(-0.08, 0.08)
    visible = true

    sprite.visible = true
    sprite.scale = START_SCALE * visual_scale
    sprite.modulate = Color(1.0, 0.96, 0.72, START_ALPHA)

    tween.stop_all()
    tween.remove_all()
    tween.interpolate_property(sprite, "scale", START_SCALE * visual_scale, PEAK_SCALE * visual_scale, DURATION_IN, Tween.TRANS_QUAD, Tween.EASE_OUT)
    tween.interpolate_property(sprite, "modulate", Color(1.0, 0.96, 0.72, START_ALPHA), Color(1.0, 1.0, 0.88, PEAK_ALPHA), DURATION_IN, Tween.TRANS_QUAD, Tween.EASE_OUT)
    tween.interpolate_property(sprite, "scale", PEAK_SCALE * visual_scale, END_SCALE * visual_scale, DURATION_OUT, Tween.TRANS_SINE, Tween.EASE_OUT, DURATION_IN)
    tween.interpolate_property(sprite, "modulate", Color(1.0, 1.0, 0.88, PEAK_ALPHA), Color(1.0, 1.0, 0.9, 0.0), DURATION_OUT, Tween.TRANS_SINE, Tween.EASE_IN, DURATION_IN)
    tween.start()

# =========================== Method =========================== #
func fa_on_Tween_tween_all_completed() -> void:
    visible = false
    _main.add_node_to_pool(self , _pool_id)
