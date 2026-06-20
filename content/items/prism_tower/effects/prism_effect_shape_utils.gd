extends Reference

static func set_line_points(line: Line2D, from_pos: Vector2, to_pos: Vector2) -> void:
	var points: PoolVector2Array = PoolVector2Array()
	points.append(from_pos)
	points.append(to_pos)
	line.points = points

static func set_circle_points(line: Line2D, radius: float, steps: int) -> void:
	var points: PoolVector2Array = PoolVector2Array()
	for i in range(steps + 1):
		var angle: float = TAU * float(i) / float(steps)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	line.points = points

static func set_polygon_points(line: Line2D, radius: float, sides: int, angle_offset: float = -PI / 2.0) -> void:
	var points: PoolVector2Array = PoolVector2Array()
	for i in range(sides + 1):
		var angle: float = angle_offset + TAU * float(i) / float(sides)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	line.points = points
