extends "res://weapons/melee/melee_weapon.gd"

# =========================== Extension =========================== #
func _ready() -> void:
    _fantasy_cannot_damage_tree()

func shoot() -> void:
    .shoot()
    _fantasy_reload_when_shoot()

func on_killed_something(_thing_killed: Node, hitbox: Hitbox) -> void:
    .on_killed_something(_thing_killed, hitbox)
    _fantasy_gain_stat_every_killed_enemies()
    _fantasy_change_weapon_every_killed_enemies()

func _on_Range_body_entered(body: Node) -> void:
    if RunData.get_player_effect_bool(Utils.fantasy_cannot_damage_tree_hash, _parent.player_index) and Utils.plant_enemies_ids.has(body.get("enemy_id_hash")): return
    ._on_Range_body_entered(body)

func _on_Range_body_exited(body: Node) -> void:
    if RunData.get_player_effect_bool(Utils.fantasy_cannot_damage_tree_hash, _parent.player_index) and Utils.plant_enemies_ids.has(body.get("enemy_id_hash")): return
    ._on_Range_body_exited(body)

# =========================== Custom =========================== #
func _fantasy_cannot_damage_tree() -> void:
    if !RunData.get_player_effect_bool(Utils.fantasy_cannot_damage_tree_hash, _parent.player_index): return

    _range.collision_mask -= Utils.NEUTRAL_BIT
    return

func _fantasy_gain_stat_every_killed_enemies() -> void:
    for effect in effects:
        if effect.get_id() != "fantasy_gain_stat_every_killed_enemies" or \
        _enemies_killed_this_wave_count % effect.value != 0: continue

        if effect.is_temp: TempStats.add_stat(effect.stat_hash, effect.stat_nb, player_index)
        else: RunData.add_stat(effect.stat_hash, effect.stat_nb, player_index)

        # Update when first add hit_protection
        if effect.stat_hash == Keys.hit_protection_hash:
            _parent._hit_protection += effect.stat_nb

func _fantasy_reload_when_shoot() -> void:
    var effect_items: Array = RunData.get_player_effect(Utils.fantasy_reload_when_shoot_hash, player_index)

    for effect_item in effect_items:
        var chance: float = effect_item[1] / 100.0

        if !Utils.get_chance_success(chance): continue

        var tracking_key_hash: int = effect_item[0]
        RunData.ncl_add_effect_tracking_value(tracking_key_hash, 1, player_index)

        _current_cooldown = 0
        tween_animation.interpolate_property(
            sprite, "self_modulate",
            Color("#3E68DA"), Color.white, 0.48,
            Tween.TRANS_SINE, Tween.EASE_IN_OUT
        )
        tween_animation.start()

func _fantasy_change_weapon_every_killed_enemies() -> void:
    for effect in effects:
        if effect.get_id() != "fantasy_change_weapon_every_killed_enemies" or \
        _enemies_killed_this_wave_count != effect.value: continue

        Utils.ncl_change_weapon_within_run(weapon_pos, effect.key_hash, player_index)
