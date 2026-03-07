extends AttackBehavior

export(PackedScene) var trail_scene = preload("res://mods-unpacked/Yoko-Fantasy/content/projectiles/enemy/slime_trail/slime_trail.tscn")
var trail_pool_id: int = Keys.empty_hash
export(int) var cooldown = 60
export(float) var trail_duration = 5.0
export(float) var speed_reduction = 0.5
export(float) var size = 1.0

var main: Main = Utils.get_scene_node()
var _materials_container: Node2D = main._materials_container

# =========================== Extension =========================== #
func _ready() -> void:
    reset()
    if !trail_scene: trail_pool_id = Keys.generate_hash(trail_scene.resource_path)

func reset() -> void:
    hide()
    set_deferred("monitoring", false)
    set_physics_process(false)
    scale = Vector2(1.0, 1.0)

func shoot() -> void:
    var trail: Node = main.get_node_from_pool(trail_pool_id, _materials_container)
    
    if !trail:
        trail = trail_scene.instance()
        _materials_container.call_deferred("add_child", trail)
        var _error = trail.connect("duration_timeout", self , "fa_on_DurationTimer_timeout", [trail])
        yield (trail, "ready")

    trail.scale *= size
    trail.reduction = speed_reduction
    trail.already_recycle = false

    trail.drop(global_position, trail_duration)

# =========================== Method =========================== #
func fa_on_DurationTimer_timeout(trail: Area2D) -> void:
    if trail.already_recycle: return

    trail.already_recycle = true
    main.add_node_to_pool(trail, trail_pool_id)
