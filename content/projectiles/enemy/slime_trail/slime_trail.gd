extends Area2D

signal duration_timeout()

var idle_time_after_pushed_back: float = 10.0
var already_recycle: bool = false

var reduction: float = 0.5
var affected_players: Array = []

onready var duration_timer: Timer = $Timer

# =========================== Extension =========================== #
func _ready() -> void:
    reset()

func reset() -> void:
    hide()
    set_deferred("monitoring", false)
    set_physics_process(false)
    scale = Vector2(1.0, 1.0)
    idle_time_after_pushed_back = 10.0
    affected_players.clear()

func drop(pos: Vector2, duration: float) -> void:
    global_position = pos
    duration_timer.wait_time = duration
    duration_timer.start()
    show()
    set_physics_process(true)

func _physics_process(delta: float) -> void:
    if idle_time_after_pushed_back > 0:
        if !monitoring: monitoring = true
        idle_time_after_pushed_back -= Utils.physics_one(delta) * delta
    else: set_physics_process(false)

# =========================== Method =========================== #
func fa_on_DurationTimerTimeout() -> void:
    emit_signal("duration_timeout")
    reset()

    for body in affected_players:
        fa_remove_effect_from_body(body)

func fa_on_SlimeTrail_body_entered(body) -> void:
    if affected_players.has(body): return

    if !body or body.dead: return

    var player_index: int = body.player_index
    var effects: Dictionary = RunData.get_player_effects(player_index)
    
    var original_speed = effects[Utils.fantasy_original_speed_hash]
    if body.current_stats.speed >= original_speed: effects[Utils.fantasy_original_speed_hash] = body.current_stats.speed
    
    body.current_stats.speed *= 1 - reduction
    affected_players.append(body)

func fa_on_SlimeTrail_body_exited(body) -> void:
    fa_remove_effect_from_body(body)

func fa_remove_effect_from_body(body) -> void:
    if !affected_players.has(body): return

    if !body or body.dead: return

    var player_index: int = body.player_index
    body.current_stats.speed = RunData.get_player_effect(Utils.fantasy_original_speed_hash, player_index)
    affected_players.erase(body)
