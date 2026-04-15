extends "res://entities/structures/turret/wandering_bot/wandering_bot.gd"

# =========================== Extension =========================== #
func _ready() -> void:
    set_meta("can_pursue", false)
