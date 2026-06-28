class_name TacticalGlobalPet
extends Pet

export(int) var max_num: int = 8
export(String) var damage_tracking_id
var damage_tracking_id_hash: int = Keys.empty_hash
export(Color) var damage_color = Color("#F5D35E")
export(bool) var has_shoot_anim = false

var _base_weapon_stats: RangedWeaponStats = RangedWeaponStats.new()
var _current_weapon_stats: RangedWeaponStats = RangedWeaponStats.new()

var _cooldown: float = 0.0
var _is_shooting: bool = false

var tactical_global_args: TakeDamageArgs = null

# =========================== Extension =========================== #
func init(zone_min_pos: Vector2, zone_max_pos: Vector2, p_players_ref: Array = [], entity_spawner_ref=null) -> void:
    .init(zone_min_pos, zone_max_pos, p_players_ref, entity_spawner_ref)
    damage_tracking_id_hash = Keys.generate_hash(damage_tracking_id)

func update_data(effect: PetEffect) -> void:
    .update_data(effect)
    _base_weapon_stats = effect.weapon_stats

    reload_data()

    _cooldown = _current_weapon_stats.cooldown

func should_data_be_reload() -> bool:
    return true

func reload_data():
    var args := WeaponServiceInitStatsArgs.new()
    _current_weapon_stats = WeaponService.init_ranged_pet_stats(_base_weapon_stats, player_index, false, args)
    _current_weapon_stats.burning_data.from = self

func set_current_stats(stats: Array) -> void:
    _current_weapon_stats = stats[0]
    _current_weapon_stats.burning_data.from = self

func get_stats() -> Array:
    return [_current_weapon_stats]

func _physics_process(delta) -> void:
    if dead: return

    _cooldown -= Utils.physics_one(delta)

    if _cooldown > 0 or _is_shooting: return

    if has_shoot_anim: _animation_player.play("shoot")
    else: shoot()

func shoot() -> void:
    _is_shooting = true
    var enemies: Array = entity_spawner.get_all_enemies(false)

    if enemies.empty(): return

    var crit_chance: float = _current_weapon_stats.crit_chance
    var crit_damage: float = _current_weapon_stats.crit_damage
    var damage: int = _current_weapon_stats.damage
    if Utils.get_chance_success(crit_chance):
        damage = int(damage * crit_damage)
        tactical_global_args = Utils.ncl_create_custom_damage_args(player_index, damage_color)
    else: tactical_global_args = TakeDamageArgs.new(player_index)

    enemies.sort_custom(self, "fa_sort_by_health_desc")

    var processed_count = 0
    for i in range(min(max_num, enemies.size())):
        var enemy: Enemy = enemies[i]

        if !is_instance_valid(enemy) or enemy.dead: continue

        if !enemy.is_connected("died", self, "fa_on_tatical_global_pet_killed_best_enemy"):
            enemy.connect("died", self, "fa_on_tatical_global_pet_killed_best_enemy", [], CONNECT_ONESHOT)

        var take_damage_array: Array = enemy.take_damage(damage, tactical_global_args)
        var actual_damage: int = take_damage_array[1]
        RunData.add_tracked_value(player_index, damage_tracking_id_hash, actual_damage)
        processed_count += 1

        if processed_count >= max_num: break
    
    if !has_shoot_anim:
        _cooldown = _current_weapon_stats.cooldown
        _is_shooting = false

# =========================== Method =========================== #
func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
    if anim_name == "shoot" and !dead:
        _cooldown = _current_weapon_stats.cooldown
        _is_shooting = false
        _animation_player.play("idle")

func fa_sort_by_health_desc(enemy_1: Enemy, enemy_2: Enemy) -> bool:
    return enemy_1.current_stats.health > enemy_2.current_stats.health

func fa_on_tatical_global_pet_killed_best_enemy(_entity: Entity, _die_args: Entity.DieArgs) -> void:
    pass
