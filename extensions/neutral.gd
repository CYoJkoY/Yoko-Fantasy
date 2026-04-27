extends "res://entities/units/neutral/neutral.gd"

# =========================== Extension =========================== #
func _on_Hurtbox_area_entered(hitbox: Area2D) -> void:
    _fantasy_cannot_damage_tree(hitbox)
    ._on_Hurtbox_area_entered(hitbox)

# =========================== Custom =========================== #
func _fantasy_cannot_damage_tree(hitbox: Area2D) -> void:
    if !is_instance_valid(hitbox) or \
    !is_instance_valid(hitbox.from) or \
    hitbox.from.player_index == -1 or \
    hitbox.from.player_index == RunData.DUMMY_PLAYER_INDEX: return

    var player_index: int = hitbox.from.player_index
    if RunData.get_player_effect_bool(Utils.fantasy_cannot_damage_tree_hash, player_index): hitbox.ignored_objects.append(self )
