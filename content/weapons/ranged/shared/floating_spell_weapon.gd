extends "res://weapons/ranged/ranged_weapon.gd"

var _float_time: float = 0.0
var _float_phase: float = 0.0

onready var _base_book_offset: Vector2 = sprite.offset
onready var _base_book_rotation: float = sprite.rotation
onready var _base_book_muzzle: Vector2 = muzzle.position


func _ready() -> void:
    _float_phase = float(weapon_pos) * 2.399963 + float(player_index) * 0.7


func _process(delta: float) -> void:
    _float_time = fmod(_float_time + delta, TAU * 10.0)
    var lift_phase: float = _float_time * 2.2 + _float_phase
    var sway_phase: float = _float_time * 1.3 + _float_phase
    var drift: Vector2 = Vector2(
        sin(sway_phase) * 1.5,
        sin(lift_phase) * 4.5 + sin(lift_phase * 2.0 + 0.6) * 0.8
    )
    sprite.rotation = _base_book_rotation + sin(sway_phase + 0.8) * 0.055 + sin(lift_phase) * 0.012
    var local_drift: Vector2 = drift.rotated(-sprite.global_rotation)
    sprite.offset = _base_book_offset + local_drift
    muzzle.position = _base_book_muzzle + local_drift
