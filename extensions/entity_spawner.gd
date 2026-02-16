extends "res://global/entity_spawner.gd"

# EFFECT : gain_temp_stat_every_killed_enemies

# =========================== Extension =========================== #
func _on_enemy_died(enemy: Node2D, _args: Entity.DieArgs) -> void:
    ._on_enemy_died(enemy, _args)
    if !_cleaning_up:
        _fantasy_gain_temp_stat_every_killed_enemies()

# =========================== Custom =========================== #
func _fantasy_gain_temp_stat_every_killed_enemies() -> void:
    pass
