extends "res://weapons/shooting_behaviors/melee_weapon_shooting_behavior.gd"

enum Phase { IDLE, WINDUP, OUTBOUND, RETURN }

const STEERING_END: float = 0.55
const MAX_ARC_BEND: float = 100.0
const ARC_BEND_RATIO: float = 0.32

var phase: int = Phase.IDLE
var attack_angle: float = 0.0
var _elapsed: float = 0.0
var _duration: float = 0.0
var _outbound_duration: float = 0.0
var _return_duration: float = 0.0
var _time_remainder: float = 0.0
var _reach: float = 0.0
var _side: float = 1.0
var _bend_scale: float = 1.0
var _motion_scale: float = 1.0
var _windup_angle: float = 0.55
var _windup_offset: float = 24.0
var _follow_angle: float = 0.30
var _exit_speed: float = 1.0
var _direction: Vector2
var _phase_start: Vector2
var _flight_end: Vector2
var _handle_rest: Vector2
var _handle_angle: float = 0.0
var _return_control: Vector2
var _release_velocity: Vector2
var _target: Node


func shoot(_distance: float) -> void:
    shooting_data = MeleeShootingData.new(_parent.current_stats, _parent.player_index)
    var physics_step: float = 1.0 / Engine.iterations_per_second
    var total_duration: float = max(shooting_data.get_shooting_total_duration(), physics_step * 4.0)
    var free_duration: float = total_duration - physics_step * 4.0
    _duration = physics_step + free_duration * 0.14
    _outbound_duration = physics_step * 2.0 + free_duration * 0.34
    _return_duration = total_duration - _duration - _outbound_duration
    _exit_speed = min(1.2, 3.2 * _outbound_duration / _return_duration)
    attack_angle = _parent.rotation
    _direction = Vector2.RIGHT.rotated(attack_angle)
    _side = -_side
    _reach = max(70.0, _parent.current_stats.max_range + 20.0)
    _motion_scale = clamp(_reach / 320.0, 0.35, 1.2)
    _bend_scale = rand_range(0.94, 1.06)
    _windup_angle = rand_range(0.50, 0.60) * _motion_scale
    _windup_offset = 42.0 * _motion_scale
    _follow_angle = rand_range(0.32, 0.38) * _motion_scale
    _handle_rest = _parent.sprite.position
    _handle_angle = _parent.get_handle_rest_angle()
    _phase_start = _parent.head_position - _parent.global_position
    _elapsed = 0.0
    _time_remainder = 0.0
    phase = Phase.WINDUP
    _parent.set_shooting(true)
    _parent._hitbox.player_attack_id = _get_next_attack_id()
    _parent.disable_hitbox()


func advance(delta: float) -> void:
    if _elapsed >= _duration:
        _next_phase()
    var next_elapsed: float = _elapsed + delta + _time_remainder
    _time_remainder = max(0.0, next_elapsed - _duration)
    _elapsed = min(next_elapsed, _duration)
    var t: float = _elapsed / _duration
    var eased: float = t * t * (3.0 - 2.0 * t)
    var owner_position: Vector2 = _parent.global_position
    if phase == Phase.WINDUP:
        var hand_progress: float = clamp(t / 0.72, 0.0, 1.0)
        var hand_eased: float = hand_progress * hand_progress * (3.0 - 2.0 * hand_progress)
        _parent.sprite.position = _handle_rest + Vector2(-14.0 * hand_eased * _motion_scale, 0)
        _parent.sprite.rotation = _handle_angle - _side * _windup_angle * hand_eased
        var back: Vector2 = _parent.get_chain_anchor() - owner_position + Vector2(18.0 * _motion_scale, _side * _windup_offset).rotated(attack_angle)
        _parent.head_position = owner_position + _phase_start.linear_interpolate(back, eased)
    elif phase == Phase.OUTBOUND:
        if t < STEERING_END and is_instance_valid(_target) and not _target.is_queued_for_deletion() and not (_target is Unit and _target._pending_die):
            var desired: Vector2 = _get_target_endpoint((_duration - _elapsed) * 0.8)
            var turn: float = 1.5 * delta / _duration * (1.0 - t / STEERING_END)
            _flight_end = _flight_end.rotated(clamp(_flight_end.angle_to(desired), -turn, turn))
        var launch: float = t * t * ((3.0 - _exit_speed) + (_exit_speed - 2.0) * t)
        var hand_progress: float = clamp(t / 0.68, 0.0, 1.0)
        var hand_eased: float = hand_progress * hand_progress * (3.0 - 2.0 * hand_progress)
        _parent.sprite.position = _handle_rest + Vector2((-14.0 * (1.0 - hand_eased) + 20.0 * sin(PI * hand_eased)) * _motion_scale, 0)
        _parent.sprite.rotation = _handle_angle + _side * (-_windup_angle + (_windup_angle + _follow_angle) * hand_eased)
        var chord: Vector2 = _flight_end - _phase_start
        var forward: Vector2 = chord.normalized()
        var normal: Vector2 = Vector2(-forward.y, forward.x) * _side
        var bend: float = min(MAX_ARC_BEND, chord.length() * ARC_BEND_RATIO) * _bend_scale
        var control: Vector2 = _phase_start + chord * 0.35 + normal * bend
        var approach: Vector2 = _flight_end + normal * bend - forward * bend * 0.12
        _parent.head_position = owner_position + _get_arc_position(launch, control, approach, _flight_end)
        _release_velocity = (_flight_end - approach) * (3.0 * _exit_speed / _outbound_duration)
    else:
        var recovery: float = t * (2.0 - t)
        var recovery_eased: float = recovery * recovery * (3.0 - 2.0 * recovery)
        _parent.sprite.position = _handle_rest + Vector2(-12.0 * sin(PI * recovery_eased) * _motion_scale, 0)
        _parent.sprite.rotation = _handle_angle + _side * (_follow_angle * (1.0 - recovery_eased) + 0.12 * sin(PI * recovery_eased) * _motion_scale)
        var rest: Vector2 = _parent.get_rest_position() - owner_position
        var remaining: float = 1.0 - recovery
        _parent.head_position = owner_position + _phase_start * (remaining * remaining * remaining) \
            + _return_control * (3.0 * remaining * remaining * recovery) \
            + rest * (recovery * recovery * (3.0 * remaining + recovery))
        if _elapsed >= _duration:
            cancel_attack()


func _get_arc_position(progress: float, control: Vector2, approach: Vector2, endpoint: Vector2) -> Vector2:
    var remaining: float = 1.0 - progress
    return _phase_start * (remaining * remaining * remaining) + control * (3.0 * remaining * remaining * progress) \
        + approach * (3.0 * remaining * progress * progress) + endpoint * (progress * progress * progress)


func is_damage_phase() -> bool:
    return phase == Phase.OUTBOUND


func get_chain_tension() -> float:
    if phase == Phase.OUTBOUND:
        var t: float = clamp(_elapsed / _duration / 0.48, 0.0, 1.0)
        return t * t * (3.0 - 2.0 * t)
    if phase == Phase.RETURN:
        var t: float = _elapsed / _duration
        return pow(1.0 - t, 3.0)
    return 0.0


func _get_target_endpoint(lead_time: float) -> Vector2:
    var aim: Vector2 = _target.global_position
    var relative_velocity: Vector2 = -_parent._parent.get_move_input()
    lead_time *= sqrt(clamp(aim.distance_to(_parent.global_position) / _reach, 0.0, 1.0))
    if _target is Unit:
        relative_velocity += _target.get_move_input()
    aim += (relative_velocity * lead_time).clamped(48.0)
    return _get_aim_endpoint(aim - _parent.global_position)


func _get_aim_endpoint(offset: Vector2) -> Vector2:
    var aim_distance: float = offset.length()
    if aim_distance < 1.0:
        return _direction * _reach
    var aim_direction: Vector2 = offset / aim_distance
    var endpoint: Vector2 = aim_direction * _reach
    var start_projection: float = _phase_start.dot(aim_direction)
    for _iteration in range(3):
        var chord: Vector2 = endpoint - _phase_start
        var forward: Vector2 = chord.normalized()
        var normal: Vector2 = Vector2(-forward.y, forward.x) * _side
        var bend: float = min(MAX_ARC_BEND, chord.length() * ARC_BEND_RATIO) * _bend_scale
        var control: Vector2 = _phase_start + chord * 0.35 + normal * bend
        var approach: Vector2 = endpoint + normal * bend - forward * bend * 0.12
        var control_projection: float = control.dot(aim_direction)
        var approach_projection: float = approach.dot(aim_direction)
        var end_projection: float = endpoint.dot(aim_direction)
        var low: float = 0.0
        var high: float = 1.0
        for _step in range(8):
            var midpoint: float = (low + high) * 0.5
            var remaining: float = 1.0 - midpoint
            var projection: float = start_projection * (remaining * remaining * remaining) \
                + 3.0 * midpoint * remaining * (control_projection * remaining + approach_projection * midpoint) \
                + end_projection * (midpoint * midpoint * midpoint)
            if projection < aim_distance:
                low = midpoint
            else:
                high = midpoint
        var point: Vector2 = _get_arc_position((low + high) * 0.5, control, approach, endpoint)
        endpoint = endpoint.rotated(clamp(point.angle_to(offset), -0.4, 0.4))
    return endpoint


func _prepare_launch() -> void:
    _target = null
    if _parent._manual_aim:
        if Utils.is_player_using_gamepad(_parent.player_index):
            var stick: Vector2 = _parent._parent.gamepad_attack_vector
            if stick.length_squared() > 0.0:
                _direction = stick.normalized()
            _flight_end = (_phase_start + _direction * _reach).normalized() * _reach
        else:
            _flight_end = _get_aim_endpoint(_parent.get_global_mouse_position() - _parent.global_position)
    else:
        var _aim_angle: float = _parent.get_direction_and_calculate_target()
        if not _parent._current_target.empty() and is_instance_valid(_parent._current_target[0]):
            _target = _parent._current_target[0]
        _flight_end = _get_target_endpoint(_outbound_duration * 0.8) if is_instance_valid(_target) else _direction * _reach
    _direction = (_flight_end - _phase_start).normalized()


func _next_phase() -> void:
    _elapsed = 0.0
    _phase_start = _parent.head_position - _parent.global_position
    if phase == Phase.WINDUP:
        phase = Phase.OUTBOUND
        _duration = _outbound_duration
        _prepare_launch()
        _parent._hitbox.active = true
        _parent.enable_hitbox()
        SoundManager.play(Utils.get_rand_element(_parent.current_stats.shooting_sounds), _parent.current_stats.sound_db_mod, 0.1)
    else:
        phase = Phase.RETURN
        _duration = _return_duration
        _return_control = _phase_start + _release_velocity * (_return_duration / 6.0)
        _parent.disable_hitbox()
        _target = null


func cancel_attack() -> void:
    _parent.disable_hitbox()
    _parent.set_shooting(false)
    if phase == Phase.IDLE:
        return
    phase = Phase.IDLE
    _target = null
    _time_remainder = 0.0
    _parent.sprite.position = _handle_rest
    _parent.sprite.rotation = _handle_angle
