extends Line2D

const LIFETIME: float = 0.16
const SAMPLE_INTERVAL: float = 0.0125
const MAX_POINTS: int = 16

var _sample_times: Array = []
var _source: Sprite
var _emitting: bool = false
var _ending: bool = false
var _end_position: Vector2
var _time: float = 0.0
var _next_sample_time: float = SAMPLE_INTERVAL
var _previous_position: Vector2


func _ready() -> void:
	set_as_toplevel(true)
	global_transform = Transform2D.IDENTITY
	process_priority = 1
	gradient = Gradient.new()
	gradient.offsets = PoolRealArray([0.0, 0.16, 0.4, 0.68, 0.86, 1.0])
	gradient.colors = PoolColorArray([
		Color(1.0, 0.72, 0.3, 0.0), Color(1.0, 0.79, 0.42, 0.0),
		Color(1.0, 0.88, 0.6, 0.0), Color(1.0, 0.95, 0.77, 0.0),
		Color(1.0, 0.98, 0.86, 0.0), Color(1.0, 0.98, 0.86, 0.0)
	])
	visible = false
	set_process(false)


func begin_trail(source: Sprite) -> void:
	clear_trail()
	_source = source
	_emitting = true
	_time = 0.0
	_next_sample_time = SAMPLE_INTERVAL
	_previous_position = source.global_position
	add_point(_previous_position)
	add_point(_previous_position)
	_sample_times.append(0.0)
	_sample_times.append(0.0)
	set_process(true)


func end_trail() -> void:
	if not _emitting:
		return
	_emitting = false
	_ending = true
	_end_position = _source.global_position
	_source = null


func clear_trail() -> void:
	if _sample_times.empty():
		return
	_emitting = false
	_ending = false
	_source = null
	_sample_times.clear()
	clear_points()
	visible = false
	set_process(false)


func _process(delta: float) -> void:
	var previous_time: float = _time
	_time += delta
	if _emitting or _ending:
		var current_position: Vector2 = _source.global_position if _emitting else _end_position
		_next_sample_time = max(_next_sample_time, ceil((_time - LIFETIME) / SAMPLE_INTERVAL) * SAMPLE_INTERVAL)
		while _next_sample_time <= _time:
			var weight: float = clamp((_next_sample_time - previous_time) / max(delta, 0.0001), 0.0, 1.0)
			_append_sample(_previous_position.linear_interpolate(current_position, weight), _next_sample_time)
			_next_sample_time += SAMPLE_INTERVAL
		var tip: int = get_point_count() - 1
		if get_point_position(tip) != current_position:
			set_point_position(tip, current_position)
		_sample_times[tip] = _time
		_previous_position = current_position
		_ending = false
	_trim_tail()
	if _sample_times.empty():
		return
	_update_fade()


func _append_sample(at_position: Vector2, birth_time: float) -> void:
	var tip: int = get_point_count() - 1
	if tip > 0 and get_point_position(tip - 1).distance_squared_to(at_position) < 1.0:
		return
	set_point_position(tip, at_position)
	_sample_times[tip] = birth_time
	add_point(at_position)
	_sample_times.append(birth_time)
	if get_point_count() > MAX_POINTS:
		remove_point(0)
		_sample_times.pop_front()


func _trim_tail() -> void:
	var cutoff: float = _time - LIFETIME
	if not _emitting and _sample_times.back() <= cutoff:
		clear_trail()
		return
	while _sample_times.size() > 2 and _sample_times[1] <= cutoff:
		remove_point(0)
		_sample_times.pop_front()
	if _sample_times[0] < cutoff and _sample_times[1] > _sample_times[0]:
		var weight: float = clamp((cutoff - _sample_times[0]) / (_sample_times[1] - _sample_times[0]), 0.0, 1.0)
		set_point_position(0, get_point_position(0).linear_interpolate(get_point_position(1), weight))
		_sample_times[0] = cutoff


func _update_fade() -> void:
	var path: PoolVector2Array = points
	var length: float = 0.0
	for i in range(1, path.size()):
		length += path[i - 1].distance_to(path[i])
	visible = length >= 1.0
	if not visible:
		return
	var segment: int = 1
	var traversed: float = 0.0
	var segment_length: float = path[0].distance_to(path[1])
	for i in range(gradient.get_point_count()):
		var distance: float = gradient.get_offset(i) * length
		while segment < path.size() - 1 and traversed + segment_length < distance:
			traversed += segment_length
			segment += 1
			segment_length = path[segment - 1].distance_to(path[segment])
		var weight: float = clamp((distance - traversed) / max(segment_length, 0.0001), 0.0, 1.0)
		var birth_time: float = lerp(_sample_times[segment - 1], _sample_times[segment], weight)
		var freshness: float = clamp(1.0 - (_time - birth_time) / LIFETIME, 0.0, 1.0)
		var alpha: float = freshness * freshness * (3.0 - 2.0 * freshness)
		var color: Color = gradient.get_color(i)
		if abs(color.a - alpha) > 0.002:
			color.a = alpha
			gradient.set_color(i, color)
