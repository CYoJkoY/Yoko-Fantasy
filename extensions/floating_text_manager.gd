extends "res://visual_effects/floating_text/floating_text_manager.gd"

# ══════════════════════════════════════════ Extension ══════════════════════════════════ #
func _on_unit_took_damage(unit: Unit, value: int, knockback_direction: Vector2, is_crit: bool, is_dodge: bool, is_protected: bool, armor_did_something: bool, args: TakeDamageArgs, hit_type: int, is_one_shot: bool) -> void:
    var display_args: TakeDamageArgs = args
    if not args.has_meta("custom_color") and is_instance_valid(args.hitbox) and args.hitbox.has_meta("fantasy_damage_color"):
        display_args = Utils.ncl_create_custom_damage_args(args.from_player_index, args.hitbox.get_meta("fantasy_damage_color"), args.get_meta("custom_icon", Keys.empty_hash))
    ._on_unit_took_damage(unit, value, knockback_direction, is_crit, is_dodge, is_protected, armor_did_something, display_args, hit_type, is_one_shot)
