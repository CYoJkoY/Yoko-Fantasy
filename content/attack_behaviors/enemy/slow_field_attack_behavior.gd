extends AttackBehavior

enum SpawnPosition {Self, Random}

export(PackedScene) var slow_field_scene = preload("res://mods-unpacked/Yoko-Fantasy/content/specials/enemy/slime_trail/slime_trail.tscn")
var slow_field_pool_id: int = Keys.empty_hash
export(int) var cooldown = 60
export(float) var slow_field_duration = 5.0
export(float) var speed_reduction = 0.5
export(float) var size = 1.0
export(SpawnPosition) var spawn_position = SpawnPosition.Self

var main: Main = Utils.get_scene_node()

# =========================== Extension =========================== #
func _ready() -> void:
    reset()
    if is_instance_valid(slow_field_scene): slow_field_pool_id = Keys.generate_hash(slow_field_scene.resource_path)

func reset() -> void:
    hide()
    set_deferred("monitoring", false)
    set_physics_process(false)
    scale = Vector2(1.0, 1.0)

func shoot() -> void:
    var slow_field: Node = main.get_node_from_pool(slow_field_pool_id, main._materials_container)

    if !is_instance_valid(slow_field):
        slow_field = slow_field_scene.instance()
        main._materials_container.add_child(slow_field)
        var _error = slow_field.connect("duration_timeout", self , "fa_on_DurationTimer_timeout", [slow_field])

    slow_field.scale *= size
    slow_field.reduction = speed_reduction
    slow_field.already_recycle = false

    match spawn_position:
        SpawnPosition.Self: slow_field.drop(global_position, slow_field_duration)
        SpawnPosition.Random: slow_field.drop(ZoneService.get_rand_pos(), slow_field_duration)

# =========================== Method =========================== #
func fa_on_DurationTimer_timeout(slow_field: Area2D) -> void:
    if slow_field.already_recycle: return

    slow_field.already_recycle = true
    main.add_node_to_pool(slow_field, slow_field_pool_id)
