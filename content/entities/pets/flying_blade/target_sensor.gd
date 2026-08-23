extends Node2D

var _targets_in_range: Array = []
var _area: Area2D = null
var _collision: CollisionShape2D = null
var _shape: CircleShape2D = null

func setup(mask: int = Utils.ENEMIES_BIT) -> void:
    _area = Area2D.new()
    _area.name = "Range"
    _area.collision_layer = 0
    _area.collision_mask = mask
    add_child(_area)

    _collision = CollisionShape2D.new()
    _collision.name = "Collision"
    _shape = CircleShape2D.new()
    _collision.shape = _shape
    _area.add_child(_collision)

    _area.connect("body_entered", self, "_on_body_entered")
    _area.connect("body_exited", self, "_on_body_exited")

func set_radius(radius: float) -> void:
    if abs(_shape.radius - radius) <= 0.1:
        return
    _shape.radius = radius

func clear_targets() -> void:
    for target in _targets_in_range:
        _disconnect_target(target)
    _targets_in_range.clear()

func get_targets() -> Array:
    _prune_targets()
    return _targets_in_range

func shutdown() -> void:
    clear_targets()
    queue_free()

func _prune_targets() -> void:
    for i in range(_targets_in_range.size() - 1, -1, -1):
        if !_is_target_valid(_targets_in_range[i]):
            _disconnect_target(_targets_in_range[i])
            _targets_in_range.remove(i)

func _is_target_valid(target: Node) -> bool:
    if !is_instance_valid(target):
        return false
    if not (target is Node2D):
        return false
    return !target.dead

func _disconnect_target(target: Node) -> void:
    if !is_instance_valid(target):
        return
    if target.is_connected("died", self, "_on_target_died"):
        target.disconnect("died", self, "_on_target_died")

func _on_body_entered(body: Node) -> void:
    _targets_in_range.push_back(body)
    if !body.is_connected("died", self, "_on_target_died"):
        body.connect("died", self, "_on_target_died")

func _on_body_exited(body: Node) -> void:
    _targets_in_range.erase(body)
    _disconnect_target(body)

func _on_target_died(target: Node2D, _args: Entity.DieArgs) -> void:
    _disconnect_target(target)
    _targets_in_range.erase(target)
