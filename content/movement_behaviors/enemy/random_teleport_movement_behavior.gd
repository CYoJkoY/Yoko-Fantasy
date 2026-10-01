extends MovementBehavior

export(float) var teleport_cooldown: float = 3.0
export(float) var teleport_distance: float = 700.0
export(bool) var base_on_centerx: bool = true
export(bool) var base_on_centery: bool = true
export(PackedScene) var prediction_line_scene = preload("res://mods-unpacked/Yoko-Fantasy/content/specials/enemy/prediction_line/prediction_line.tscn")
export(float) var prediction_duration: float = 1.0
export(float) var prediction_radius: float = 48.0
export(Color) var prediction_color: Color = Color("#3E68DA")
export(float) var prediction_width: float = 12.0
export(int) var prediction_points_num: int = 32

var _current_target: Vector2 = Vector2.ZERO
var _cooldown: float = 0.0
var _is_teleporting: bool = false
var _has_predicted_target: bool = false
var _prediction_line: Line2D = null
var _prediction_line_pool_id: int = Keys.empty_hash

onready var _main: Main = Utils.get_scene_node()

# ══════════════════════════════════════════ Extension ══════════════════════════════════════════ #
func _ready() -> void:
    _cooldown = teleport_cooldown
    if prediction_line_scene != null:
        _prediction_line_pool_id = Keys.generate_hash(prediction_line_scene.resource_path)

func init(parent: Node) -> Node:
    .init(parent)
    _cooldown = teleport_cooldown
    _has_predicted_target = false
    if is_instance_valid(_parent) and not _parent.is_connected("died", self, "_on_parent_died"):
        var _err = _parent.connect("died", self, "_on_parent_died")
    return self

func _exit_tree() -> void:
    _cleanup_prediction_line()

func get_movement() -> Vector2:
    if !is_instance_valid(_parent) or _parent.dead or _parent._pending_die:
        _cleanup_prediction_line()
        return Vector2.ZERO

    _cooldown -= _parent.get_physics_process_delta_time()

    if _is_teleporting:
        return Vector2.ZERO

    if !_has_predicted_target and _cooldown <= prediction_duration:
        _prepare_teleport_target()

    if _cooldown > 0:
        return Vector2.ZERO

    fa_trigger_teleport()

    return Vector2.ZERO

# ══════════════════════════════════════════ Method ══════════════════════════════════════════ #
func _prepare_teleport_target() -> void:
    _has_predicted_target = true
    var angle: float = randf() * TAU
    var direction: Vector2 = Vector2(cos(angle), sin(angle))
    var base_position: Vector2 = _parent.global_position

    match [base_on_centerx, base_on_centery]:
        [true, true]: base_position = ZoneService.get_map_center()
        [true, false]: base_position.x = ZoneService.get_map_center().x
        [false, true]: base_position.y = ZoneService.get_map_center().y

    _current_target = base_position + direction * teleport_distance
    var min_pos: Vector2 = _parent._min_pos if _parent._min_pos != Vector2.ZERO else Vector2.ZERO
    var max_pos: Vector2 = _parent._max_pos if _parent._max_pos != Vector2.ZERO else ZoneService.current_zone_max_position
    _current_target.x = clamp(_current_target.x, min_pos.x, max_pos.x)
    _current_target.y = clamp(_current_target.y, min_pos.y, max_pos.y)

    _spawn_prediction_circle(_current_target, max(0.05, _cooldown))

func _spawn_prediction_circle(center: Vector2, duration: float) -> void:
    _cleanup_prediction_line()
    if prediction_line_scene == null or !is_instance_valid(_main):
        return

    var line: Line2D = _main.get_node_from_pool(_prediction_line_pool_id, _main._effects)
    if !is_instance_valid(line):
        line = prediction_line_scene.instance()
        _main.add_effect(line)
        var _err = line.connect("duration_timeout", self, "fa_on_DurationTimer_timeout", [line])

    line.already_recycle = false
    var points := PoolVector2Array()
    var step: float = TAU / float(max(8, prediction_points_num))
    for i in range(max(8, prediction_points_num) + 1):
        points.append(center + Vector2.UP.rotated(i * step) * prediction_radius)

    line.points = points
    line.width_curve = null
    line.default_color = prediction_color
    line.width = prediction_width
    if line.material is ShaderMaterial:
        line.material.set_shader_param("dash_count", 24.0)
    line.draw_prediction(duration)
    _prediction_line = line

func fa_on_DurationTimer_timeout(line: Line2D) -> void:
    if !is_instance_valid(line) or line.already_recycle:
        return
    line.already_recycle = true
    line.reset()
    if _prediction_line == line:
        _prediction_line = null
    if is_instance_valid(_main):
        _main.add_node_to_pool(line, _prediction_line_pool_id)

func _cleanup_prediction_line() -> void:
    if is_instance_valid(_prediction_line):
        fa_on_DurationTimer_timeout(_prediction_line)
    _prediction_line = null

func _on_parent_died(_entity: Node, _die_args: Entity.DieArgs) -> void:
    _cleanup_prediction_line()
    _has_predicted_target = false
    _cooldown = teleport_cooldown
    _is_teleporting = false

func fa_trigger_teleport() -> void:
    _is_teleporting = true
    if !_has_predicted_target:
        _prepare_teleport_target()

    _cleanup_prediction_line()
    _has_predicted_target = false
    _cooldown = teleport_cooldown
    _parent.global_position = _current_target
    _is_teleporting = false
