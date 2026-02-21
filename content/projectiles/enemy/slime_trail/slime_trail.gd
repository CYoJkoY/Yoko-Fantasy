extends Area2D

signal duration_timeout()

var already_recycle: bool = false
var duration: float = 5.0
var reduction: float = 0.5
var affected_players: Array = []

onready var duration_timer: Timer = $Timer

# =========================== Extension =========================== #
func _ready() -> void:
    hide()
    set_deferred("monitoring", false)
    set_physics_process(false)
    duration_timer.wait_time = duration

# =========================== Method =========================== #
func fa_on_DurationTimerTimeout() -> void:
    for body in affected_players:
        fa_remove_effect_from_body(body)

    emit_signal("duration_timeout")

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
