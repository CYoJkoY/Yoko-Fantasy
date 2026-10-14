extends Boss

export(PackedScene) var pivots_scene = null

onready var COOLDOWN_0 = _attack_behavior.cooldown
onready var breath_warning: Node2D = $BreathWarning
onready var breath_warning_fill: Polygon2D = $BreathWarning/Fill
onready var breath_warning_outline: Line2D = $BreathWarning/Outline
var cooldown_0 = 0.0
var _charge_shots_remaining: int = 0
var _flame_lifetime: float = 0.0
var _flame_capsule_ends: Array = []
var _flame_radius: float = 0.0

var pivots: Node2D = null

# ══════════════════════════════════════════ Extension ══════════════════════════════════════════ #
func _ready() -> void:
    var flame: Node2D = _attack_behavior.projectile_scene.instance()
    var collision: CollisionShape2D = flame.get_node("Hitbox/Collision")
    var capsule: CapsuleShape2D = collision.shape
    _flame_lifetime = flame.get_node("AnimationPlayer").get_animation("shoot").length
    _flame_radius = capsule.radius * flame.scale.x
    for end in [-capsule.height / 2.0, capsule.height / 2.0]:
        _flame_capsule_ends.append((collision.position + Vector2(0.0, end)) * flame.scale)
    flame.free()
    remove_child(breath_warning)
    Utils.get_scene_node().get_node("TileMap").add_child(breath_warning)
    breath_warning.set_as_toplevel(true)

func _exit_tree() -> void:
    if is_instance_valid(breath_warning):
        breath_warning.queue_free()

func start_shoot() -> void:
    .start_shoot()
    var direction: float = (current_target.global_position - global_position).angle()
    var breath_behavior = _current_attack_behavior
    var charge_distance: float = 0.0
    if _current_state == 1:
        direction = _current_attack_behavior._charge_direction.angle()
        breath_behavior = _attack_behavior
        var shot_interval: float = COOLDOWN_0 / 60.0
        _charge_shots_remaining = int(ceil(_current_attack_behavior.charge_duration / shot_interval))
        var last_shot_time: float = (_charge_shots_remaining - 1) * shot_interval
        charge_distance = _current_attack_behavior.charge_speed * last_shot_time
    else:
        _can_move = false
    breath_behavior.locked_direction = direction
    show_breath_warning(direction, breath_behavior, charge_distance)

func shoot() -> void:
    .shoot()
    if _current_state == 1:
        _attack_behavior.shoot()
        _charge_shots_remaining -= 1
        cooldown_0 = COOLDOWN_0
    else:
        breath_warning.hide()

func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
    ._on_AnimationPlayer_animation_finished(anim_name)
    if is_shooting_anim(anim_name) and _current_state != 1:
        _can_move = true

func _physics_process(delta: float) -> void:
    if dead: return

    # Mutation 2: Plus Mutation 0 attack behavior
    if _current_state == 1 and _move_locked and _charge_shots_remaining > 0:
        cooldown_0 -= Utils.physics_one(delta)
        if cooldown_0 <= 0.0:
            cooldown_0 += COOLDOWN_0
            _charge_shots_remaining -= 1
            _attack_behavior.shoot()

func on_state_changed(new_state: int) -> void:
    _animation_player.stop()
    _animation_player.play("idle")
    _animation_player.playback_speed = _idle_playback_speed
    breath_warning.hide()
    .on_state_changed(new_state)

    match new_state:
        0:
            pivots = pivots_scene.instance()
            add_child(pivots)
            for child in pivots.get_bullets():
                register_additional_projectile(child)
        1: current_stats.speed = 0

func die(args := Utils.default_die_args) -> void:
    breath_warning.hide()
    .die(args)

    if is_instance_valid(pivots):
        pivots.free_pivots()
        pivots = null

# ══════════════════════════════════════════ Method ══════════════════════════════════════════ #
func show_breath_warning(direction: float, behavior: ShootingAttackBehavior, charge_distance: float) -> void:
    var reach: float = behavior.projectile_speed * _flame_lifetime * RunData.current_run_accessibility_settings.speed
    var last_origin: Vector2 = Vector2.RIGHT * charge_distance * RunData.current_run_accessibility_settings.speed
    var origins: Array = [Vector2.ZERO]
    if charge_distance > 0.0:
        origins.append(last_origin)
    var outline_radius: float = (_flame_radius + 1.0) / cos(PI / 16.0)
    var points: PoolVector2Array = PoolVector2Array()
    for projectile_index in range(behavior.number_projectiles):
        var angle: float = 0.0
        if behavior.number_projectiles > 1:
            angle = -behavior.projectile_spread + 2.0 * behavior.projectile_spread * projectile_index / (behavior.number_projectiles - 1)
        for origin in origins:
            for distance in [0.0, reach]:
                for capsule_end in _flame_capsule_ends:
                    var center: Vector2 = origin + (Vector2(distance, 0.0) + capsule_end).rotated(angle)
                    for i in range(16):
                        points.append(center + Vector2.RIGHT.rotated(TAU * i / 16.0) * outline_radius)
    var outline: PoolVector2Array = Geometry.convex_hull_2d(points)
    breath_warning_outline.points = outline
    outline.remove(outline.size() - 1)
    breath_warning_fill.polygon = outline
    breath_warning.global_position = global_position
    breath_warning.global_rotation = direction
    breath_warning.show()

func on_charge_finished() -> void:
    _charge_shots_remaining = 0
    breath_warning.hide()
