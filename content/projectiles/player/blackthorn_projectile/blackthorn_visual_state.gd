extends Reference

const META_KEY: String = "fantasy_blackthorn_visual_state"
const MAIN_IMPACTS_PER_WINDOW: int = 8
const SHARD_IMPACTS_PER_WINDOW: int = 16

var _frame: int = -1
var _impact_window: int = -1
var _impact_cells: Dictionary = {}
var _main_impacts: int = 0
var _shard_impacts: int = 0
var opacity: float = 1.0


func refresh() -> void:
    var frame: int = Engine.get_physics_frames()
    if frame != _frame:
        _frame = frame
        opacity = FantasyProjectileVisualUtils.get_opacity()


func allow_impact(at: Vector2, is_shard: bool) -> bool:
    refresh()
    if opacity <= 0.0:
        return false
    var window: int = int(_frame / 3)
    if window != _impact_window:
        _impact_window = window
        _impact_cells.clear()
        _main_impacts = 0
        _shard_impacts = 0
    if is_shard and _shard_impacts >= SHARD_IMPACTS_PER_WINDOW:
        return false
    if not is_shard and _main_impacts >= MAIN_IMPACTS_PER_WINDOW:
        return false
    var cell: Vector3 = Vector3(floor(at.x / 64.0), floor(at.y / 64.0), 1.0 if is_shard else 0.0)
    if _impact_cells.has(cell):
        return false
    _impact_cells[cell] = true
    if is_shard:
        _shard_impacts += 1
    else:
        _main_impacts += 1
    return true
