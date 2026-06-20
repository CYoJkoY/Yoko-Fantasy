extends "res://mods-unpacked/Yoko-Fantasy/content/entities/pets/wandering_ranged_pet.gd"

const VisualPartsSync = preload("res://mods-unpacked/Yoko-Fantasy/content/entities/visual_parts_sync.gd")

onready var _parts_offset: Node2D = $Animation/Offset
var _visual_parts_sync = VisualPartsSync.new()

# =========================== Extension =========================== #
func _ready() -> void:
    _visual_parts_sync.setup_from(_parts_offset, sprite)

func _physics_process(_delta: float) -> void:
    _angle = wrapf(_angle, 0.0, 2.0 * PI)
    sprite.flip_h = _angle > 0.0 and _angle < PI
    _parts_offset.scale.x = -1 if sprite.flip_h else 1

func _set_outlines(alpha: float = 1.0, desaturation: float = 0.0) -> void:
    ._set_outlines(alpha, desaturation)
    _visual_parts_sync.sync_from(sprite)
