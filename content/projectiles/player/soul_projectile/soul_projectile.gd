extends "res://mods-unpacked/Yoko-Fantasy/content/projectiles/player/micro_homing_player_projectile.gd"

export(float) var turn_rate = 10.0

func fa_set_initial_homing_target(target) -> void:
    _homing_target = target if is_instance_valid(target) else null

func _physics_process(delta: float) -> void:
    _process_micro_homing(delta, turn_rate, Utils.LARGE_NUMBER, 180.0, 180.0)
    ._physics_process(delta)

func _find_best_homing_target(_max_range: float, _acquire_fov_deg: float) -> Node:
    return Utils.fa_get_highest_health_enemy(Utils.get_scene_node()._entity_spawner.get_all_enemies(false))
