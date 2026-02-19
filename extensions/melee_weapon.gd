extends "res://weapons/melee/melee_weapon.gd"

# =========================== Extension =========================== #
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
