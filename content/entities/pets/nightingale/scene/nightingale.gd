extends "res://mods-unpacked/Yoko-Fantasy/content/entities/pets/wandering_ranged_pet.gd"

# =========================== Extension =========================== #
func _physics_process(_delta: float) -> void:
    _angle = wrapf(_angle, 0.0, 2.0 * PI)
    sprite.flip_h = _angle > 0.0 and _angle < PI

# =========================== Custom =========================== #
func _fantasy_nightingale_boost_speed() -> void:
    rotation_speed *= 2.5

func _fantasy_nightingale_reduce_speed() -> void:
    rotation_speed /= 2.5
