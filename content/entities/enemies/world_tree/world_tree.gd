extends Boss

onready var _laser_shooting_attack_behavior: ShootingAttackBehavior = $"%LaserShootingAttackBehavior"
onready var COOLDOWN_0: float = _laser_shooting_attack_behavior.cooldown
var current_cooldown_0: float = 0.0

# =========================== Extension =========================== #
func _ready() -> void:
    _laser_shooting_attack_behavior.init(self )
    _laser_shooting_attack_behavior.max_range = int(ceil(ZoneService.get_current_zone_rect().size.length()))

    register_attack_behavior(_laser_shooting_attack_behavior)
    _prewarm_laser_projectile()

func _physics_process(delta) -> void:
    ._physics_process(delta)
    if dead: return

    if _current_state == 0:
        current_cooldown_0 = current_cooldown_0 - Utils.physics_one(delta)
        if current_cooldown_0 <= 0:
            current_cooldown_0 = COOLDOWN_0
            _laser_shooting_attack_behavior.shoot()

# =========================== Custom =========================== #
func _prewarm_laser_projectile() -> void:
    var main: Main = Utils.get_scene_node()
    var pool_id: int = _laser_shooting_attack_behavior.projectile_pool_id
    if pool_id == Keys.empty_hash:
        pool_id = Keys.generate_hash(_laser_shooting_attack_behavior.projectile_scene.resource_path)
        _laser_shooting_attack_behavior.projectile_pool_id = pool_id

    var projectile = main.get_node_from_pool(pool_id, main._enemy_projectiles)
    if projectile == null:
        projectile = _laser_shooting_attack_behavior.projectile_scene.instance()
        main.add_enemy_projectile(projectile)
        projectile.set_meta("pool_id", pool_id)

    main.add_node_to_pool(projectile, pool_id)
