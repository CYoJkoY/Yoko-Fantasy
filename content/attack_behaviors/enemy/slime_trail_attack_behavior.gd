extends AttackBehavior

export(PackedScene) var trail_scene = preload("res://mods-unpacked/Yoko-Fantasy/content/projectiles/enemy/slime_trail/slime_trail.tscn")
var trail_pool_id: int = Keys.empty_hash
export(int) var cooldown = 60
export(float) var trail_duration = 5.0
export(float) var speed_reduction = 0.5

var main: Main = Utils.get_scene_node()
var _materials_container: Node2D = main._materials_container

# =========================== Extension =========================== #
func _ready() -> void:
    if trail_scene != null: trail_pool_id = Keys.generate_hash(trail_scene.resource_path)

func shoot() -> void:
    var trail = main.get_node_from_pool(trail_pool_id, _materials_container)
    
    if !trail:
        trail = trail_scene.instance()
        _materials_container.call_deferred("add_child", trail)
        if !trail.is_connected("duration_timeout", self , "fa_on_DurationTimer_timeout"):
            trail.connect("duration_timeout", self , "fa_on_DurationTimer_timeout", [trail])
        yield (trail, "ready")

    trail.global_position = global_position
    trail.duration = trail_duration
    trail.reduction = speed_reduction
    trail.already_recycle = false
    trail.show()
    trail.monitoring = true
    trail.duration_timer.start()

# =========================== Method =========================== #
func fa_on_DurationTimer_timeout(trail: Area2D) -> void:
    if trail.already_recycle: return

    trail.monitoring = false
    trail.hide()
    trail.already_recycle = true
    main.add_node_to_pool(trail, trail_pool_id)
