extends "res://weapons/melee/melee_weapon.gd"

# =========================== Extension =========================== #
func shoot() -> void:
    .shoot()
    _fantasy_try_skip_cooldown_after_shoot()

func on_killed_something(_thing_killed: Node, hitbox: Hitbox) -> void:
    .on_killed_something(_thing_killed, hitbox)
    _fantasy_gain_temp_stat_every_killed_enemies()

# =========================== Custom =========================== #
func _fantasy_gain_temp_stat_every_killed_enemies() -> void:
    for effect in effects:
        if effect.get_id() != "fantasy_gain_temp_stat_every_killed_enemies" or \
        _enemies_killed_this_wave_count % effect.value != 0: continue

        TempStats.add_stat(effect.stat_hash, effect.stat_nb, player_index)

        # Update when first add hit_protection
        if effect.stat_hash == Keys.hit_protection_hash:
            _parent._hit_protection += effect.stat_nb

func _fantasy_try_skip_cooldown_after_shoot() -> void:
    var chance: int = int(RunData.get_player_effect(Utils.fantasy_job_dual_blade_skip_cooldown_chance_hash, player_index))
    if chance <= 0:
        return
    if !Utils.get_chance_success(chance / 100.0):
        return

    _current_cooldown = 0
    tween_animation.interpolate_property(
        sprite, "self_modulate",
        Color("#3E68DA"), Color.white, 0.48,
        Tween.TRANS_SINE, Tween.EASE_IN_OUT
    )
    tween_animation.start()
