extends Area2D

signal duration_timeout()

onready var duration_timer: Timer = $"Timer"
onready var _sprite: Sprite = $"Sprite"

var idle_time_after_pushed_back: float = 10.0
var already_recycle: bool = false

var reduction: float = 0.5
var affected_units: Dictionary = {}

# =========================== Extension =========================== #
func _ready() -> void:
    reset()

func reset() -> void:
    hide()
    set_deferred("monitoring", false)
    set_physics_process(false)
    collision_mask = Utils.PLAYER_BIT
    _sprite.material = null
    scale = Vector2(1.0, 1.0)
    idle_time_after_pushed_back = 10.0
    affected_units.clear()

func set_collision_mask(value: int) -> void:
	collision_mask = value

func set_sprite_material(material: ShaderMaterial) -> void:
	_sprite.material = material

func drop(pos: Vector2, duration: float) -> void:
    global_position = pos
    duration_timer.wait_time = duration
    duration_timer.start()
    show()
    set_physics_process(true)

func _physics_process(delta: float) -> void:
    if idle_time_after_pushed_back > 0:
        if !monitoring: monitoring = true
        idle_time_after_pushed_back -= Utils.physics_one(delta)
    else: set_physics_process(false)

# =========================== Method =========================== #
func fa_on_DurationTimerTimeout() -> void:
    emit_signal("duration_timeout")
    reset()

    for body in affected_units:
        fa_remove_effect_from_body(body)

func fa_on_SlimeTrail_body_entered(body) -> void:
    if affected_units.has(body): return

    if !is_instance_valid(body) or body.dead: return

    var original_speed: int = body.current_stats.speed
    body.current_stats.speed = int(original_speed * reduction)
    affected_units.set(body, original_speed)

func fa_on_SlimeTrail_body_exited(body) -> void:
    fa_remove_effect_from_body(body)

func fa_remove_effect_from_body(body) -> void:
    if !affected_units.has(body): return

    if !is_instance_valid(body) or body.dead: return

    body.current_stats.speed = affected_units[body]
    affected_units.erase(body)
