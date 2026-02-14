extends "res://mods-unpacked/Yoko-Fantasy/content/entities/enemies/006_medium_slime/scene/medium_slime.gd"

export(PackedScene) var trail_scene
export(float) var trail_duration = 5.0
export(float) var trail_interval = 0.5
export(float) var speed_reduction = 0.5

var trail_timer: float = 0.0
var last_trail_pos: Vector2 = Vector2.ZERO
var _Materials: Node = Utils.get_scene_node().get_node("Materials")

onready var _shoot_projectiles_behavior = $ShootProjectilesBehavior
onready var COOLDOWN: float = _shoot_projectiles_behavior.cooldown
var current_projectiles_cooldown: float = 0.0

func _ready() -> void:
    _shoot_projectiles_behavior.init(self )
    _all_attack_behaviors.append(_shoot_projectiles_behavior)

func _physics_process(delta) -> void:
    current_projectiles_cooldown = max(0.0, current_projectiles_cooldown - Utils.physics_one(delta))
    if current_projectiles_cooldown <= 0.0 and not dead:
        current_projectiles_cooldown = COOLDOWN
        _shoot_projectiles_behavior.shoot()
    
    trail_timer += delta
    if trail_timer < trail_interval or trail_scene == null: return
    trail_timer = 0.0
    
    if last_trail_pos.distance_to(global_position) <= 20: return
    last_trail_pos = global_position
    create_trail()

func create_trail():
    var trail_instance = trail_scene.instance()
    trail_instance.global_position = global_position
    trail_instance.duration = trail_duration
    trail_instance.reduction = speed_reduction
    _Materials.add_child(trail_instance)
