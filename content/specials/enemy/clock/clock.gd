extends Node2D

export(bool) var with_prediction = false
export(PackedScene) var prediction_line_scene = null
export(Color) var prediction_line_color = Color("#3E68DA")
export(float) var prediction_line_width = 40.0
export(int) var prediction_line_points_num = 64

export(int) var tick_num = 12
export(bool) var fixed_start_rotation = false
export(float) var start_rotation = 0.0
export(float) var tick_time = 0.5

onready var tween: Tween = $"Tween"
onready var timer: Timer = $"Timer"

var tick_angle: float = TAU / float(tick_num)
var prediction_line: Line2D = null
var main: Main = Utils.get_scene_node()

# =========================== Extension =========================== #
func _ready() -> void:
    timer.wait_time = tick_time
    timer.start()
    rotation = deg2rad(start_rotation) if fixed_start_rotation else tick_angle * Utils.randi_range(0, tick_num - 1)
    global_position = ZoneService.get_map_center()
    if with_prediction: _fantasy_spawn_prediction_line()

# =========================== Custom =========================== #
func _fantasy_change_tick(is_add: bool) -> void:
    var target_angle = rotation + (tick_angle if is_add else -tick_angle)
    tween.interpolate_property(
        self , "rotation",
        rotation, target_angle, 0.2,
        Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
    tween.start()

func _fantasy_get_current_radius() -> float:
    var bullets = get_children()
    return bullets[-1].max_target_distance

func _fantasy_get_all_top_positions() -> Array:
    var center: Vector2 = global_position
    var base_vec: Vector2 = Vector2.UP * _fantasy_get_current_radius()
    var top_positions: Array = []
    for i in range(tick_num):
        var top_position: Vector2 = center + base_vec.rotated(i * tick_angle)
        top_positions.append(top_position)
    return top_positions

func _fantasy_spawn_prediction_line() -> void:
    var center: Vector2 = global_position
    var base_vec: Vector2 = Vector2.UP * _fantasy_get_current_radius()
    var prediction_point_angle: float = TAU / float(prediction_line_points_num)
    var prediction_points: PoolVector2Array = PoolVector2Array()
    for i in range(prediction_line_points_num + 1):
        var prediction_point: Vector2 = center + base_vec.rotated(i * prediction_point_angle)
        prediction_points.append(prediction_point)

    prediction_line = prediction_line_scene.instance()
    main.add_effect(prediction_line)
    prediction_line.points = prediction_points
    prediction_line.default_color = prediction_line_color
    prediction_line.width = prediction_line_width
    prediction_line.draw_prediction()
