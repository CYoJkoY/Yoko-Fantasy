extends "res://weapons/melee/melee_weapon.gd"

const CHAIN_TEXTURE: Texture = preload("res://mods-unpacked/Yoko-Fantasy/content/weapons/melee/meteor_hammer/meteor_hammer_chain_link.webp")
const CHAIN_CURVE_STEPS: int = 12
const MAX_CHAIN_LINKS: int = 64
const LINK_PITCH: float = 17.0
const HANDLE_SOCKET: Vector2 = Vector2(-14, -14)
const HEAD_SOCKET: Vector2 = Vector2(-13, 14)
const HEAD_RADIUS: float = 34.0

onready var head: Sprite = $Sprite/Head
onready var _swing_trail: Node2D = $SwingTrail
onready var _sweep_shape: CapsuleShape2D = $Sprite/Hitbox/Collision.shape

var head_position: Vector2
var _head_velocity: Vector2 = Vector2.ZERO
var _head_angular_velocity: float = 0.0
var _chain_draw_points: PoolVector2Array = PoolVector2Array()
var _chain_draw_transform: Transform2D = Transform2D.IDENTITY
var _last_anchor: Vector2
var _last_owner_position: Vector2
var _chain_start: Vector2
var _chain_end: Vector2
var _chain_bend: Vector2 = Vector2.ZERO
var _chain_bend_velocity: Vector2 = Vector2.ZERO
var _kill_cooldown_effect: Resource
var _impact_time: float = 0.0
var _initialized: bool = false


func _ready() -> void:
    for effect in effects:
        if effect.custom_key == "meteor_hammer_kill_cooldown":
            _kill_cooldown_effect = effect
            break
    _hitbox.active = false
    _sweep_shape.radius = HEAD_RADIUS
    head.set_as_toplevel(true)


func get_direction() -> float:
    if _shooting_behavior.phase != _shooting_behavior.Phase.IDLE:
        return _shooting_behavior.attack_angle
    return .get_direction()


func shoot() -> void:
    if _parent.dead or _parent.cleaning_up:
        _shooting_behavior.cancel_attack()
        return
    .shoot()


func update_sprite_flipv() -> void:
    pass


func get_chain_anchor() -> Vector2:
    return sprite.to_global(Vector2(HANDLE_SOCKET.x, -HANDLE_SOCKET.y if sprite.flip_v else HANDLE_SOCKET.y))


func get_handle_rest_angle() -> float:
    return HANDLE_SOCKET.angle() if sprite.flip_v else -HANDLE_SOCKET.angle()


func get_rest_position() -> Vector2:
    var side: float = -1.0 if sprite.flip_v else 1.0
    var rest_length: float = min(58.0, max(70.0, current_stats.max_range + 20.0) * 0.4)
    return get_chain_anchor() + Vector2(rest_length, side * rest_length * (18.0 / 58.0)).rotated(rotation)


func _physics_process(delta: float) -> void:
    if _shooting_behavior.phase == _shooting_behavior.Phase.IDLE:
        .update_sprite_flipv()
        sprite.rotation = get_handle_rest_angle()
    var anchor: Vector2 = get_chain_anchor()
    if not _initialized:
        head_position = get_rest_position()
        _last_anchor = anchor
        _last_owner_position = global_position
        _initialized = true
        _update_head_transform()
        _reset_chain()
    if _parent.dead or _parent.cleaning_up:
        _shooting_behavior.cancel_attack()
        if not _parent.dead:
            head_position = get_rest_position()
            _head_velocity = Vector2.ZERO
            _head_angular_velocity = 0.0
            _update_head_transform()
            _reset_chain()
            update()
        set_physics_process(false)
        return
    if anchor.distance_to(_last_anchor) > max(400.0, current_stats.max_range * 2.0):
        var shift: Vector2 = anchor - _last_anchor
        head_position += shift
        _last_owner_position = global_position
        _head_velocity = Vector2.ZERO
        _head_angular_velocity = 0.0
        _swing_trail.clear_trail()
        _update_head_transform()
        _reset_chain()
    var previous_head: Vector2 = head_position
    if _shooting_behavior.phase != _shooting_behavior.Phase.IDLE:
        head_position += global_position - _last_owner_position
        _shooting_behavior.advance(delta)
        if _shooting_behavior.phase == _shooting_behavior.Phase.IDLE:
            _head_velocity = ((head_position - previous_head) / delta).clamped(250.0)
        else:
            _head_velocity = Vector2.ZERO
    else:
        var step: float = min(delta, 1.0 / 30.0) / 2.0
        var rest: Vector2 = get_rest_position()
        var damping: float = exp(-12.0 * step)
        for _i in range(2):
            _head_velocity += (rest - head_position) * 100.0 * step
            _head_velocity *= damping
            head_position += _head_velocity * step
        var idle_offset: Vector2 = head_position - anchor
        if idle_offset.length() > 110.0:
            var idle_direction: Vector2 = idle_offset.normalized()
            head_position = anchor + idle_direction * 110.0
            _head_velocity = _head_velocity.slide(idle_direction)
    var tension: float = _shooting_behavior.get_chain_tension()
    _update_head_transform(delta, tension)
    _update_sweep(previous_head)
    var chain_changed: bool = _update_chain(delta, tension)
    _last_anchor = get_chain_anchor()
    _last_owner_position = global_position
    _impact_time = max(0.0, _impact_time - delta)
    var flash: float = _impact_time / 0.10 if ProgressData.settings.visual_effects else 0.0
    head.self_modulate = Color(1.0 + flash * 0.3, 1.0 + flash * 0.25, 1.0 + flash * 0.15)
    var trail_opacity: float = ProgressData.settings.explosion_opacity if ProgressData.settings.visual_effects else 0.0
    _swing_trail.advance(head, _hitbox.active and _shooting_behavior.is_damage_phase(), delta, trail_opacity)
    if chain_changed or global_transform != _chain_draw_transform:
        update()


func _update_head_transform(delta: float = 0.0, tension: float = 0.0) -> void:
    head.global_position = head_position
    var direction: Vector2 = head_position - get_chain_anchor()
    var target_angle: float = direction.angle() + PI - HEAD_SOCKET.angle()
    if delta <= 0.0:
        head.global_rotation = target_angle
    else:
        var step: float = min(delta, 1.0 / 30.0) * 0.5
        var stiffness: float = lerp(160.0, 620.0, tension)
        var damping: float = exp(-lerp(16.0, 28.0, tension) * step)
        for _i in range(2):
            var angle_error: float = wrapf(target_angle - head.global_rotation, -PI, PI)
            _head_angular_velocity += angle_error * stiffness * step
            _head_angular_velocity *= damping
            head.global_rotation += _head_angular_velocity * step
    muzzle.global_position = head_position


func _update_sweep(previous_head: Vector2) -> void:
    if not _hitbox.active or not _shooting_behavior.is_damage_phase():
        return
    var motion: Vector2 = head_position - previous_head
    if motion.length_squared() > 0.001:
        _hitbox.set_knockback(motion.normalized(), current_stats.knockback, current_stats.knockback_piercing)
    _hitbox.global_position = (head_position + previous_head) * 0.5
    _hitbox.global_rotation = motion.angle() + PI / 2.0
    _sweep_shape.height = motion.length()


func _reset_chain() -> void:
    _chain_start = get_chain_anchor()
    _chain_end = head.to_global(HEAD_SOCKET)
    var tension: float = _shooting_behavior.get_chain_tension()
    var max_bend: float = min(64.0, max(12.0, _chain_start.distance_to(_chain_end) * 0.35))
    _chain_bend = Vector2(0, min(max_bend, lerp(22.0, 1.5, tension)))
    _chain_bend_velocity = Vector2.ZERO
    _chain_draw_points.resize(CHAIN_CURVE_STEPS + 1)


func _update_chain(delta: float, tension: float) -> bool:
    var start: Vector2 = get_chain_anchor()
    var end: Vector2 = head.to_global(HEAD_SOCKET)
    var chord: Vector2 = end - start
    var chord_length: float = chord.length()
    var motion: Vector2 = ((start - _chain_start) + (end - _chain_end)) * 0.5
    var lateral_velocity: Vector2 = motion / delta
    if chord_length > 0.001:
        var direction: Vector2 = chord / chord_length
        lateral_velocity -= direction * lateral_velocity.dot(direction)
    lateral_velocity = lateral_velocity.clamped(600.0)
    var max_bend: float = min(64.0, max(12.0, chord_length * 0.35))
    var target: Vector2 = (Vector2(0, lerp(22.0, 1.5, tension)) - lateral_velocity * (0.06 * (1.0 - tension))).clamped(max_bend)
    var previous_bend: Vector2 = _chain_bend
    var frequency: float = lerp(12.0, 24.0, tension)
    var error: Vector2 = _chain_bend - target
    var impulse: Vector2 = _chain_bend_velocity + error * frequency
    var decay: float = exp(-frequency * delta)
    _chain_bend = target + (error + impulse * delta) * decay
    _chain_bend_velocity = (_chain_bend_velocity - impulse * frequency * delta) * decay
    if _chain_bend.distance_squared_to(target) < 0.0001 and _chain_bend_velocity.length_squared() < 0.01:
        _chain_bend = target
        _chain_bend_velocity = Vector2.ZERO
    var changed: bool = start != _chain_start or end != _chain_end or _chain_bend != previous_bend
    _chain_start = start
    _chain_end = end
    return changed


func _draw() -> void:
    if not _initialized:
        return
    _chain_draw_transform = global_transform
    var inverse_transform: Transform2D = _chain_draw_transform.affine_inverse()
    var start: Vector2 = inverse_transform.xform(_chain_start)
    var end: Vector2 = inverse_transform.xform(_chain_end)
    var bend: Vector2 = inverse_transform.basis_xform(_chain_bend)
    for i in range(CHAIN_CURVE_STEPS + 1):
        var t: float = float(i) / CHAIN_CURVE_STEPS
        _chain_draw_points[i] = start.linear_interpolate(end, t) + bend * (4.0 * t * (1.0 - t))
    draw_polyline(_chain_draw_points, Color(0.16, 0.20, 0.21), 3.0, true)
    var link_pitch: float = max(LINK_PITCH, (start.distance_to(end) + 2.0 * bend.length()) / (MAX_CHAIN_LINKS - 1))
    var next_link: float = 0.0
    var link_index: int = 0
    var texture_origin: Vector2 = -CHAIN_TEXTURE.get_size() * 0.5
    for segment in range(CHAIN_CURVE_STEPS):
        var i: int = CHAIN_CURVE_STEPS - 1 - segment
        var segment_start: Vector2 = _chain_draw_points[i + 1]
        var segment_end: Vector2 = _chain_draw_points[i]
        var length: float = segment_start.distance_to(segment_end)
        if length < 0.001:
            continue
        var angle: float = (segment_end - segment_start).angle()
        while next_link <= length and link_index < MAX_CHAIN_LINKS:
            var point: Vector2 = segment_start.linear_interpolate(segment_end, next_link / length)
            draw_set_transform(point, angle, Vector2(1.0, 1.0 if link_index % 2 == 0 else 0.65))
            draw_texture(CHAIN_TEXTURE, texture_origin)
            next_link += link_pitch
            link_index += 1
        next_link -= length
        draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func on_weapon_hit_something(thing_hit: Node, damage_dealt: int, hitbox: Hitbox) -> void:
    .on_weapon_hit_something(thing_hit, damage_dealt, hitbox)
    if hitbox == _hitbox and damage_dealt > 0:
        _impact_time = 0.10


func on_killed_something(thing_killed: Node, hitbox: Hitbox) -> void:
    .on_killed_something(thing_killed, hitbox)
    if not thing_killed is Enemy:
        return
    var remaining: float = 1.0 - clamp(_kill_cooldown_effect.value / 100.0, 0.0, 1.0)
    for weapon in _parent.current_weapons:
        weapon._current_cooldown *= remaining


func disable_hitbox() -> void:
    _hitbox.active = false
    .disable_hitbox()
    if is_instance_valid(_swing_trail) and (_parent.dead or _parent.cleaning_up):
        if _parent.dead:
            head.hide()
        _swing_trail.clear_trail()
