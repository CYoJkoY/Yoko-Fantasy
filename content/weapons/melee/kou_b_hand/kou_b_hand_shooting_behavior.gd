extends "res://weapons/shooting_behaviors/weapon_shooting_behavior.gd"

const FRAMES = [
    preload("res://mods-unpacked/Yoko-Fantasy/content/weapons/melee/kou_b_hand/kou_b_hand_01.webp"),
    preload("res://mods-unpacked/Yoko-Fantasy/content/weapons/melee/kou_b_hand/kou_b_hand_02.webp"),
    preload("res://mods-unpacked/Yoko-Fantasy/content/weapons/melee/kou_b_hand/kou_b_hand_03.webp")
]

const FRAME_SEQUENCE = [0, 1, 2, 1, 0]
const FRAME_TIMES = [0.0, 0.2, 0.45, 0.7, 1.0]

const WRIST_PIVOT: Vector2 = Vector2(-35.0, 0.0)
const LIFT_ANGLE: float = 19.0 * PI / 180.0

var _rest_position: Vector2
var _rest_rotation: float
var _swing_sign: float = -1.0
var _frame_index: int = -1


func init(parent: Node) -> Node:
    .init(parent)
    _rest_position = _parent.sprite.position
    _rest_rotation = _parent.sprite.rotation
    return self


func update_attack_pose(progress: float) -> void:
    var frame_index: int = 0
    while frame_index < FRAME_TIMES.size() - 1 and progress >= FRAME_TIMES[frame_index + 1]:
        frame_index += 1
    if frame_index != _frame_index:
        _frame_index = frame_index
        _parent.update_sprite(FRAMES[FRAME_SEQUENCE[frame_index]])
    var lift: float = progress / 0.45 if progress <= 0.45 else (1.0 - progress) / 0.55
    lift = lift * lift * (3.0 - 2.0 * lift)
    var angle: float = _rest_rotation + _swing_sign * LIFT_ANGLE * lift
    var wrist_position: Vector2 = _rest_position + WRIST_PIVOT.rotated(_rest_rotation)
    _parent.sprite.rotation = angle
    _parent.sprite.position = wrist_position - WRIST_PIVOT.rotated(angle)


func finish_attack_pose() -> void:
    _parent.update_sprite(FRAMES[0])
    _parent.sprite.position = _rest_position
    _parent.sprite.rotation = _rest_rotation
    _frame_index = -1


static func get_animation_duration(from_stats: Resource, player_index: int, use_global_stats: bool = true) -> float:
    var shooting_data = MeleeShootingData.new(from_stats, player_index, use_global_stats)
    return shooting_data.get_shooting_total_duration() * 0.25


func shoot(_distance: float) -> void:
    var duration: float = get_animation_duration(_parent.current_stats, _parent.player_index)
    _parent.set_shooting(true)
    _parent.disable_hitbox()
    _parent._hitbox.player_attack_id = _get_next_attack_id()
    _swing_sign = 1.0 if cos(_parent.global_rotation) < 0.0 else -1.0
    _frame_index = -1
    update_attack_pose(0.0)
    _parent.tween.interpolate_method(self, "update_attack_pose", 0.0, 1.0, duration, Tween.TRANS_LINEAR)
    _parent.tween.interpolate_callback(_parent, duration * 0.45, "strike")
    _parent.tween.interpolate_callback(self, duration, "finish_attack_pose")
    _parent.tween.interpolate_callback(_parent, duration, "set_shooting", false)
    _parent.tween.start()
