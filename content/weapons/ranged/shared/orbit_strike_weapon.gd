extends "res://weapons/ranged/ranged_weapon.gd"

const STRIKE_ATTACK: PackedScene = preload("res://mods-unpacked/Yoko-Fantasy/content/weapons/ranged/shared/orbit_strike_attack.tscn")

const FALLBACK_SOUND: AudioStream = preload("res://mods-unpacked/Yoko-Fantasy/content/weapons/ranged/myriad_thunder/myriad_thunder.wav")

const BASE_ORBIT_RADIUS_X: float = 72.0
const BASE_ORBIT_RADIUS_Y: float = 42.0
const THRUST_DURATION: float = 0.48
const THRUST_HEIGHT: float = 22.0
const ORBIT_GROUP: String = "fantasy_orbit_strike_weapons"

export(PackedScene) var strike_scene
export(String) var targeting_effect_id

var _time: float = 0.0
var _orbit_phase: float = 0.0
var _is_thrusting: bool = false
var _thrust_elapsed: float = 0.0
var _recoil_remaining: float = 0.0
var _pending_targets: Array = []
var _targeting_effect: Resource


func _ready() -> void:
    disable_target_tracking()
    add_to_group(ORBIT_GROUP)
    for effect in effects:
        if effect.get_id() == targeting_effect_id:
            _targeting_effect = effect
            break
    assert(_targeting_effect != null, "Orbit strike targeting effect is missing")
    assert(strike_scene != null, "Orbit strike scene is missing")
    visible = true
    sprite.visible = true
    var animation_node: Node = _parent.get_node_or_null("Animation")
    if animation_node != null:
        animation_node.z_index = 1
    get_parent().z_index = 0
    _update_orbit_position_and_motion(0.0)


func attach(_attach_to: Vector2, _attach_idle_angle: float) -> void:
    _update_orbit_position_and_motion(0.0)


func is_manual_aim() -> bool:
    return false


func get_direction() -> float:
    return rotation


func get_direction_and_calculate_target() -> float:
    return rotation


func update_sprite_flipv() -> void:
    sprite.flip_v = false


func _physics_process(delta: float) -> void:
    if not is_instance_valid(_parent) or _parent.dead or _parent.cleaning_up:
        _pending_targets.clear()
        _recoil_remaining = 0.0
        _is_shooting = false
        return

    if _recoil_remaining > 0.0:
        _recoil_remaining = max(0.0, _recoil_remaining - delta)
        if _recoil_remaining <= 0.0:
            _is_shooting = false

    visible = true
    if is_instance_valid(sprite):
        sprite.visible = true

    _time += delta
    _update_orbit_position_and_motion(delta)
    _update_visual_effects(delta)


func _update_orbit_position_and_motion(delta: float) -> void:
    var orbiting_weapons: Array = []
    for weapon in _parent.current_weapons:
        if is_instance_valid(weapon) and weapon.is_in_group(ORBIT_GROUP):
            orbiting_weapons.append(weapon)
    if not orbiting_weapons.has(self):
        orbiting_weapons.append(self)

    var total_weapons: int = max(1, orbiting_weapons.size())
    var my_index: int = orbiting_weapons.find(self)
    if my_index < 0:
        my_index = 0

    _orbit_phase += delta * 0.35

    var angle: float = (float(my_index) / float(total_weapons)) * TAU - PI / 2.0 + _orbit_phase
    var rx: float = BASE_ORBIT_RADIUS_X + min(total_weapons, 6) * 3.0
    var ry: float = BASE_ORBIT_RADIUS_Y + min(total_weapons, 6) * 2.0
    var local_center: Vector2 = Vector2.ZERO
    var local_orbit_pos: Vector2 = local_center + Vector2(cos(angle) * rx, sin(angle) * ry)

    var in_foreground: bool = sin(angle) > 0.05
    z_index = 2 if in_foreground else 0
    z_as_relative = true

    var breath_y: float = sin(_time * 2.6 + float(my_index) * 1.3) * 5.5
    var breath_sway: float = sin(_time * 1.8 + float(my_index) * 1.1) * 0.045
    var breath_scale: float = 1.0 + sin(_time * 2.2 + float(my_index) * 0.9) * 0.025

    var thrust_y: float = 0.0
    var thrust_scale_bonus: float = 0.0
    if _is_thrusting:
        _thrust_elapsed += delta
        if _thrust_elapsed < THRUST_DURATION:
            var t: float = clamp(_thrust_elapsed / THRUST_DURATION, 0.0, 1.0)
            var pulse: float = 0.0
            if t < 0.35:
                var u: float = t / 0.35
                pulse = u * u * (3.0 - 2.0 * u)
            else:
                var v: float = (t - 0.35) / 0.65
                var cos_fall: float = (cos(v * PI) + 1.0) * 0.5
                pulse = pow(cos_fall, 1.25)
            thrust_y = -_get_thrust_height() * pulse
            thrust_scale_bonus = pulse * 0.07
        else:
            _is_thrusting = false

    position = local_orbit_pos + Vector2(0, breath_y + thrust_y)
    rotation = -PI / 2.0 + breath_sway

    if is_instance_valid(sprite):
        sprite.flip_v = false
        sprite.scale = Vector2.ONE * (breath_scale + thrust_scale_bonus)


func should_shoot() -> bool:
    if not WeaponService.fantasy_can_start_attack(self):
        return false

    var main = Utils.get_scene_node()
    if not is_instance_valid(main) or main._cleaning_up or main._entity_spawner == null:
        return false

    _pending_targets = _collect_targets(main)
    return not _pending_targets.empty()


func shoot() -> void:
    var main = Utils.get_scene_node()
    if not is_instance_valid(main) or main._cleaning_up or main._entity_spawner == null:
        _is_shooting = false
        return

    if is_queued_for_deletion() or not is_physics_processing():
        _is_shooting = false
        return

    if not is_instance_valid(_parent) or _parent.dead or _parent.cleaning_up or current_stats == null:
        _is_shooting = false
        return

    for i in range(_pending_targets.size() - 1, -1, -1):
        if not is_valid_strike_target(_pending_targets[i]):
            _pending_targets.remove(i)
    if _pending_targets.empty():
        _pending_targets = _collect_targets(main)
    if _pending_targets.empty():
        _is_shooting = false
        return

    var targets: Array = _pending_targets
    _pending_targets = []

    _nb_shots_taken += 1
    _current_cooldown = get_next_cooldown()
    _recoil_remaining = current_stats.recoil_duration * 2.0

    for effect in effects:
        if effect.key_hash == Keys.reload_turrets_on_shoot_hash:
            emit_signal("wanted_to_reset_turrets_cooldown")

    _is_thrusting = true
    _thrust_elapsed = 0.0
    _start_cast_effects()

    _play_cast_sound()

    var attack = STRIKE_ATTACK.instance()
    add_child(attack)
    attack.connect("strike_started", self, "_spawn_strike_visuals", [main])
    attack.start(self, targets, main)

    WeaponService.fantasy_on_shoot(self)

    _is_shooting = _recoil_remaining > 0.0
    _on_cast_completed()


func _play_cast_sound() -> void:
    if current_stats != null and not current_stats.shooting_sounds.empty():
        var snd = Utils.get_rand_element(current_stats.shooting_sounds)
        if snd != null:
            SoundManager.play(snd, current_stats.sound_db_mod, 0.15)
            return

    SoundManager.play(FALLBACK_SOUND, -4, 0.15)


func _collect_targets(main: Node) -> Array:
    var center: Vector2 = global_position
    var max_range_sq: float = float(current_stats.max_range) * float(current_stats.max_range)
    var candidates: Array = []
    var in_range: Array = []
    for enemy in main._entity_spawner.get_all_enemies(false):
        if is_valid_strike_target(enemy):
            candidates.append(enemy)
            if center.distance_squared_to(enemy.global_position) <= max_range_sq:
                in_range.append(enemy)
    for neutral in main._entity_spawner.neutrals:
        if is_valid_strike_target(neutral):
            if center.distance_squared_to(neutral.global_position) <= max_range_sq:
                in_range.append(neutral)
    if in_range.empty():
        return []
    var nearest: Unit = in_range[0]
    var nearest_distance: float = center.distance_squared_to(nearest.global_position)
    for target in in_range:
        var distance: float = center.distance_squared_to(target.global_position)
        if distance < nearest_distance:
            nearest = target
            nearest_distance = distance
    candidates.erase(nearest)
    var targets: Array = [nearest]
    var projectile_bonus: int = current_stats.nb_projectiles - stats.nb_projectiles
    var extra_count: int = min(max(0, _targeting_effect.value + projectile_bonus), candidates.size())
    for i in range(extra_count):
        var selected_index: int = Utils.randi_range(i, candidates.size() - 1)
        var selected: Unit = candidates[selected_index]
        candidates[selected_index] = candidates[i]
        candidates[i] = selected
        targets.append(selected)
    return targets


func is_valid_strike_target(target) -> bool:
    return (
        is_instance_valid(target)
        and target is Unit
        and not target.dead
        and not target._pending_die
        and not WeaponService.fantasy_should_ignore_tree_body(self, target)
    )


func _spawn_strike_visuals(target: Unit, main: Node) -> void:
    var pool_id: int = strike_scene.get_instance_id()
    var strike_vfx: Node2D = main.get_node_from_pool(pool_id, main._effects)
    if not is_instance_valid(strike_vfx):
        strike_vfx = strike_scene.instance()
        main._effects.add_child(strike_vfx)
    strike_vfx.set_pool_id(pool_id)
    _configure_strike_visuals(strike_vfx)
    strike_vfx.start_strike(target.global_position, target, 1.0, _get_strike_tint())


func _get_thrust_height() -> float:
    return THRUST_HEIGHT


func _get_strike_tint() -> Color:
    return Color.white


func _configure_strike_visuals(_strike_vfx: Node2D) -> void:
    pass


func _start_cast_effects() -> void:
    pass


func _update_visual_effects(_delta: float) -> void:
    pass


func _on_cast_completed() -> void:
    pass
