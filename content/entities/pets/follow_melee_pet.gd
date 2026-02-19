extends Pet

export(String) var damage_tracking_id = ""
var _damage_tracking_id_hash: int = Keys.empty_hash

onready var _target_behavior_shape := $"TargetBehavior/Range/CollisionShape2D"
onready var _hitbox: Hitbox = $"Animation/Hitbox"

var _base_weapon_stats: MeleeWeaponStats = MeleeWeaponStats.new()
var _current_weapon_stats: MeleeWeaponStats = MeleeWeaponStats.new()

var _cooldown: float = 0.0
var _is_shooting: bool = false

# =========================== Extension =========================== #
func init(zone_min_pos: Vector2, zone_max_pos: Vector2, p_players_ref: Array = [], entity_spawner_ref = null) -> void:
    .init(zone_min_pos, zone_max_pos, p_players_ref, entity_spawner_ref)
    _damage_tracking_id_hash = Keys.generate_hash(damage_tracking_id)
    _hitbox.from = self

func update_data(effect: PetEffect) -> void:
    .update_data(effect)
    _base_weapon_stats = effect.weapon_stats

    reload_data()

    _cooldown = _current_weapon_stats.cooldown

func should_data_be_reload() -> bool:
    return true

func reload_data():
    var args := WeaponServiceInitStatsArgs.new()
    _current_weapon_stats = WeaponService.init_melee_pet_stats(_base_weapon_stats, player_index, args)
    _hitbox.projectiles_on_hit = []
    _current_weapon_stats.burning_data.from = self
    _target_behavior_shape.shape.radius = _base_weapon_stats.max_range

    var hitbox_args := Hitbox.HitboxArgs.new().set_from_weapon_stats(_current_weapon_stats)
    _hitbox.effect_scale = _current_weapon_stats.effect_scale
    _hitbox.set_damage(_current_weapon_stats.damage, hitbox_args)
    _hitbox.speed_percent_modifier = _current_weapon_stats.speed_percent_modifier
    _hitbox.from = self

func set_current_stats(stats: Array) -> void:
    _current_weapon_stats = stats[0]

    _hitbox.projectiles_on_hit = []
    _current_weapon_stats.burning_data.from = self
    _target_behavior_shape.shape.radius = _base_weapon_stats.max_range

    var hitbox_args := Hitbox.HitboxArgs.new().set_from_weapon_stats(_current_weapon_stats)
    _hitbox.effect_scale = _current_weapon_stats.effect_scale
    _hitbox.set_damage(_current_weapon_stats.damage, hitbox_args)
    _hitbox.speed_percent_modifier = _current_weapon_stats.speed_percent_modifier
    _hitbox.from = self

func get_stats() -> Array:
    return [_current_weapon_stats]

func _physics_process(delta) -> void:
    if dead: return

    _current_target_behavior.update_target()

    _cooldown -= Utils.physics_one(delta)

    if _cooldown <= 0 and !_is_shooting:
        _animation_player.play("shoot")

func shoot() -> void:
    _is_shooting = true
    _hitbox.enable()

func update_animation(movement: Vector2) -> void:
    .update_animation(movement)
    if mirror_sprite_with_movement:
        if movement.x > 0:
            _hitbox.scale.x = abs(_hitbox.scale.x)
        elif movement.x < 0:
            _hitbox.scale.x = - abs(_hitbox.scale.x)

# =========================== Method =========================== #
func fa_return_attack() -> void:
    _hitbox.ignored_objects.clear()
    if _hitbox.is_disabled(): _hitbox.enable()

func _on_Hitbox_hit_something(_thing_hit: Node, damage_dealt: int):
    RunData.manage_life_steal(_current_weapon_stats, player_index)

    if damage_dealt > 0:
        RunData.add_tracked_value(player_index, _damage_tracking_id_hash, damage_dealt, 1)

func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
    if anim_name == "shoot" and !dead:
        _hitbox.ignored_objects.clear()
        _hitbox.disable()
        _cooldown = _current_weapon_stats.cooldown
        _is_shooting = false
        _animation_player.play("idle")
