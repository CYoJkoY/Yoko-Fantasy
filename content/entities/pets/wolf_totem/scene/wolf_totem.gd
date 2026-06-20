extends "res://mods-unpacked/Yoko-Fantasy/content/entities/pets/tactical_global_pet.gd"

const VisualPartsSync = preload("res://mods-unpacked/Yoko-Fantasy/content/entities/visual_parts_sync.gd")

onready var _parts_offset: Node2D = $Animation/Offset
var _visual_parts_sync = VisualPartsSync.new()

func _ready() -> void:
	_visual_parts_sync.setup_from(_parts_offset, sprite)

func update_animation(movement: Vector2) -> void:
	.update_animation(movement)
	_parts_offset.scale.x = sprite.scale.x

func _set_outlines(alpha: float = 1.0, desaturation: float = 0.0) -> void:
	._set_outlines(alpha, desaturation)
	_visual_parts_sync.sync_from(sprite)
