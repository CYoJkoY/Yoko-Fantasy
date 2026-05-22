extends "res://weapons/ranged/ranged_weapon.gd"

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

func on_weapon_hit_something(thing_hit: Node, damage_dealt: int, hitbox: Hitbox) -> void:
    .on_weapon_hit_something(thing_hit, damage_dealt, hitbox)
    _fantasy_lightning_chain_on_hit(thing_hit)

func _on_weapon_critically_hit_something(_thing_hit, _damage_dealt) -> void:
    ._on_weapon_critically_hit_something(_thing_hit, _damage_dealt)
    _fantasy_reload_when_critically_hit()

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

func _fantasy_reload_when_critically_hit() -> void:
    for effect in effects:
        if effect.custom_key_hash != Utils.fantasy_reload_when_critically_hit_hash: continue

        var chance: float = effect.value / 100.0

        if !Utils.get_chance_success(chance): continue

        _current_cooldown = 0
        tween_animation.interpolate_property(
            sprite, "self_modulate",
            Color("#3E68DA"), Color.white, 0.48,
            Tween.TRANS_SINE, Tween.EASE_IN_OUT, 0.64
        )

func _fantasy_lightning_chain_on_hit(thing_hit: Node) -> void:
    for effect in effects:
        if effect.get_id() != "fantasy_lightning_chain_on_hit": continue

        if !Utils.get_chance_success(effect.base_chance): continue

        var damage: int = Utils.ncl_get_dmg_with_scaling_stats(effect.value, effect.damage_scaling_stats, player_index)
        var chain_targets: int = Utils.ncl_get_dmg_with_scaling_stats(effect.base_chain_targets, effect.targets_scaling_stats, player_index)
        var final_damage: int = round(damage * effect.chain_damage_mult) as int
        var arc_pool_id: int = Keys.generate_hash(effect.arc_scene.resource_path)
        var main: Main = Utils.get_scene_node()
        var arc: Node = main.get_node_from_pool(arc_pool_id, main._effects)

        if !is_instance_valid(arc):
            arc = effect.arc_scene.instance()
            main.add_effect(arc)
            arc.set_meta("pool_id", arc_pool_id)
        
        var chain_enemies: Array = [thing_hit]
        var all_enemies: Array = main._entity_spawner.get_all_enemies(false)
        var available: Array = all_enemies.duplicate()
        available.erase(thing_hit)

        var current_pos: Vector2 = thing_hit.global_position
        for _i in range(chain_targets):
            var next_target = Utils.get_nearest_no_max_no_dist(available, current_pos)
            if next_target == null or !is_instance_valid(next_target) or next_target.dead: break

            chain_enemies.append(next_target)
            current_pos = next_target.global_position
            available.erase(next_target)

        var arc_damage: int = arc.link(
            chain_enemies,
            final_damage,
            effect.chain_damage_mult,
            player_index,
            effect.arc_width,
            effect.arc_jaggedness,
            effect.arc_color,
            effect.arc_glow_color,
            effect.arc_duration,
            effect.arc_crit_chance,
            effect.arc_crit_damage,
            effects,
            effect.damage_scaling_stats
        )

        RunData.add_weapon_dmg_dealt(weapon_pos, arc_damage, _parent.player_index)

    var effect_items: Array = RunData.get_player_effect(Utils.fantasy_lightning_chain_on_hit_hash, player_index)
    for effect_item in effect_items:
        var chance: float = effect_item[0]
        var base_damage: int = effect_item[1]
        var damage_scaling_stats: Array = effect_item[2]
        var base_chain_targets: int = effect_item[3]
        var targets_scaling_stats: Array = effect_item[4]
        var chain_damage_mult: float = effect_item[5]
        var arc_width: float = effect_item[6]
        var arc_jaggedness: float = effect_item[7]
        var arc_color: Color = Color(effect_item[8])
        var arc_glow_color: Color = Color(effect_item[9])
        var arc_duration: float = effect_item[10]
        var arc_crit_chance: float = effect_item[11]
        var arc_crit_damage: float = effect_item[12]
        var arc_scene_path: String = effect_item[13]

        if !Utils.get_chance_success(chance): continue

        var damage: int = Utils.ncl_get_dmg_with_scaling_stats(base_damage, damage_scaling_stats, player_index)
        var chain_targets: int = Utils.ncl_get_dmg_with_scaling_stats(base_chain_targets, targets_scaling_stats, player_index)
        var arc_pool_id: int = Keys.generate_hash(arc_scene_path)
        var main: Main = Utils.get_scene_node()
        var arc: Node = main.get_node_from_pool(arc_pool_id, main._effects)

        if !is_instance_valid(arc):
            arc = load(arc_scene_path).instance()
            main.add_effect(arc)
            arc.set_meta("pool_id", arc_pool_id)

        var chain_enemies: Array = [thing_hit]
        var all_enemies: Array = main._entity_spawner.get_all_enemies(false)
        var available: Array = all_enemies.duplicate()
        available.erase(thing_hit)

        var current_pos: Vector2 = thing_hit.global_position
        for _i in range(chain_targets):
            var next_target = Utils.get_nearest_no_max_no_dist(available, current_pos)
            if next_target == null or !is_instance_valid(next_target) or next_target.dead: break

            chain_enemies.append(next_target)
            current_pos = next_target.global_position
            available.erase(next_target)

        var arc_damage: int = arc.link(
            chain_enemies,
            damage,
            chain_damage_mult,
            player_index,
            arc_width,
            arc_jaggedness,
            arc_color,
            arc_glow_color,
            arc_duration,
            arc_crit_chance,
            arc_crit_damage,
            effects,
            damage_scaling_stats
        )

        RunData.add_weapon_dmg_dealt(weapon_pos, arc_damage, _parent.player_index)
