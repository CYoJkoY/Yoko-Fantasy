extends ShootingAttackBehavior

export(PackedScene) var prediction_line_scene = preload("res://mods-unpacked/Yoko-Fantasy/content/specials/enemy/prediction_line/prediction_line.tscn")
var prediction_line_pool_id: int = Keys.empty_hash
export(float) var prediction_line_time = 3.0
export(float) var prediction_line_precision = 0.1
export(float) var prediction_line_duration = 1.0
export(Color) var prediction_line_color = Color.red
export(float) var prediction_line_width = 30.0

export(float) var wave_range = 100.0
export(float) var wave_speed = 1.0

var active_projectiles: Array = []
var _time_passed: float = 0.0
var _forward = Vector2.ZERO
var pre_forward = Vector2.ZERO
var _perpendicular: Vector2 = Vector2.ZERO

var main: Main = Utils.get_scene_node()

# =========================== Extension =========================== #
func _ready() -> void:
    if prediction_line_scene: prediction_line_pool_id = Keys.generate_hash(prediction_line_scene.resource_path)

func reset() -> void:
    _time_passed = 0.0
    active_projectiles.clear()

func physics_process(delta: float) -> void:
    _time_passed += delta

    for i in range(active_projectiles.size() - 1, -1, -1):
        var p = active_projectiles[i]

        if !p._hitbox.active:
            active_projectiles.remove(i)
            continue
        
        if _forward == Vector2.ZERO or _forward != pre_forward:
            _forward = p.velocity.normalized()
            pre_forward = _forward
            _perpendicular = _forward.rotated(PI / 2.0)

        # offset(t) = wave_range * sin(wave_speed * TAU * t)
        # d(offset) / dt = wave_range * cos(wave_speed * TAU * t) * (wave_speed * TAU)
        var delta_wave_offset: Vector2 = _perpendicular * wave_range * cos(_time_passed * wave_speed * TAU) * wave_speed * TAU * delta
        p.position += delta_wave_offset

    if _current_initial_cooldown > 0:
        _current_initial_cooldown = _current_initial_cooldown - Utils.physics_one(delta)
        return

    _current_cd = _current_cd - Utils.physics_one(delta)

    if not _parent.is_playing_shoot_animation() and _current_cd <= 0 and Utils.is_between(_parent.global_position.distance_to(_parent.current_target.global_position), min_range, max_range):
        _parent._animation_player.playback_speed = attack_anim_speed
        _parent._animation_player.play(_parent.shoot_animation_name)
        emit_signal("shot")

func shoot() -> void:
    var target_pos = _parent.current_target.global_position
    var base_randomization = rand_range(-base_direction_randomization, base_direction_randomization)

    if base_direction_constant_spread:
        if alternate_between_base_direction_spread:
            if _last_base_direction_spread < 0:
                base_randomization = base_direction_randomization
            else:
                base_randomization = - base_direction_randomization
        else:
            base_randomization = Utils.get_rand_element([-base_direction_randomization, base_direction_randomization])
        _last_base_direction_spread = base_randomization

    if shoot_in_unit_direction:
        target_pos = _parent.global_position + _parent.get_movement()

    var base_pos = 0.0

    if constant_spread_rand_base_pos > 0.0:
        base_pos = rand_range(0.0, constant_spread_rand_base_pos)

    var rand_rot = rand_range(-random_rotation, random_rotation)
    var speed: int = 0
    var _projectile: Node = null

    for i in range(number_projectiles):
        var pos: Vector2 = get_projectile_spawn_pos(target_pos, i, base_pos)

        var base_rot = (target_pos - _parent.global_position).angle() + base_randomization

        var rot = rand_range(base_rot - projectile_spread, base_rot + projectile_spread)
        
        speed = projectile_speed

        if random_direction:
            rot = rand_range(-PI, PI)

        if constant_spread and number_projectiles > 1:
            var chunk = (2 * projectile_spread) / (number_projectiles - 1)
            var start = base_rot - projectile_spread
            rot = start + (i * chunk)

        if shoot_away_from_unit:
            target_pos = pos
            if rand_rot != 0.0:
                target_pos = get_new_target_pos(target_pos, rand_rot)
            rot = (target_pos - _parent.global_position).angle()

        if shoot_towards_unit:
            target_pos = _parent.global_position
            if rand_rot != 0.0:
                target_pos = get_new_target_pos(target_pos, rand_rot)
            rot = (target_pos - pos).angle()

        if shoot_from_proj_pos_towards_player:
            target_pos = _parent.current_target.global_position
            if rand_rot != 0.0:
                target_pos = get_new_target_pos(target_pos, rand_rot)
            rot = (target_pos - pos).angle()

        if speed_change_after_each_projectile != 0:
            speed += speed_change_after_each_projectile * i
        
        # Prediction lines
        _fantasy_spawn_prediction_line(rot, pos, speed)

        # Waving projectiles
        _projectile = spawn_projectile(rot, pos, int(rand_range(speed - projectile_speed_randomization, speed + projectile_speed_randomization)))
        active_projectiles.append(_projectile)

    _shots_taken += 1

# =========================== Custom =========================== #
func _fantasy_spawn_prediction_line(rot: float, pos: Vector2, spd: int) -> void:
    var prediction_line: Node = main.get_node_from_pool(prediction_line_pool_id, main._effects)
    if !is_instance_valid(prediction_line):
        prediction_line = prediction_line_scene.instance()
        main.add_effect(prediction_line)
        var _error = prediction_line.connect("duration_timeout", self , "fa_on_DurationTimer_timeout", [prediction_line])

    prediction_line.already_recycle = false
    var velocity: Vector2 = Vector2.RIGHT.rotated(rot) * spd * RunData.current_run_accessibility_settings.speed
    prediction_line.points = fa_get_prediction_points(pos, velocity, prediction_line_time, prediction_line_precision)
    prediction_line.default_color = prediction_line_color
    prediction_line.width = prediction_line_width

    prediction_line.draw_prediction(prediction_line_duration)

# =========================== Method =========================== #
func fa_on_DurationTimer_timeout(prediction_line: Line2D) -> void:
    if prediction_line.already_recycle: return

    prediction_line.already_recycle = true
    main.add_node_to_pool(prediction_line, prediction_line_pool_id)

func fa_get_prediction_points(start_pos: Vector2, velocity: Vector2, time: float, precision: float) -> PoolVector2Array:
    var points: PoolVector2Array = PoolVector2Array()
    var forward: Vector2 = velocity.normalized()
    var perpendicular: Vector2 = forward.rotated(PI / 2.0)
    
    var t: float = 0.0
    while t <= time:
        var linear_pos: Vector2 = start_pos + velocity * t
        var wave_offset: Vector2 = perpendicular * wave_range * sin(wave_speed * TAU * t)

        points.append(linear_pos + wave_offset)
        t += precision
        
    return points
