extends Node2D

const FlyingBladeMotion = preload("res://mods-unpacked/Yoko-Fantasy/content/entities/pets/flying_blade/motion_math.gd")
const TEXTURE_SLASH_CRESCENT = preload("res://mods-unpacked/Yoko-Fantasy/content/entities/pets/flying_blade/visuals/textures/slash_arc_rift.webp")
const TEXTURE_STAR_GLINT = preload("res://mods-unpacked/Yoko-Fantasy/content/entities/pets/flying_blade/visuals/textures/star_glint_4pt.webp")

const SEGMENTS = 12

var _left_side: Array = []
var _right_side: Array = []
var _u_left: Array = []
var _u_right: Array = []
var _ribbon_mesh: ArrayMesh = ArrayMesh.new()
var _ribbon_color: Color = Color.white

var _tip_position: Vector2 = Vector2.ZERO
var _tip_rotation: float = 0.0
var _tip_scale: Vector2 = Vector2.ZERO
var _tip_color: Color = Color.white

var _quality: int = 0
var _visible_alpha: float = 0.0
var _base_color: Color = Color(0.75, 0.35, 1.0, 0.8)
var _material: CanvasItemMaterial = null

var is_world_entity: bool = false
var _age: float = 0.0
var _lifetime: float = 0.18
var _start_world: Vector2 = Vector2.ZERO
var _control_world: Vector2 = Vector2.ZERO
var _end_world: Vector2 = Vector2.ZERO
var _dir_world: Vector2 = Vector2.RIGHT
var _curve_side_world: float = 1.0
var _slash_width_world: float = 22.0

func _init() -> void:
	_material = CanvasItemMaterial.new()
	_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = _material

func ignite_world_rift(start_pos: Vector2, control_pos: Vector2, end_pos: Vector2, direction: Vector2, curve_side: float, slash_width: float, slash_color: Color, p_lifetime: float = 0.18) -> void:
	is_world_entity = true
	set_as_toplevel(true)
	global_position = Vector2.ZERO
	rotation = 0.0
	scale = Vector2.ONE
	_start_world = start_pos
	_control_world = control_pos
	_end_world = end_pos
	_dir_world = direction if direction.length_squared() > 0.1 else Vector2.RIGHT
	_curve_side_world = curve_side
	_slash_width_world = max(10.0, slash_width)
	_base_color = slash_color
	_lifetime = max(0.04, p_lifetime)
	_age = 0.0
	_visible_alpha = 1.0
	visible = true
	_render_rift_mesh(0.0)

func tick(delta: float) -> bool:
	if !visible:
		return false
	_age += delta
	var progress: float = _age / _lifetime
	if progress >= 1.0:
		hide_visual()
		return false
	_render_rift_mesh(progress)
	return true

func _render_rift_mesh(progress: float) -> void:
	var ease_prog: float = FlyingBladeMotion.ease_out_cubic(clamp(progress, 0.0, 1.0))
	var head_pct: float = clamp(0.25 + ease_prog * 0.75, 0.20, 1.0)
	var tail_pct: float = clamp(head_pct - (0.48 + ease_prog * 0.22), 0.0, 0.75)
	_visible_alpha = (1.0 - progress) * (1.0 - progress)
	var dynamic_width: float = _slash_width_world * (1.0 + ease_prog * 0.35)
	var col: Color = Color(_base_color.r * 1.3, _base_color.g * 1.15, _base_color.b * 1.45, min(0.90, _base_color.a * 1.4 * _visible_alpha))
	var tip_color: Color = Color(1.0, 0.95, 1.2, min(0.95, _base_color.a * 1.8 * _visible_alpha))
	_build_mesh(_start_world, _control_world, _end_world, _dir_world, _curve_side_world, head_pct, tail_pct, dynamic_width, 0.22, 0.10, col, tip_color)

func configure(start: Vector2, control: Vector2, end: Vector2, fallback_direction: Vector2, curve_side: float, progress: float, windup: bool, visibility: float, slash_width: float, slash_color: Color, ticks: float, phase: float, quality: int = 0) -> void:
	if is_world_entity:
		return
	_quality = quality
	_base_color = slash_color
	_visible_alpha = visibility

	var head_pct: float = clamp(0.20 + progress * 0.88, 0.15, 1.0)
	var tail_pct: float = clamp(head_pct - (0.45 + progress * 0.15), 0.0, 0.80)
	if windup:
		head_pct = 0.42
		tail_pct = 0.06

	var flash: float = 0.90 + sin(phase * 8.0 + ticks * 1.8) * 0.10
	var dynamic_width: float = slash_width * 1.2
	var col: Color = Color(slash_color.r * 1.25, slash_color.g * 1.15, slash_color.b * 1.35, min(0.85, slash_color.a * 1.45 * visibility * flash))
	var tip_color: Color = Color(1.0, 0.95, 1.2, min(0.9, slash_color.a * 1.8 * visibility * flash))
	_build_mesh(start, control, end, fallback_direction, curve_side, head_pct, tail_pct, dynamic_width, 0.20, 0.15, col, tip_color)

func _build_mesh(start: Vector2, control: Vector2, end: Vector2, fallback_direction: Vector2, curve_side: float, head_pct: float, tail_pct: float, dynamic_width: float, width_base: float, tip_offset: float, polygon_color: Color, tip_color: Color) -> void:
	_reset_work_arrays()

	for i in range(SEGMENTS):
		var local_pct: float = float(i) / float(max(SEGMENTS - 1, 1))
		var path_pct: float = lerp(tail_pct, head_pct, local_pct)
		var point: Vector2 = FlyingBladeMotion.bezier2(start, control, end, path_pct)
		var tangent: Vector2 = FlyingBladeMotion.bezier2_tangent(start, control, end, path_pct)
		if tangent.length_squared() <= 0.1:
			tangent = fallback_direction
		if tangent.length_squared() <= 0.1:
			tangent = Vector2.RIGHT
		tangent = tangent.normalized()
		var side: Vector2 = Vector2(-tangent.y, tangent.x) * curve_side

		var head_weight: float = FlyingBladeMotion.ease_out_cubic(local_pct)
		var tail_weight: float = clamp(local_pct * 3.5, 0.0, 1.0)
		var tip_fade: float = clamp((1.05 - local_pct) * 3.2, 0.0, 1.0)
		var mass: float = tail_weight * tip_fade * (0.35 + head_weight * 0.85)

		var half_w: float = dynamic_width * (width_base + mass * 1.15)
		var forward_bias: Vector2 = tangent * (head_weight - 0.4) * dynamic_width * 0.15
		var center: Vector2 = point + forward_bias

		var p_left: Vector2 = center + side * half_w
		var p_right: Vector2 = center - side * (half_w * 0.65)

		_left_side.append(p_left)
		_right_side.append(p_right)
		_u_left.append(Vector2(local_pct, 0.0))
		_u_right.append(Vector2(local_pct, 1.0))

		if i == SEGMENTS - 1:
			_tip_position = center + side * half_w * tip_offset
			_tip_rotation = tangent.angle()
			_tip_scale = Vector2(dynamic_width * 0.05, dynamic_width * 0.05) * (0.8 + head_weight * 0.4)

	_ribbon_color = polygon_color
	_tip_color = tip_color
	_rebuild_ribbon_mesh()
	visible = _ribbon_mesh.get_surface_count() > 0 and _visible_alpha > 0.02
	update()

func _rebuild_ribbon_mesh() -> void:
	_ribbon_mesh.clear_surfaces()
	var vertices: PoolVector3Array = PoolVector3Array()
	var uvs: PoolVector2Array = PoolVector2Array()
	var indices: PoolIntArray = PoolIntArray()
	vertices.resize(_left_side.size() * 2)
	uvs.resize(_left_side.size() * 2)
	for i in range(_left_side.size()):
		vertices[i * 2] = Vector3(_left_side[i].x, _left_side[i].y, 0.0)
		vertices[i * 2 + 1] = Vector3(_right_side[i].x, _right_side[i].y, 0.0)
		uvs[i * 2] = _u_left[i]
		uvs[i * 2 + 1] = _u_right[i]
	for i in range(_left_side.size() - 1):
		var left_a: int = i * 2
		var right_a: int = left_a + 1
		var left_b: int = left_a + 2
		var right_b: int = left_a + 3
		if _triangle_has_area(_left_side[i], _right_side[i], _left_side[i + 1]):
			indices.append(left_a)
			indices.append(right_a)
			indices.append(left_b)
		if _triangle_has_area(_left_side[i + 1], _right_side[i], _right_side[i + 1]):
			indices.append(left_b)
			indices.append(right_a)
			indices.append(right_b)
	if indices.empty():
		return
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	_ribbon_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

func _triangle_has_area(a: Vector2, b: Vector2, c: Vector2) -> bool:
	return abs((b - a).cross(c - a)) > 0.01

func hide_visual() -> void:
	visible = false
	_visible_alpha = 0.0

func _reset_work_arrays() -> void:
	_left_side.clear()
	_right_side.clear()
	_u_left.clear()
	_u_right.clear()

func _draw() -> void:
	if !visible or _ribbon_mesh.get_surface_count() == 0 or _visible_alpha <= 0.0:
		return

	draw_mesh(_ribbon_mesh, TEXTURE_SLASH_CRESCENT, null, Transform2D.IDENTITY, _ribbon_color)

	if _quality == 0 and _tip_color.a > 0.05:
		var glint_size: Vector2 = Vector2(32.0, 32.0) * _tip_scale
		var rect: Rect2 = Rect2(-glint_size * 0.5, glint_size)
		draw_set_transform(_tip_position, _tip_rotation, Vector2.ONE)
		draw_texture_rect(TEXTURE_STAR_GLINT, rect, false, _tip_color)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
