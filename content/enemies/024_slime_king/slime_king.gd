extends Boss

export (PackedScene) var trail_scene
export (float) var trail_duration = 5.0
export (float) var trail_interval = 0.5
export (float) var speed_reduction = 0.5

var trail_timer: float = 0.0
var last_trail_pos: Vector2 = Vector2.ZERO
var _Materials: Node = Utils.get_scene_node().get_node("Materials")

onready var COOLDOWN_0: float = _attack_behavior.cooldown
var current_spawn_cooldown_0: float = 0.0

onready var _spawning_attack_behavior = $SpawningAttackBehavior
onready var COOLDOWN_1: float = _spawning_attack_behavior.cooldown
var current_spawn_cooldown_1: float = 0.0

onready var _spawning_attack_behavior_once = $SpawningAttackBehaviorOnce

func _ready() -> void:
	_spawning_attack_behavior.init(self)
	_spawning_attack_behavior_once.init(self)
	
	_all_attack_behaviors.push_back(_spawning_attack_behavior)
	_all_attack_behaviors.push_back(_spawning_attack_behavior_once)

func _physics_process(delta) -> void:
	if _current_state == 0:
		current_spawn_cooldown_0 = max(0.0, current_spawn_cooldown_0 - Utils.physics_one(delta))
		if current_spawn_cooldown_0 <= 0.0 and not dead:
			current_spawn_cooldown_0 = COOLDOWN_0
			_attack_behavior.shoot()
	
	current_spawn_cooldown_1 = max(0.0, current_spawn_cooldown_1 - Utils.physics_one(delta))
	if current_spawn_cooldown_1 <= 0.0 and not dead:
		current_spawn_cooldown_1 = COOLDOWN_1
		_spawning_attack_behavior.shoot()
	
	trail_timer += delta
	if trail_timer < trail_interval or trail_scene == null: return
	trail_timer = 0.0
	
	if last_trail_pos.distance_to(global_position) <= 20: return
	last_trail_pos = global_position
	create_trail()

func on_state_changed(_new_state: int)->void :
	.on_state_changed(_new_state)
	
	if _new_state == 0:
		_spawning_attack_behavior_once.shoot()

func create_trail():
	var trail_instance = trail_scene.instance()
	trail_instance.global_position = global_position
	trail_instance.duration = trail_duration
	trail_instance.reduction = speed_reduction
	_Materials.add_child(trail_instance)
