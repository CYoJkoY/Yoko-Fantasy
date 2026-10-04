extends Reference

const CELL_SIZE: float = 256.0
const META_KEY: String = "fantasy_projectile_target_index"
var _frame: int = -1
var _cells: Dictionary = {}
var _enemies: Array = []


func candidates(main: Node, center: Vector2, radius: float) -> Array:
    var frame: int = Engine.get_physics_frames()
    if _frame != frame:
        _frame = frame
        _cells.clear()
        _enemies.clear()
        for enemy in main._entity_spawner.get_all_enemies(false):
            if not is_instance_valid(enemy) or not (enemy is Enemy) or enemy.dead:
                continue
            _enemies.append(enemy)
            var cell: Vector2 = (enemy.global_position / CELL_SIZE).floor()
            if not _cells.has(cell):
                _cells[cell] = []
            _cells[cell].append(enemy)
    var low: Vector2 = ((center - Vector2.ONE * radius) / CELL_SIZE).floor() - Vector2.ONE
    var high: Vector2 = ((center + Vector2.ONE * radius) / CELL_SIZE).floor() + Vector2.ONE
    if (high.x - low.x + 1) * (high.y - low.y + 1) >= _enemies.size():
        return _enemies
    var result: Array = []
    for x in range(int(low.x), int(high.x) + 1):
        for y in range(int(low.y), int(high.y) + 1):
            var cell := Vector2(x, y)
            if _cells.has(cell):
                result.append_array(_cells[cell])
    return result
