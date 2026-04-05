extends Boss

const PARTICLES = preload("res://mods-unpacked/Yoko-Fantasy/content/entities/enemies/030_elder_shadow/elder_shadow_particles.tscn")

export(PackedScene) var clocks_scene = null

var main: Main = null
var particles: Node = null
var clocks: Node = null

# =========================== Extension =========================== #
func _ready() -> void:
    main = Utils.get_scene_node()
    particles = PARTICLES.instance()
    clocks = clocks_scene.instance()
    main.add_child(particles)
    main.add_child(clocks)
    for child in clocks._fantasy_get_bullets():
        register_additional_projectile(child)

func on_state_changed(_new_state: int) -> void:
    .on_state_changed(_new_state)
    
    # Mutation 1:
    if _new_state == 0:
        _current_movement_behavior.teleport_points = clocks._fantasy_get_all_top_positions(false)

func die(args := Utils.default_die_args) -> void:
    .die(args)
    particles.queue_free()
    clocks.fa_remove_prediction_line()
    clocks.queue_free()
