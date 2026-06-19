extends Enemy

const VisualPartsSync = preload("res://mods-unpacked/Yoko-Fantasy/content/entities/visual_parts_sync.gd")

onready var _parts_offset: Node2D = $Animation/Offset
var _visual_parts_sync = VisualPartsSync.new()

func _ready() -> void:
	_visual_parts_sync.setup(_parts_offset)
	_visual_parts_sync.sync(sprite.material)

func free_entity() -> void:
	.free_entity()
	_visual_parts_sync.sync(sprite.material)

func update_animation(movement: Vector2) -> void:
	.update_animation(movement)
	_parts_offset.scale.x = sprite.scale.x

func flash() -> void:
	.flash()
	_visual_parts_sync.sync(sprite.material)

func _on_FlashTimer_timeout() -> void:
	._on_FlashTimer_timeout()
	_visual_parts_sync.sync(sprite.material)

func _set_outlines(alpha: float = 1.0, desaturation: float = 0.0) -> void:
	._set_outlines(alpha, desaturation)
	_visual_parts_sync.sync(sprite.material)
