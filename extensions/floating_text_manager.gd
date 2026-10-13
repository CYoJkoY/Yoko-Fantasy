extends "res://visual_effects/floating_text/floating_text_manager.gd"

const EROSION_TEXT_MATERIAL = preload("res://mods-unpacked/Yoko-Fantasy/content/visual_effects/erosion_damage_text.tres")

var _fantasy_erosion_text_pending: bool = false

# ══════════════════════════════════════════ Extension ══════════════════════════════════ #
func _on_unit_took_damage(unit: Unit, value: int, knockback_direction: Vector2, is_crit: bool, is_dodge: bool, is_protected: bool, armor_did_something: bool, args: TakeDamageArgs, hit_type: int, is_one_shot: bool) -> void:
    var display_args: TakeDamageArgs = args
    if not args.has_meta("custom_color") and is_instance_valid(args.hitbox) and args.hitbox.has_meta("fantasy_damage_color"):
        display_args = Utils.ncl_create_custom_damage_args(args.from_player_index, args.hitbox.get_meta("fantasy_damage_color"), args.get_meta("custom_icon", Keys.empty_hash))
    var previous_erosion_text_pending: bool = _fantasy_erosion_text_pending
    _fantasy_erosion_text_pending = args.has_meta("fantasy_erosion_gradient")
    ._on_unit_took_damage(unit, value, knockback_direction, is_crit, is_dodge, is_protected, armor_did_something, display_args, hit_type, is_one_shot)
    _fantasy_erosion_text_pending = previous_erosion_text_pending

func get_floating_text() -> FloatingText:
    var is_erosion_text: bool = _fantasy_erosion_text_pending
    _fantasy_erosion_text_pending = false
    var instance: FloatingText = .get_floating_text()
    if is_erosion_text:
        instance.material = EROSION_TEXT_MATERIAL
    return instance

func on_floating_text_available(instance: FloatingText) -> void:
    if instance.material == EROSION_TEXT_MATERIAL:
        instance.material = null
    .on_floating_text_available(instance)
