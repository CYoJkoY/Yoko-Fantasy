extends EnemyProjectile

export (float) var interval = 0.5
export (String) var projectile_path = "res://mods-unpacked/Yoko-Fantasy/content/projectiles/skeleton_archer_projectile/skeleton_archer_projectile_small.tscn"
export (float) var size = 0.6
export (float) var free_time = 2.5

const OFFSET_DISTANCE = 50
const HALF_PI = PI / 2

var timer: float = 0
var projectile_scene: PackedScene = null
var last_spawn_time: float = 0

func _ready():
	projectile_scene = load(projectile_path)

func _physics_process(delta) -> void:
	timer += delta
	
	if timer - last_spawn_time >= interval:
		spawn_perpendicular_projectiles()
		last_spawn_time = timer

func spawn_perpendicular_projectiles() -> void:
	var parent = get_parent()
	if not parent or not projectile_scene:
		return
		
	var new_projectile1 = projectile_scene.instance()
	var new_projectile2 = projectile_scene.instance()
	
	if not new_projectile1 or not new_projectile2:
		return
	
	var direction = velocity.normalized() if velocity else Vector2.RIGHT.rotated(rotation)
	var perpendicular = direction.rotated(HALF_PI)
	
	new_projectile1.position = position + perpendicular * OFFSET_DISTANCE
	new_projectile1.rotation = perpendicular.angle()
	new_projectile1.scale = Vector2(size, size)
	new_projectile1.set_lifetime(free_time)
	new_projectile1.velocity = velocity.rotated(HALF_PI) * size
	
	new_projectile2.position = position - perpendicular * OFFSET_DISTANCE
	new_projectile2.rotation = perpendicular.angle() + PI
	new_projectile2.scale = Vector2(size, size)
	new_projectile2.set_lifetime(free_time)
	new_projectile2.velocity = velocity.rotated(-HALF_PI) * size
	
	parent.add_child(new_projectile1)
	parent.add_child(new_projectile2)

	new_projectile1._hitbox.damage = get_damage() * size
	new_projectile2._hitbox.damage = get_damage() * size
