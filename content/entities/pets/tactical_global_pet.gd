extends Pet

export(String) var damage_tracking_id
var _damage_tracking_id_hash: int = Keys.empty_hash

var _base_weapon_stats: RangedWeaponStats = RangedWeaponStats.new()
var _current_weapon_stats: RangedWeaponStats = RangedWeaponStats.new()

var _cooldown: float = 0.0
var _is_shooting: bool = false

var wolf_totem_args: TakeDamageArgs

# =========================== Extension =========================== #
func init(zone_min_pos: Vector2, zone_max_pos: Vector2, p_players_ref: Array = [], entity_spawner_ref = null) -> void:
    .init(zone_min_pos, zone_max_pos, p_players_ref, entity_spawner_ref)
    _damage_tracking_id_hash = Keys.generate_hash(damage_tracking_id)

func _ready() -> void:
    wolf_totem_args = TakeDamageArgs.new(player_index)

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

    if _cooldown <= 0 and !_is_shooting:
        _animation_player.play("shoot")

func shoot() -> void:
    _is_shooting = true
    var entity_spawner: EntitySpawner = get_tree().current_scene._entity_spawner
    var enemies: Array = entity_spawner.get_all_enemies(false)
    var bosses: Array = entity_spawner.bosses
    var max_hp: int = 0
    var best_enemy: Enemy = null
    var crit_chance: float = _current_weapon_stats.crit_chance
    var crit_damage: float = _current_weapon_stats.crit_damage
    var damage: int = int(_current_weapon_stats.damage * crit_damage) if Utils.get_chance_success(crit_chance) else _current_weapon_stats.damage

    if enemies.empty(): return

    if !bosses.empty(): enemies = bosses

    for enemy in enemies:
        var hp: int = enemy.current_stats.health
        if hp <= max_hp: continue
        
        max_hp = hp
        best_enemy = enemy

    if !best_enemy or best_enemy.dead: return

    if !best_enemy.is_connected("died", self , "fa_on_wolf_totem_killed_best_enemy"):
        best_enemy.connect("died", self , "fa_on_wolf_totem_killed_best_enemy", [entity_spawner], CONNECT_ONESHOT)
    best_enemy.take_damage(damage, wolf_totem_args)

# =========================== Method =========================== #
func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
    if anim_name == "shoot" and !dead:
        _cooldown = _current_weapon_stats.cooldown
        _is_shooting = false
        _animation_player.play("idle")

func fa_on_wolf_totem_killed_best_enemy(_entity: Entity, _die_args: Entity.DieArgs, entity_spawner: EntitySpawner) -> void:
    entity_spawner.on_weapon_wanted_to_reset_turrets_cooldown()
