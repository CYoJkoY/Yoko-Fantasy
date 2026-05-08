extends ShootingAttackBehavior

export(int) var bullets_per_frame = 2

var _shooting_cancelled: bool = false

# =========================== Extension =========================== #
func reset() -> void:
    .reset()
    _shooting_cancelled = true

func shoot() -> void:
    _shooting_cancelled = true

    var target_pos = _parent.current_target.global_position
    var base_randomization = rand_range(-base_direction_randomization, base_direction_randomization)

    if base_direction_constant_spread:
        if alternate_between_base_direction_spread:
            if _last_base_direction_spread < 0: base_randomization = base_direction_randomization
            else: base_randomization = - base_direction_randomization
        else: base_randomization = Utils.get_rand_element([-base_direction_randomization, base_direction_randomization])
        _last_base_direction_spread = base_randomization

    if shoot_in_unit_direction: target_pos = _parent.global_position + _parent.get_movement()

    var base_pos = 0.0

    if constant_spread_rand_base_pos > 0.0: base_pos = rand_range(0.0, constant_spread_rand_base_pos)

    var rand_rot = rand_range(-random_rotation, random_rotation)

    _current_cd = cooldown
    _shooting_cancelled = false
    _fantasy_distribute_shots(target_pos, base_randomization, base_pos, rand_rot)

func _fantasy_distribute_shots(target_pos: Vector2, base_randomization: float, base_pos: float, rand_rot: float) -> void:
    var speed: int = projectile_speed
    var bullets_this_frame = 0

    for i in range(number_projectiles):
        if _shooting_cancelled: return

        var pos: Vector2 = get_projectile_spawn_pos(target_pos, i, base_pos)
        var base_rot = (target_pos - _parent.global_position).angle() + base_randomization
        var rot = rand_range(base_rot - projectile_spread, base_rot + projectile_spread)

        if speed_change_after_each_projectile != 0: speed = projectile_speed + speed_change_after_each_projectile * i

        if random_direction: rot = rand_range(-PI, PI)

        if constant_spread and number_projectiles > 1:
            var chunk = (2 * projectile_spread) / (number_projectiles - 1)
            var start = base_rot - projectile_spread
            rot = start + (i * chunk)

        if shoot_away_from_unit:
            var away_pos = pos
            if rand_rot != 0.0: away_pos = get_new_target_pos(away_pos, rand_rot)
            rot = (away_pos - _parent.global_position).angle()

        if shoot_towards_unit:
            var towards_pos = _parent.global_position
            if rand_rot != 0.0: towards_pos = get_new_target_pos(towards_pos, rand_rot)
            rot = (towards_pos - pos).angle()

        if shoot_from_proj_pos_towards_player:
            var player_pos = _parent.current_target.global_position
            if rand_rot != 0.0: player_pos = get_new_target_pos(player_pos, rand_rot)
            rot = (player_pos - pos).angle()

        var final_speed = int(rand_range(speed - projectile_speed_randomization, speed + projectile_speed_randomization))
        spawn_projectile(rot, pos, final_speed)

        bullets_this_frame += 1
        if bullets_this_frame < bullets_per_frame: continue

        yield (get_tree(), "idle_frame")
        bullets_this_frame = 0

    if !_shooting_cancelled: _shots_taken += 1
