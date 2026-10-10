extends "res://weapons/ranged/ranged_weapon.gd"

onready var _strings: Sprite = $Sprite/Strings


func update_sprite_flipv() -> void:
    .update_sprite_flipv()
    _strings.flip_v = sprite.flip_v
