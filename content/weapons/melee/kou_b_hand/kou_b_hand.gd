extends "res://weapons/melee/melee_weapon.gd"

const SLAM = preload("res://mods-unpacked/Yoko-Fantasy/content/weapons/melee/kou_b_hand/kou_b_hand_slam.gd")
const SPLASH_SCENE: PackedScene = preload("res://mods-unpacked/Yoko-Fantasy/content/weapons/melee/kou_b_hand/vfx/kou_b_hand_splash.tscn")
const HEARTS_SCENE: PackedScene = preload("res://mods-unpacked/Yoko-Fantasy/content/weapons/melee/kou_b_hand/vfx/kou_b_hand_hearts.tscn")
const TARGET_INDEX = preload("res://mods-unpacked/Yoko-Fantasy/content/utils/projectile_target_index.gd")
const TARGET_RANGE: float = 320.0

var _next_splash_time: int = 0
var _climax_effect: Effect


func _ready() -> void:
    for effect in effects:
        if effect.text_key == "EFFECT_FANTASY_KOU_B_HAND":
            _climax_effect = effect
            break
    assert(_climax_effect != null)


func is_manual_aim() -> bool:
    return false


func get_direction_and_calculate_target() -> float:
    _current_target = Utils.get_nearest_no_max(_targets_in_range, global_position, current_stats.min_range)
    return get_direction()


func get_direction() -> float:
    var target_angle: float = rotation
    if not _current_target.empty() and is_instance_valid(_current_target[0]) and not _current_target[0].dead:
        target_angle = (_current_target[0].global_position - global_position).angle()
    return lerp_angle(rotation, target_angle, 1.0 - exp(-18.0 * get_physics_process_delta_time()))


func should_shoot() -> bool:
    if _parent.dead or _parent.cleaning_up:
        return false
    return .should_shoot()


func shoot() -> void:
    if _parent.dead or _parent.cleaning_up:
        set_shooting(false)
        return
    .shoot()


func strike() -> void:
    if _parent.dead or _parent.cleaning_up:
        return
    _current_target = Utils.get_nearest_no_max(_targets_in_range, global_position, current_stats.min_range)
    var target: Unit = _current_target[0]
    if not is_instance_valid(target) or target.dead:
        return
    if not Utils.is_between(_current_target[1], current_stats.min_range, get_max_range()):
        return
    _hitbox.set_knockback((target.global_position - global_position).normalized(), current_stats.knockback, current_stats.knockback_piercing)
    SoundManager.play(Utils.get_rand_element(current_stats.shooting_sounds), current_stats.sound_db_mod, 0.2)
    target.hurt_area_entered_deferred(_hitbox)


func on_weapon_hit_something(thing_hit: Node, damage_dealt: int, hitbox: Hitbox) -> void:
    .on_weapon_hit_something(thing_hit, damage_dealt, hitbox)
    if hitbox != _hitbox or damage_dealt <= 0 or not is_instance_valid(thing_hit) or not (thing_hit is Enemy):
        return
    if _parent.dead or _parent.cleaning_up:
        return
    var main: Node = Utils.get_scene_node()
    if not is_instance_valid(main) or main._cleaning_up:
        return

    var origin: Vector2 = thing_hit._hurtbox.global_position
    var target: Node = null
    var chance: float = _climax_effect.value / 100.0
    if thing_hit is Boss:
        chance *= 0.1
    if not thing_hit.dead and not thing_hit._pending_die and not thing_hit.has_meta(SLAM.META_KEY) and Utils.get_chance_success(chance):
        target = _find_slam_target(main, thing_hit, origin)

    if ProgressData.settings.visual_effects:
        var now: int = OS.get_ticks_msec()
        if now >= _next_splash_time or target != null:
            _next_splash_time = now + 65
            var splash_id: int = SPLASH_SCENE.get_instance_id()
            var splash = main.get_node_from_pool(splash_id, main._effects)
            if splash == null:
                splash = SPLASH_SCENE.instance()
                main.add_effect(splash)
            splash.play(thing_hit, main, splash_id, 1.10 if target != null else 1.0)

    if target == null:
        return
    var slam = SLAM.new()
    main.add_effect(slam)
    slam.begin(thing_hit, target, self, main, _climax_effect)
    if ProgressData.settings.visual_effects:
        var hearts_id: int = HEARTS_SCENE.get_instance_id()
        var hearts = main.get_node_from_pool(hearts_id, main._effects)
        if hearts == null:
            hearts = HEARTS_SCENE.instance()
            main.add_effect(hearts)
        hearts.play(thing_hit, main, hearts_id)


func _find_slam_target(main: Node, source: Node, origin: Vector2) -> Node:
    if not main.has_meta(TARGET_INDEX.META_KEY):
        main.set_meta(TARGET_INDEX.META_KEY, TARGET_INDEX.new())
    var index = main.get_meta(TARGET_INDEX.META_KEY)
    var nearest: Node = null
    var nearest_distance: float = TARGET_RANGE * TARGET_RANGE
    for enemy in index.candidates(main, origin, TARGET_RANGE):
        if not is_instance_valid(enemy) or enemy == source or not (enemy is Enemy) or enemy.dead or enemy._pending_die or enemy.has_meta(SLAM.META_KEY):
            continue
        var distance_squared: float = origin.distance_squared_to(enemy._hurtbox.global_position)
        if distance_squared < nearest_distance:
            nearest_distance = distance_squared
            nearest = enemy
    return nearest
