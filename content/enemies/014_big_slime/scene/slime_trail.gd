extends Area2D

var duration: float = 5.0
var reduction: float = 0.5
var affected_players: Array = []

func _ready() -> void:
    var timer = get_tree().create_timer(duration)
    timer.connect("timeout", self, "_on_TimerTimeout")

func _on_TimerTimeout() -> void:
    if is_instance_valid(self):
        for body in affected_players:
            _remove_effect_from_body(body)
        queue_free()

func _on_SlimeTrail_body_entered(body) -> void:
    if not body in affected_players:
        var player_index: int = body.player_index
        affected_players.append(body)
        var original_speed = RunData.players_data[player_index].effects[Keys.fantasy_original_speed_hash]
        if body.current_stats.speed >= original_speed:
            RunData.players_data[player_index].effects[Keys.fantasy_original_speed_hash] = body.current_stats.speed
        body.current_stats.speed *= 1 - reduction

func _on_SlimeTrail_body_exited(body) -> void:
    _remove_effect_from_body(body)

func _remove_effect_from_body(body) -> void:
    if body in affected_players:
        var player_index: int = body.player_index
        affected_players.erase(body)
        
        if body and not body.dead:
            body.current_stats.speed = RunData.get_player_effect(Keys.fantasy_original_speed_hash, player_index)
        
        
