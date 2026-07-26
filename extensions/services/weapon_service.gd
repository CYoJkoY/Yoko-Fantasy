extends "res://singletons/weapon_service.gd"

const LightningChainService = preload("res://mods-unpacked/Yoko-Fantasy/extensions/services/lightning_chain_service.gd")

# =========================== Extension =========================== #
func init_base_stats(from_stats: WeaponStats, player_index: int, args: WeaponServiceInitStatsArgs = _init_stats_args_service, is_structure := false, is_special_spawn := false, is_pet := false) -> WeaponStats:
    var base_stats: WeaponStats =.init_base_stats(from_stats, player_index, args, is_structure, is_special_spawn, is_pet)
    base_stats.crit_damage = _fantasy_add_crit_damage(base_stats.crit_damage, player_index)
    base_stats.crit_damage = _fantasy_crit_overflow(base_stats.crit_chance, base_stats.crit_damage, player_index)
    return base_stats

func init_structure_stats(from_stats: RangedWeaponStats, player_index: int, args: WeaponServiceInitStatsArgs = _init_stats_args_service) -> RangedWeaponStats:
    var structure_stats: RangedWeaponStats =.init_structure_stats(from_stats, player_index, args)
    structure_stats.scaling_stats = _fantasy_apply_structure_scaling_stat_effects(structure_stats.scaling_stats, player_index)
    return structure_stats

func init_melee_pet_stats(from_stats: MeleeWeaponStats, player_index: int, args := WeaponServiceInitStatsArgs.new()) -> MeleeWeaponStats:
    var melee_pet_stats: MeleeWeaponStats =.init_melee_pet_stats(from_stats, player_index, args)
    melee_pet_stats.cooldown = apply_attack_speed_mod_to_cooldown(melee_pet_stats.cooldown, Utils.get_stat(Utils.stat_fantasy_pet_attack_speed_hash, player_index) / 100.0)
    return melee_pet_stats

func init_ranged_pet_stats(from_stats: RangedWeaponStats, player_index: int, is_special_spawn := false, args := WeaponServiceInitStatsArgs.new()) -> RangedWeaponStats:
    var ranged_pet_stats: RangedWeaponStats =.init_ranged_pet_stats(from_stats, player_index, is_special_spawn, args)
    ranged_pet_stats.cooldown = apply_attack_speed_mod_to_cooldown(ranged_pet_stats.cooldown, Utils.get_stat(Utils.stat_fantasy_pet_attack_speed_hash, player_index) / 100.0)
    return ranged_pet_stats

func init_structure_pet_stats(from_stats: RangedWeaponStats, player_index: int, args := WeaponServiceInitStatsArgs.new()) -> RangedWeaponStats:
    var structure_pet_stats: RangedWeaponStats =.init_structure_pet_stats(from_stats, player_index, args)
    structure_pet_stats.scaling_stats = _fantasy_apply_structure_scaling_stat_effects(structure_pet_stats.scaling_stats, player_index)
    structure_pet_stats.cooldown = apply_attack_speed_mod_to_cooldown(structure_pet_stats.cooldown, Utils.get_stat(Utils.stat_fantasy_pet_attack_speed_hash, player_index) / 100.0)
    return structure_pet_stats

# =========================== Custom =========================== #
func _fantasy_add_crit_damage(crit_damage: float, player_index: int) -> float:
    crit_damage += Utils.get_stat(Utils.stat_fantasy_crit_damage_hash, player_index) / 100.0
    return crit_damage

func _fantasy_crit_overflow(crit_chance: float, crit_damage: float, player_index: int) -> float:
    var add_crit_dmg: bool = crit_chance > 1.0
    if !add_crit_dmg: return crit_damage

    var crit_overflows: Array = RunData.get_player_effect(Utils.fantasy_crit_overflow_hash, player_index)
    for crit_overflow in crit_overflows:
        var over: float = crit_chance - 1.0
        var scaling: float = crit_overflow[1] / 100.0
        var plus: float = crit_overflow[0] / 100.0

        crit_damage += over / scaling * plus
    return crit_damage

func _fantasy_apply_structure_scaling_stat_effects(scaling_stats: Array, player_index: int) -> Array:
    var structure_scaling_stat_effects: Array = RunData.get_player_effect(Utils.fantasy_structure_scaling_stats_hash, player_index)
    if structure_scaling_stat_effects.empty(): return scaling_stats

    var new_scaling_stats = scaling_stats.duplicate(true)
    for scaling_stat_effect in structure_scaling_stat_effects:
        assert(scaling_stat_effect[0] is int)
        var scaling_stat_hash = scaling_stat_effect[0]
        var scaling_stat_value = scaling_stat_effect[1] / 100.0
        var existing_scaling_stat = find_scaling_stat(scaling_stat_hash, new_scaling_stats)
        if existing_scaling_stat != null:
            existing_scaling_stat[1] += scaling_stat_value
        else:
            new_scaling_stats.append([scaling_stat_hash, scaling_stat_value])
    return new_scaling_stats

# =========================== Weapon Runtime Effects =========================== #
func fantasy_reset_weapon_cooldown(weapon: Node) -> void:
    weapon._current_cooldown = 0
    weapon.tween_animation.remove(weapon.sprite, "self_modulate")
    weapon.sprite.self_modulate = Color("#70CFFF")
    weapon.tween_animation.interpolate_property(
        weapon.sprite, "self_modulate",
        Color("#70CFFF"), Color.white, 0.22,
        Tween.TRANS_SINE, Tween.EASE_OUT
    )
    weapon.tween_animation.start()

func fantasy_cannot_attack_while_stationary(weapon: Node) -> bool:
    if RunData.get_player_effect(Utils.fantasy_cannot_attack_while_stationary_hash, weapon.player_index) <= 0:
        return false

    if weapon._parent == null:
        return false

    var current_movement = weapon._parent.get("_current_movement")
    if !(current_movement is Vector2):
        return false

    return current_movement == Vector2.ZERO

func fantasy_cannot_damage_tree(weapon: Node) -> void:
    if !RunData.get_player_effect_bool(Utils.fantasy_cannot_damage_tree_hash, weapon._parent.player_index): return

    weapon._range.collision_mask -= Utils.NEUTRAL_BIT

func fantasy_should_ignore_tree_body(weapon: Node, body: Node) -> bool:
    return RunData.get_player_effect_bool(Utils.fantasy_cannot_damage_tree_hash, weapon._parent.player_index) and Utils.plant_enemies_ids.has(body.get("enemy_id_hash"))

func fantasy_on_shoot(weapon: Node) -> void:
    _fantasy_reload_when_shoot(weapon)

func fantasy_on_killed_something(weapon: Node) -> void:
    _fantasy_gain_stat_every_killed_enemies(weapon)
    _fantasy_change_weapon_every_killed_enemies(weapon)

func fantasy_on_weapon_hit(weapon: Node, thing_hit: Node, damage_dealt: int, hitbox: Hitbox) -> void:
    if hitbox == null:
        return

    _fantasy_weapon_hit_proc(weapon, thing_hit, damage_dealt)
    _fantasy_lightning_chain_on_hit(weapon, thing_hit)

func fantasy_on_weapon_critically_hit(weapon: Node) -> void:
    _fantasy_reload_when_critically_hit(weapon)

func _fantasy_gain_stat_every_killed_enemies(weapon: Node) -> void:
    for effect in weapon.effects:
        if effect.get_id() != "fantasy_gain_stat_every_killed_enemies" or \
        weapon._enemies_killed_this_wave_count % effect.value != 0: continue

        if effect.is_temp: TempStats.add_stat(effect.stat_hash, effect.stat_nb, weapon.player_index)
        else: RunData.add_stat(effect.stat_hash, effect.stat_nb, weapon.player_index)

        # Update when first add hit_protection
        if effect.stat_hash == Keys.hit_protection_hash:
            weapon._parent._hit_protection += effect.stat_nb

func _fantasy_reload_when_shoot(weapon: Node) -> void:
    var effect_items: Array = RunData.get_player_effect(Utils.fantasy_reload_when_shoot_hash, weapon.player_index)

    for effect_item in effect_items:
        var chance: float = effect_item[1] / 100.0

        if !Utils.get_chance_success(chance): continue

        var tracking_key_hash: int = effect_item[0]
        RunData.ncl_add_effect_tracking_value(tracking_key_hash, 1, weapon.player_index)

        fantasy_reset_weapon_cooldown(weapon)

func _fantasy_change_weapon_every_killed_enemies(weapon: Node) -> void:
    for effect in weapon.effects:
        if effect.get_id() != "fantasy_change_weapon_every_killed_enemies" or \
        weapon._enemies_killed_this_wave_count != effect.value: continue

        Utils.ncl_change_weapon_within_run(weapon.weapon_pos, effect.key_hash, weapon.player_index)

func _fantasy_reload_when_critically_hit(weapon: Node) -> void:
    for effect in weapon.effects:
        if effect.custom_key_hash != Utils.fantasy_reload_when_critically_hit_hash: continue

        var chance: float = effect.value / 100.0

        if !Utils.get_chance_success(chance): continue

        fantasy_reset_weapon_cooldown(weapon)

func _fantasy_weapon_hit_proc(weapon: Node, thing_hit: Node, damage_dealt: int) -> void:
    if damage_dealt <= 0 or !(thing_hit is Enemy) or !is_instance_valid(thing_hit):
        return

    var effect_items: Array = RunData.get_player_effect(Utils.fantasy_weapon_hit_proc_hash, weapon.player_index)
    for effect_item in effect_items:
        var chance: float = effect_item[0]
        var set_id_hash: int = effect_item[1]
        var proc_type: String = effect_item[2]
        var proc_value: int = effect_item[3]

        if set_id_hash != Keys.empty_hash and !_fantasy_weapon_has_set(weapon, set_id_hash):
            continue

        if !Utils.get_chance_success(chance):
            continue

        match proc_type:
            "slow_enemy":
                thing_hit.add_decaying_speed(proc_value)
            "drop_material":
                var main: Main = Utils.get_scene_node()
                if main != null:
                    main.spawn_gold(proc_value, thing_hit.global_position, 0)

func _fantasy_weapon_has_set(weapon: Node, set_id_hash: int) -> bool:
    for weapon_set in weapon.weapon_sets:
        if weapon_set != null and weapon_set.my_id_hash == set_id_hash:
            return true

    return false

func _fantasy_lightning_chain_on_hit(weapon: Node, thing_hit: Node) -> void:
    var main: Main = Utils.get_scene_node()
    if main == null or !(thing_hit is Enemy) or !is_instance_valid(thing_hit):
        return

    var effect_items: Array = RunData.get_player_effect(Utils.fantasy_lightning_chain_on_hit_hash, weapon.player_index)
    var params_list: Array = LightningChainService.collect_triggered_hit_params(weapon.effects, effect_items, weapon.player_index)
    for params in params_list:
        var arc_damage: int = LightningChainService.spawn_lightning_chain(
            main,
            thing_hit,
            weapon.player_index,
            params.damage,
            params.chain_targets,
            params.chain_damage_mult,
            params.arc_width,
            params.arc_jaggedness,
            params.arc_color,
            params.arc_glow_color,
            params.arc_duration,
            params.arc_crit_chance,
            params.arc_crit_damage,
            weapon.effects,
            params.damage_scaling_stats,
            params.arc_scene_path
        )

        RunData.add_weapon_dmg_dealt(weapon.weapon_pos, arc_damage, weapon._parent.player_index)
