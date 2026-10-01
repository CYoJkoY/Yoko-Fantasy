extends "res://weapons/ranged/ranged_weapon.gd"

const HOLY_STRIKE_SCENE: PackedScene = preload("res://mods-unpacked/Yoko-Fantasy/content/weapons/ranged/cross_staff/vfx/holy_light_strike.tscn")
const FALLBACK_SOUND: AudioStream = preload("res://mods-unpacked/Yoko-Fantasy/content/weapons/ranged/myriad_thunder/myriad_thunder.wav")

const BASE_ORBIT_RADIUS_X: float = 72.0
const BASE_ORBIT_RADIUS_Y: float = 42.0
const THRUST_DURATION: float = 0.48
const THRUST_HEIGHT: float = 22.0
const CAST_VFX_DURATION: float = 0.36
const STRIKE_STAGGER_INTERVAL: float = 0.038

const TIER_COLORS = [
    {
        "halo": Color(1.0, 0.95, 0.78, 0.70),
        "corona": Color(1.0, 0.95, 0.80, 0.55),
        "flare": Color(1.0, 0.98, 0.90, 0.45),
        "strike": Color(1.0, 0.96, 0.85, 1.0)
    },
    {
        "halo": Color(0.84, 0.96, 1.0, 0.72),
        "corona": Color(0.82, 0.95, 1.0, 0.58),
        "flare": Color(0.90, 0.98, 1.0, 0.48),
        "strike": Color(0.86, 0.96, 1.0, 1.0)
    },
    {
        "halo": Color(0.95, 0.86, 1.0, 0.74),
        "corona": Color(0.92, 0.84, 1.0, 0.60),
        "flare": Color(0.96, 0.90, 1.0, 0.50),
        "strike": Color(0.95, 0.88, 1.0, 1.0)
    },
    {
        "halo": Color(1.0, 0.88, 0.70, 0.78),
        "corona": Color(1.0, 0.90, 0.72, 0.62),
        "flare": Color(1.0, 0.94, 0.80, 0.52),
        "strike": Color(1.0, 0.88, 0.72, 1.0)
    }
]

onready var _staff_halo: Sprite = $Sprite/Muzzle/StaffHalo
onready var _sun_corona: Sprite = $Sprite/Muzzle/SunCoronaRing
onready var _cast_flare: Sprite = $Sprite/Muzzle/CastFlare
onready var _cast_particles: CPUParticles2D = $Sprite/Muzzle/CastParticles

var _time: float = 0.0
var _orbit_phase: float = 0.0
var _is_thrusting: bool = false
var _thrust_elapsed: float = 0.0
var _cast_vfx_elapsed: float = 1.0
var _pending_strikes: Array = []
var _pending_targets: Array = []


func _ready() -> void:
    ._ready()

    visible = true
    if is_instance_valid(sprite):
        sprite.visible = true

    var cfg: Dictionary = _get_tier_color_config()

    if _sun_corona != null:
        _sun_corona.visible = false
        _sun_corona.modulate.a = 0.0

    if _cast_flare != null:
        _cast_flare.visible = false
        _cast_flare.modulate.a = 0.0

    if _staff_halo != null:
        _staff_halo.visible = true
        _staff_halo.modulate = cfg.halo

    _pending_strikes.clear()

    var animation_node: Node = _parent.get_node_or_null("Animation")
    if animation_node != null:
        animation_node.z_index = 1
    get_parent().z_index = 0
    _update_orbit_position_and_motion(0.0)


func _get_tier_color_config() -> Dictionary:
    var t: int = 0
    if "tier" in self and tier is int:
        t = tier
    elif current_stats != null and "tier" in current_stats:
        t = current_stats.tier
    t = int(clamp(t, 0, 3))
    return TIER_COLORS[t]


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
    if not is_instance_valid(_parent) or _parent.dead:
        _pending_strikes.clear()
        _pending_targets.clear()
        return

    visible = true
    if is_instance_valid(sprite):
        sprite.visible = true

    _time += delta
    _process_pending_strikes(delta)
    _update_orbit_position_and_motion(delta)
    _update_visual_effects(delta)


func _process_pending_strikes(delta: float) -> void:
    if _pending_strikes.empty():
        return

    var main = Utils.get_scene_node()
    if main == null or not is_instance_valid(main):
        _pending_strikes.clear()
        return

    var i: int = _pending_strikes.size() - 1
    while i >= 0:
        var item: Dictionary = _pending_strikes[i]
        item.timer -= delta
        if item.timer <= 0.0:
            var target: Unit = item.target
            if is_instance_valid(target) and not target.dead:
                _strike_target(target, main)
            _pending_strikes.remove(i)
        i -= 1


func _update_orbit_position_and_motion(delta: float) -> void:
    var staves: Array = []
    for weapon in _parent.current_weapons:
        if is_instance_valid(weapon) and weapon.get_script() == get_script():
            staves.append(weapon)
    if not staves.has(self):
        staves.append(self)

    var total_staves: int = max(1, staves.size())
    var my_index: int = staves.find(self)
    if my_index < 0:
        my_index = 0

    _orbit_phase += delta * 0.35

    var angle: float = (float(my_index) / float(total_staves)) * TAU - PI / 2.0 + _orbit_phase
    var rx: float = BASE_ORBIT_RADIUS_X + min(total_staves, 6) * 3.0
    var ry: float = BASE_ORBIT_RADIUS_Y + min(total_staves, 6) * 2.0
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
            thrust_y = -THRUST_HEIGHT * pulse
            thrust_scale_bonus = pulse * 0.07
        else:
            _is_thrusting = false

    position = local_orbit_pos + Vector2(0, breath_y + thrust_y)
    rotation = -PI / 2.0 + breath_sway

    if is_instance_valid(sprite):
        sprite.flip_v = false
        sprite.scale = Vector2.ONE * (breath_scale + thrust_scale_bonus)


func _update_visual_effects(delta: float) -> void:
    var cfg: Dictionary = _get_tier_color_config()

    if is_instance_valid(_staff_halo):
        _staff_halo.rotation += delta * 0.8
        var halo_pulse: float = (cfg.halo.a * 0.90) + sin(_time * 2.4) * (cfg.halo.a * 0.22)
        _staff_halo.modulate = Color(cfg.halo.r, cfg.halo.g, cfg.halo.b, halo_pulse)
        _staff_halo.scale = Vector2.ONE * (0.48 + sin(_time * 2.0) * 0.05)

    if _cast_vfx_elapsed < CAST_VFX_DURATION:
        _cast_vfx_elapsed += delta
        var progress: float = clamp(_cast_vfx_elapsed / CAST_VFX_DURATION, 0.0, 1.0)
        var ease_out: float = sin(progress * PI * 0.5)
        var fade_alpha: float = (1.0 - progress) * (1.0 - progress)

        if is_instance_valid(_sun_corona):
            _sun_corona.scale = Vector2.ONE * lerp(0.15, 0.62, ease_out)
            _sun_corona.modulate = Color(cfg.corona.r, cfg.corona.g, cfg.corona.b, cfg.corona.a * fade_alpha)
            _sun_corona.rotation += delta * 1.2
            if progress >= 1.0:
                _sun_corona.visible = false

        if is_instance_valid(_cast_flare):
            _cast_flare.scale = Vector2.ONE * lerp(0.16, 0.35, ease_out)
            _cast_flare.modulate = Color(cfg.flare.r, cfg.flare.g, cfg.flare.b, cfg.flare.a * fade_alpha)
            _cast_flare.rotation += delta * 2.0
            if progress >= 1.0:
                _cast_flare.visible = false


func should_shoot() -> bool:
    if _is_shooting:
        return false

    if WeaponService.fantasy_cannot_attack_while_stationary(self):
        return false

    if _current_cooldown > 0.0:
        return false

    if _parent == null or current_stats == null:
        return false

    var main = Utils.get_scene_node()
    if main == null or main._entity_spawner == null:
        return false

    _pending_targets = _collect_targets(main)
    return not _pending_targets.empty()


func shoot() -> void:
    var main = Utils.get_scene_node()
    if main == null or main._entity_spawner == null:
        _is_shooting = false
        return

    if _parent == null or current_stats == null:
        _is_shooting = false
        return

    if _pending_targets.empty():
        _pending_targets = _collect_targets(main)
    if _pending_targets.empty():
        _is_shooting = false
        return

    var targets: Array = _pending_targets
    _pending_targets = []

    _nb_shots_taken += 1
    var original_stats: RangedWeaponStats = null
    for projectile_count in _stats_every_x_shots:
        if _nb_shots_taken % projectile_count == 0:
            original_stats = current_stats
            current_stats = _stats_every_x_shots[projectile_count]
            var hitbox_args := Hitbox.HitboxArgs.new().set_from_weapon_stats(current_stats)
            _hitbox.set_damage(current_stats.damage, hitbox_args)

    _current_cooldown = get_next_cooldown()
    _hitbox.player_attack_id = _shooting_behavior._get_next_attack_id()
    _hitbox.ignored_objects.clear()

    for effect in effects:
        if effect.key_hash == Keys.reload_turrets_on_shoot_hash:
            emit_signal("wanted_to_reset_turrets_cooldown")

    _is_thrusting = true
    _thrust_elapsed = 0.0
    _cast_vfx_elapsed = 0.0

    var cfg: Dictionary = _get_tier_color_config()

    if is_instance_valid(_sun_corona):
        _sun_corona.visible = true
        _sun_corona.scale = Vector2.ONE * 0.15
        _sun_corona.modulate = cfg.corona
        _sun_corona.rotation = randf() * TAU

    if is_instance_valid(_cast_flare):
        _cast_flare.visible = true
        _cast_flare.scale = Vector2.ONE * 0.16
        _cast_flare.modulate = cfg.flare
        _cast_flare.rotation = randf() * TAU

    if is_instance_valid(_cast_particles):
        _cast_particles.restart()
        _cast_particles.emitting = true

    _play_cast_sound()

    if not targets.empty():
        _strike_target(targets[0], main)

    for idx in range(1, targets.size()):
        _pending_strikes.append({
            "target": targets[idx],
            "timer": float(idx) * STRIKE_STAGGER_INTERVAL
        })

    WeaponService.fantasy_on_shoot(self)

    if original_stats != null:
        current_stats = original_stats
        var hitbox_args := Hitbox.HitboxArgs.new().set_from_weapon_stats(current_stats)
        _hitbox.set_damage(current_stats.damage, hitbox_args)

    _is_shooting = false


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
        if _is_valid_primary_target(enemy):
            candidates.append(enemy)
            if center.distance_squared_to(enemy.global_position) <= max_range_sq:
                in_range.append(enemy)
    for neutral in main._entity_spawner.neutrals:
        if _is_valid_primary_target(neutral):
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
    candidates.shuffle()
    var extra_count: int = min(max(0, current_stats.nb_projectiles - 1), candidates.size())
    for i in range(extra_count):
        targets.append(candidates[i])
    return targets


func _is_valid_primary_target(target: Node) -> bool:
    return (
        is_instance_valid(target)
        and target is Unit
        and not target.dead
        and not WeaponService.fantasy_should_ignore_tree_body(self, target)
    )


func _is_primary_target_in_range(target: Node, center: Vector2, max_range_sq: float) -> bool:
    return _is_valid_primary_target(target) and center.distance_squared_to(target.global_position) <= max_range_sq


func _strike_target(target: Unit, main: Node) -> void:
    if not is_instance_valid(target) or target.dead:
        return

    var cfg: Dictionary = _get_tier_color_config()

    var pool_id: int = HOLY_STRIKE_SCENE.get_instance_id()
    var strike_vfx: Node2D = main.get_node_from_pool(pool_id, main._effects)
    if not is_instance_valid(strike_vfx):
        strike_vfx = HOLY_STRIKE_SCENE.instance()
        main._effects.add_child(strike_vfx)
    strike_vfx.set_pool_id(pool_id)
    strike_vfx.start_strike(target.global_position, target, 1.0, cfg.strike)
    target.hurt_area_entered_deferred(_hitbox)
