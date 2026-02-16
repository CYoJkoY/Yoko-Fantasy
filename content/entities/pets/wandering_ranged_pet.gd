extends "res://entities/units/pet/pet.gd"

export(float) var radius = 280.0
export(float) var rotation_speed = 0.7
export(String) var damage_tracking_id = ""

onready var _muzzle: Position2D = $"Muzzle"

var _base_weapon_stats: RangedWeaponStats = RangedWeaponStats.new()
var _current_weapon_stats: RangedWeaponStats = RangedWeaponStats.new()

var _targets_in_range: Array = []
var _current_target: Array = []

var _cooldown: float = 0.0
var _is_shooting: bool = false
var _next_proj_rotation = 0

var _damage_tracking_id_hash: int = Keys.empty_hash

var _players: Array = []
var _angle: float = rand_range(0, TAU)

# =========================== Extension =========================== #
func init(zone_min_pos: Vector2, zone_max_pos: Vector2, p_players_ref: Array = [], entity_spawner_ref = null) -> void:
    .init(zone_min_pos, zone_max_pos, p_players_ref, entity_spawner_ref)
    _players = p_players_ref
    _damage_tracking_id_hash = Keys.generate_hash(damage_tracking_id)

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
    
    _angle += delta * rotation_speed
    var player_position: Vector2 = _players[player_index].global_position

    global_position = Vector2(
        player_position.x + cos(_angle) * radius,
        player_position.y + sin(_angle) * radius
    )

    _cooldown -= Utils.physics_one(delta)
    _current_target = Utils.get_nearest(_targets_in_range, _muzzle.global_position, _current_weapon_stats.min_range)

    if should_shoot(_cooldown, _current_target):
        _animation_player.play("shoot")

func should_shoot(cooldown: float, current_target: Array) -> bool:
    return (cooldown <= 0 and
        not _is_shooting and
        (
            current_target.size() > 0
            and is_instance_valid(current_target[0])
            and Utils.is_between(current_target[1], _current_weapon_stats.min_range, _current_weapon_stats.max_range)
        )
    )

func shoot() -> void:
    var weapon_point: Vector2 = _muzzle.global_position
    if _current_target.size() == 0 or !is_instance_valid(_current_target[0]):
        _is_shooting = false
        return

    _is_shooting = true

    var target_dir = (_current_target[0].global_position - global_position).angle()
    var accuracy: float = _current_weapon_stats.accuracy
    var accuracy_factor = rand_range(-1 + accuracy, 1 - accuracy)
    _next_proj_rotation = target_dir + accuracy_factor
    
    _spawn_projectile(weapon_point)

func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
    if anim_name == "shoot" and !dead:
        _cooldown = _current_weapon_stats.cooldown
        _is_shooting = false
        _animation_player.play("idle")

func _spawn_projectile(position: Vector2) -> void:
    for i in _current_weapon_stats.nb_projectiles:
        var spread: float = _current_weapon_stats.projectile_spread
        var proj_rotation: float = rand_range(_next_proj_rotation - spread, _next_proj_rotation + spread)

        var args := WeaponServiceSpawnProjectileArgs.new()
        args.knockback_direction = Vector2(cos(proj_rotation), sin(proj_rotation))
        args.from_player_index = player_index
        args.damage_tracking_key_hash = _damage_tracking_id_hash
        
        WeaponService.spawn_projectile(position, _current_weapon_stats, proj_rotation, self , args)

func _on_TargetTriggerZone_body_entered(body):
    _targets_in_range.push_back(body)
    var _error = body.connect("died", self , "on_target_died")

func _on_TargetTriggerZone_body_exited(body):
    _targets_in_range.erase(body)
    body.disconnect("died", self , "on_target_died")

func on_target_died(target: Node2D, _args: Entity.DieArgs) -> void:
    _targets_in_range.erase(target)
