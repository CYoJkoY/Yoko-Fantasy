extends "res://items/global/weapon_data.gd"

const SHOOTING_BEHAVIOR = preload("res://mods-unpacked/Yoko-Fantasy/content/weapons/melee/kou_b_hand/kou_b_hand_shooting_behavior.gd")


func get_weapon_stats_text(player_index: int, hide_if_non_unlock_in_codex: bool = false) -> String:
    if _is_locked_in_codex() and hide_if_non_unlock_in_codex:
        return ""
    _init_stats_args_data.sets = sets
    _init_stats_args_data.effects = effects
    var current_stats = WeaponService.init_melee_stats(stats, player_index, _init_stats_args_data)
    var duration: float = SHOOTING_BEHAVIOR.get_animation_duration(current_stats, player_index) + current_stats.cooldown / 60.0
    var base_duration: float = SHOOTING_BEHAVIOR.get_animation_duration(stats, -1, false) + stats.cooldown / 60.0
    var step: float = 0.001 if duration < 0.2 else 0.01
    var cooldown_text: String = current_stats.get_signed_col_a(-duration, -base_duration) + str(stepify(duration, step)) + "s" + current_stats.col_b
    var label: String = current_stats.get_col_a() + tr("COOLDOWN") + current_stats.col_b
    var original_line: String = Text.text("STAT_FORMATTED", [label, current_stats.get_cooldown_text(stats, player_index)])
    var replacement_line: String = Text.text("STAT_FORMATTED", [label, cooldown_text])
    return current_stats.get_text(stats, player_index, effects).replace(original_line, replacement_line)
