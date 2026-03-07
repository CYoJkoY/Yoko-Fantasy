extends "res://entities/units/enemies/enemy.gd"

# stat_holy
var applied_holy_reduce_health: bool = false

# =========================== Extension =========================== #
func init(zone_min_pos: Vector2, zone_max_pos: Vector2, p_players_ref: Array = [], entity_spawner_ref = null) -> void:
    .init(zone_min_pos, zone_max_pos, p_players_ref, entity_spawner_ref)
    _fantasy_holy_reduce_health()
    _fantasy_extra_curse_enemy()

func respawn() -> void:
    .respawn()
    remove_meta("fantasy_thunder_spawned")
    _fantasy_holy_reduce_health()
    _fantasy_extra_curse_enemy()

func get_damage_value(dmg_value: int, from_player_index: int, armor_applied := true, dodgeable := true, is_crit := false, hitbox: Hitbox = null, is_burning := false) -> GetDamageValueResult:
    var dmg_value_result =.get_damage_value(dmg_value, from_player_index, armor_applied, dodgeable, is_crit, hitbox, is_burning)
    dmg_value_result = _fantasy_apply_holy_damage_bonus(dmg_value_result)

    return dmg_value_result


func die(args: = Utils.default_die_args) -> void :
    _fantasy_spawn_thunder_mage_projectile_on_die(args)
    .die(args)


func take_damage(value: int, args: TakeDamageArgs) -> Array:
    var applied_fire_mage_burn: bool = _fantasy_try_apply_fire_mage_burn_from_args(args)
    if applied_fire_mage_burn:
        args.is_burning = true

    return .take_damage(value, args)

# =========================== Custom =========================== #
func _fantasy_holy_reduce_health() -> void:
    if applied_holy_reduce_health: return

    var holy_stat: int = Utils.average_all_player_stats(Utils.stat_fantasy_holy_hash) as int
    if holy_stat <= 0: return
    
    var reduction_factor: float = holy_stat / (holy_stat + 100.0)
    if reduction_factor <= 0: return

    var new_max_health = max(1, int(max_stats.health * reduction_factor))
    
    max_stats.health = new_max_health
    applied_holy_reduce_health = true

func _fantasy_apply_holy_damage_bonus(dmg_value_result: GetDamageValueResult) -> GetDamageValueResult:
    if dead: return dmg_value_result

    if _outline_colors.has(Utils.CURSE_COLOR): return dmg_value_result

    var holy_stat = Utils.average_all_player_stats(Utils.stat_fantasy_holy_hash)
    if holy_stat <= 0: return dmg_value_result

    var bonus_multiplier = 1.0 + (holy_stat / 100.0)
    dmg_value_result.value = int(dmg_value_result.value * bonus_multiplier)
    
    return dmg_value_result

func _fantasy_extra_curse_enemy() -> void:
    if _outline_colors.has(Utils.CURSE_COLOR): return

    for player_index in players_ref.size():
        var effect_items: Array = RunData.get_player_effect(Utils.fantasy_extra_curse_enemy_hash, player_index)
        for effect_item in effect_items:
            var chance: float = effect_item[1] / 100.0
            if !Utils.get_chance_success(chance): continue

            Utils.ncl_curse_enemy(self )
            RunData.add_tracked_value(player_index, effect_item[0], 1)
            reset_speed_stat(_speed_percent_modifier)
            return


func _fantasy_try_apply_fire_mage_burn_from_args(args: TakeDamageArgs) -> bool:
    if dead or args == null or args.is_burning:
        return false

    var hitbox: Hitbox = args.hitbox
    if hitbox == null or hitbox.is_healing:
        return false

    var from_player_index: int = int(args.from_player_index)
    if from_player_index < 0 or from_player_index >= RunData.get_player_count():
        return false

    var effects: Dictionary = RunData.get_player_effects(from_player_index)
    Utils.fantasy_normalize_effect_keys(effects)
    var fire_active_count: int = int(Utils.fantasy_get_effect_value(effects, Utils.fantasy_job_fire_mage_active_hash, 0))
    var selected_tier2_hash: int = int(Utils.fantasy_get_effect_value(effects, Utils.fantasy_job_tier2_id_hash, 0))
    var fire_mage_selected: bool = fire_active_count > 0 \
        or Utils.fantasy_hash_equals(selected_tier2_hash, Keys.generate_hash("fire_mage_t2"))
    if !fire_mage_selected:
        return false

    if randf() > 0.25:
        return false

    var burning_data: BurningData = _fantasy_create_fire_mage_burning_template(args.from, 5)
    if burning_data == null:
        return false

    var initialized_burning_data = WeaponService.init_burning_data(burning_data, from_player_index)
    if !(initialized_burning_data is BurningData):
        return false

    var fire_mage_burning_data: BurningData = initialized_burning_data
    fire_mage_burning_data.chance = 1.0
    fire_mage_burning_data.duration = 5
    fire_mage_burning_data.is_global_burn = true

    if !is_instance_valid(fire_mage_burning_data.from) and from_player_index < players_ref.size() and is_instance_valid(players_ref[from_player_index]):
        fire_mage_burning_data.from = players_ref[from_player_index]

    apply_burning(fire_mage_burning_data)
    return true


func _fantasy_create_fire_mage_burning_template(from_ref, duration_seconds: int = 5) -> BurningData:
    var burning_data_resource: Resource = load("res://items/all/scared_sausage/scared_sausage_burning_data.tres")
    if !(burning_data_resource is BurningData):
        return null

    var source_burning_data: BurningData = burning_data_resource
    var burning_data: BurningData = BurningData.new()
    burning_data.chance = source_burning_data.chance
    burning_data.damage = source_burning_data.damage
    burning_data.duration = duration_seconds
    burning_data.spread = source_burning_data.spread
    burning_data.scaling_stats = source_burning_data.scaling_stats.duplicate(true)
    burning_data.is_global_burn = true
    burning_data.from = from_ref if is_instance_valid(from_ref) else null
    burning_data._late_init()
    return burning_data


func _fantasy_spawn_thunder_mage_projectile_on_die(args) -> void:
    if dead:
        return
    if has_meta("fantasy_thunder_spawned"):
        return

    var player_index: int = int(args.killed_by_player_index)
    if player_index < 0 or player_index >= RunData.get_player_count():
        return
    if player_index >= players_ref.size() or !is_instance_valid(players_ref[player_index]) or players_ref[player_index].dead:
        return

    var effects: Dictionary = RunData.get_player_effects(player_index)
    Utils.fantasy_normalize_effect_keys(effects)
    var thunder_active_count: int = int(Utils.fantasy_get_effect_value(effects, Utils.fantasy_job_thunder_mage_active_hash, 0))
    var selected_tier2_hash: int = int(Utils.fantasy_get_effect_value(effects, Utils.fantasy_job_tier2_id_hash, 0))
    var thunder_mage_selected: bool = thunder_active_count > 0 \
        or Utils.fantasy_hash_equals(selected_tier2_hash, Keys.generate_hash("thunder_mage_t2"))
    if !thunder_mage_selected:
        return

    var projectile_stats_resource: Resource = load("res://weapons/melee/lightning_shiv/2/lightning_shiv_projectile_2.tres")
    if projectile_stats_resource == null:
        return

    if !(projectile_stats_resource is RangedWeaponStats):
        return
    var projectile_source_stats: RangedWeaponStats = projectile_stats_resource
    var projectile_stats: RangedWeaponStats = WeaponService.init_ranged_stats(projectile_source_stats, player_index, true)
    if projectile_stats == null:
        return
    projectile_stats.damage = max(12, projectile_stats.damage)
    projectile_stats.bounce = max(4, projectile_stats.bounce)

    var spawn_args: WeaponServiceSpawnProjectileArgs = WeaponServiceSpawnProjectileArgs.new()
    spawn_args.damage_tracking_key_hash = Keys.item_baby_with_a_beard_hash
    spawn_args.from_player_index = player_index

    set_meta("fantasy_thunder_spawned", true)
    WeaponService.manage_special_spawn_projectile(
        self,
        projectile_stats,
        rand_range(-PI, PI),
        true,
        _entity_spawner_ref,
        players_ref[player_index],
        spawn_args
    )


func reset_speed_stat(percent_modifier: int = 0) -> void:
    .reset_speed_stat(percent_modifier)
    _fantasy_apply_cursed_base_speed_modifier()


func _fantasy_apply_cursed_base_speed_modifier() -> void:
    if !_outline_colors.has(Utils.CURSE_COLOR):
        return

    var total_speed_percent: int = 0
    for player_index in RunData.get_player_count():
        var player_effects: Dictionary = RunData.get_player_effects(player_index)
        total_speed_percent += int(player_effects.get(Utils.fantasy_job_cursed_enemy_base_speed_percent_hash, 0))

    if total_speed_percent == 0:
        return

    var speed_multiplier: float = max(0.0, 1.0 + total_speed_percent / 100.0)
    current_stats.speed = max(0, int(round(current_stats.speed * speed_multiplier)))
    max_stats.speed = current_stats.speed


func get_speed_effect_mods(player_index: int) -> int:
    var effect_mods: int = .get_speed_effect_mods(player_index)
    return effect_mods
