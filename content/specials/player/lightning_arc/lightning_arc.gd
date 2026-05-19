extends Node2D

signal chain_finished

export var max_bounces: int = 4
export var bounce_range: float = 200.0
export var arc_width: float = 2.0
export var jaggedness: float = 12.0
export var arc_color: Color = Color(0.4, 0.7, 1.0)
export var bounce_delay: float = 0.08
export var damage_falloff: float = 0.7

var _source: Node2D
var _targets: Array = []
var _hit_targets: Array = []
var _bounce_count: int = 0
var _current_from: Vector2
var _arc_scene: PackedScene = null

func start(source: Node2D, initial_target: Node2D) -> void:
	_source = source
	_current_from = source.global_position
	_hit_targets.append(initial_target)
	_bounce_count = 0
	_create_arc(_current_from, initial_target.global_position)
	_next_bounce()

func _next_bounce() -> void:
	_bounce_count += 1
	if _bounce_count > max_bounces:
		emit_signal("chain_finished")
		return

	var timer = get_tree().create_timer(bounce_delay)
	timer.connect("timeout", self , "_do_bounce")

func _do_bounce() -> void:
	var last_target = _hit_targets.back()
	if last_target == null:
		emit_signal("chain_finished")
		return

	var next_target = _find_next_target(last_target.global_position)
	if next_target == null:
		emit_signal("chain_finished")
		return

	_hit_targets.append(next_target)
	_current_from = last_target.global_position
	_create_arc(_current_from, next_target.global_position)

	var damage_mult = pow(damage_falloff, _bounce_count - 1)
	_apply_damage(next_target, damage_mult)

	_next_bounce()

func _find_next_target(from_pos: Vector2) -> Node2D:
	var best: Node2D = null
	var best_dist: float = bounce_range

	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy in _hit_targets:
			continue
		var dist = from_pos.distance_to(enemy.global_position)
		if dist <= best_dist:
			best_dist = dist
			best = enemy
	return best

func _create_arc(from: Vector2, to: Vector2) -> void:
	var arc = _arc_scene.instance()
	arc.init(from, to, arc_color, arc_width, jaggedness)
	add_child(arc)

func _apply_damage(target: Node2D, base_damage: float, multiplier: float) -> void:
	if target.has_method("take_damage"):
		target.take_damage(base_damage * multiplier)
