extends EnemyProjectile

export(int) var child_projectiles_num = 2
export(int) var child_init_rotation = 90
export(int) var child_rotation_change_after_each = 0
export(bool) var is_symmetrical = true
export(int) var offset_distance = 30
export(int) var spawn_cooldown = 30
export(PackedScene) var child_projectile = preload("res://mods-unpacked/Yoko-Fantasy/content/projectiles/enemy/skeleton_archer_projectile/skeleton_archer_projectile_small.tscn")
var child_projectile_pool_id: int = Keys.empty_hash
export(float) var power = 0.6
export(bool) var will_spawn_entity = false
export(int) var entity_spawn_num = 1
export(Array, String, FILE, "*.tscn") var entity_scenes = []

var _spawn_cooldwon: float = 0.0
var main: Main = null
var entity_spawner: EntitySpawner = null

# =========================== Extension =========================== #
func _ready() -> void:
    if child_projectile != null:
        child_projectile_pool_id = Keys.generate_hash(child_projectile.resource_path)
    
    main = Utils.get_scene_node()
    entity_spawner = main._entity_spawner
    child_init_rotation = deg2rad(child_init_rotation)
    child_rotation_change_after_each = deg2rad(child_rotation_change_after_each)

func _return_to_pool() -> void:
    ._return_to_pool()

    _spawn_cooldwon = 0.0

func _physics_process(delta) -> void:
    _spawn_cooldwon -= Utils.physics_one(delta)
    if _spawn_cooldwon > 0: return

    for i in child_projectiles_num: spawn_perpendicular_projectiles(i)
    
    if will_spawn_entity:
        var args: EntitySpawner.SpawnEntityArgs = EntitySpawner.SpawnEntityArgs.new(global_position, EntityType.ENEMY)
        var entity_scene: PackedScene = load(Utils.get_rand_element(entity_scenes))
        for _i in entity_spawn_num: entity_spawner.spawn_entity(entity_scene, args)

    _spawn_cooldwon = spawn_cooldown

func spawn_perpendicular_projectiles(index: int) -> void:
    var new_projectile: EnemyProjectile = main.get_node_from_pool(child_projectile_pool_id, main._enemy_projectiles)
    if !is_instance_valid(new_projectile):
        new_projectile = child_projectile.instance()
        main.add_enemy_projectile(new_projectile)
        new_projectile.set_meta("pool_id", child_projectile_pool_id)

    var child_velocity: Vector2 = velocity
    match [is_symmetrical, index % 2 == 1]:
        [false, _]: child_velocity = child_velocity.rotated(child_init_rotation + index * child_rotation_change_after_each)
        [true, false]: child_velocity = child_velocity.rotated(child_init_rotation + index * child_rotation_change_after_each)
        [true, true]: child_velocity = child_velocity.rotated(- (child_init_rotation + (index - 1) * child_rotation_change_after_each))

    var child_rotation: float = child_velocity.angle()
    new_projectile.global_position = global_position + child_velocity.normalized() * offset_distance
    new_projectile.rotation = child_rotation
    new_projectile.set_from(_hitbox.from)
    new_projectile.velocity = child_velocity

    new_projectile.set_damage(get_damage() * power)
    new_projectile.shoot()
