extends MovementBehavior

export (float) var wave_period = 2.0
export (float) var wave_amplitude = 1000.0
export (int) var range_around_player = 200
export (int) var range_randomization = 0
export (bool) var allow_within: bool = true

var time: float = 0.0
var _actual: int
var _distance_from_player: Vector2


func init(parent: Node)->Node:
    var _init = .init(parent)
    _actual = range_around_player + rand_range( - range_randomization, range_randomization)
    _distance_from_player = Vector2(rand_range( - _actual, _actual), rand_range( - _actual, _actual))

    if not allow_within:
        _distance_from_player = _distance_from_player.normalized() * _actual

    return self

func _physics_process(delta) -> void:
    time += delta

func get_movement()->Vector2:
    var target = get_target_position()

    if Utils.vectors_approx_equal(target, _parent.global_position, EQUALITY_PRECISION):
        return Vector2.ZERO
    
    var to_target: Vector2 = target.normalized()
    var sway_direction: Vector2 = Vector2(to_target.y, -to_target.x)
    var sway_offset: Vector2 = sway_direction * sin(time * 2.0 * PI / wave_period) * wave_amplitude
    var forward_movement: Vector2 = to_target * _parent.stats.speed * 2.0
    var final_movement: Vector2 = forward_movement + sway_offset
    
    return final_movement


func get_target_position():
    return _parent.current_target.global_position + _distance_from_player - _parent.global_position
