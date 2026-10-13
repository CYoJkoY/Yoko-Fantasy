extends Node2D

const META_KEY: String = "fantasy_kou_b_hand_airborne"
const HITBOX: PackedScene = preload("res://overlap/hitbox.tscn")
const TARGET_INDEX = preload("res://mods-unpacked/Yoko-Fantasy/content/utils/projectile_target_index.gd")
const FLIGHT_DURATION: float = 0.78
const IMPACT_DURATION: float = 0.22
const IMPACT_RADIUS: float = 64.0
const SELF_LOSS_RATIO: float = 0.5
const BOSS_LOSS_RATIO: float = 0.1

var _source: Node
var _target: Node
var _weapon: Node
var _main: Node
var _hitbox: Area2D
var _age: float = 0.0
var _landed: bool = false
var _start: Vector2
var _destination: Vector2
var _sprite_position: Vector2
var _sprite_rotation: float
var _sprite_scale: Vector2
var _mode: int
var _layer: int
var _mask: int
var _physics_enabled: bool
var _animation_active: bool
var _hitbox_active: bool
var _hitbox_disabled: bool
var _hurtbox_disabled: bool
var _z_index: int
var _spin: float
var _visuals: bool
var _self_loss_ratio: float
var _player_index: int
var _boss_timer_paused: bool


func begin(source: Node, target: Node, weapon: Node, main: Node) -> void:
    _source = source
    _target = target
    _weapon = weapon
    _main = main
    _start = source.global_position
    _destination = target.global_position
    _sprite_position = source.sprite.position
    _sprite_rotation = source.sprite.rotation
    _sprite_scale = source.sprite.scale
    _mode = source.mode
    _layer = source.collision_layer
    _mask = source.collision_mask
    _physics_enabled = source.is_physics_processing()
    _animation_active = source._animation_player.is_active()
    _hitbox_active = source._hitbox.active
    _hitbox_disabled = source._hitbox.is_disabled()
    _hurtbox_disabled = source._hurtbox.is_disabled()
    _z_index = source.z_index
    _spin = -1.0 if _destination.x < _start.x else 1.0
    _visuals = ProgressData.settings.visual_effects
    _self_loss_ratio = BOSS_LOSS_RATIO if source is Boss else SELF_LOSS_RATIO
    _player_index = weapon.player_index
    if source is Boss:
        _boss_timer_paused = source._check_state_timer.paused
        source._check_state_timer.paused = true
    source.set_meta(META_KEY, self)
    source.connect("died", self, "_on_source_died")
    source.connect("tree_exiting", self, "_on_source_exiting")
    source.set_physics_process(false)
    source._animation_player.set_active(false)
    source.mode = RigidBody2D.MODE_STATIC
    source.linear_velocity = Vector2.ZERO
    source._integrate_forces_velocity = Vector2.ZERO
    source.collision_layer = 0
    source.collision_mask = 0
    source._hitbox.active = false
    source._hitbox.disable()
    source._hurtbox.disable()
    source.z_index = 25
    _hitbox = HITBOX.instance()
    add_child(_hitbox)
    _hitbox.collision_layer = 0
    _hitbox.collision_mask = 0
    _hitbox.disable()
    _hitbox.from = weapon
    _hitbox.damage = max(1, source.max_stats.health)
    _hitbox.damage_tracking_key_hash = weapon._hitbox.damage_tracking_key_hash
    _hitbox.player_attack_id = weapon._hitbox.player_attack_id
    _hitbox.connect("hit_something", weapon, "on_weapon_hit_something", [_hitbox])
    _hitbox.connect("killed_something", weapon, "on_killed_something", [_hitbox])


func _physics_process(delta: float) -> void:
    if not is_instance_valid(_main) or _main._cleaning_up:
        _finish()
        return
    _age += delta
    if _landed:
        if _age >= FLIGHT_DURATION + IMPACT_DURATION:
            queue_free()
        if _visuals:
            update()
        return
    if not is_instance_valid(_source) or _source.dead or _source._pending_die:
        _finish()
        return
    var progress: float = min(_age / FLIGHT_DURATION, 1.0)
    if progress < 0.64 and is_instance_valid(_target) and not _target.dead and not _target._pending_die and not _target.has_meta(META_KEY):
        _destination = _target.global_position
    _destination.x = clamp(_destination.x, _source._min_pos.x, _source._max_pos.x)
    _destination.y = clamp(_destination.y, _source._min_pos.y, _source._max_pos.y)
    var travel: float = smoothstep(0.18, 1.0, progress)
    _source.global_position = _start.linear_interpolate(_destination, travel)
    var arc: float = sin(progress * PI)
    _source.sprite.position = _sprite_position + Vector2(0.0, -arc * 150.0)
    _source.sprite.rotation = _sprite_rotation + _spin * arc * 0.55
    _source.sprite.scale = _sprite_scale * Vector2(1.0 - arc * 0.12, 1.0 + arc * 0.12)
    global_position = _source.global_position
    if _visuals:
        update()
    if progress >= 1.0:
        _land()


func _land() -> void:
    var thrown: Node = _source
    _restore_source()
    _target = null
    _landed = true
    _apply_self_loss(thrown)
    _apply_impact(thrown)
    if not _visuals:
        _finish()


func _apply_self_loss(thrown: Node) -> void:
    if not is_instance_valid(thrown) or thrown.dead or thrown._pending_die:
        return
    var loss_amount: int = int(floor(thrown.max_stats.health * _self_loss_ratio))
    var health_lost: int = int(min(thrown.current_stats.health, loss_amount))
    thrown.current_stats.health -= health_lost
    thrown.emit_signal("health_updated", thrown, thrown.current_stats.health, thrown.max_stats.health)
    if health_lost > 0:
        thrown.flash()
        if is_instance_valid(_weapon) and not _weapon.is_queued_for_deletion():
            _hitbox.hit_something(thrown, health_lost)
    if is_instance_valid(thrown) and not thrown.dead and not thrown._pending_die and thrown.current_stats.health <= 0:
        thrown._pending_die = true
        _hitbox.killed_something(thrown)
        var death_args = Entity.DieArgs.new()
        death_args.killed_by_player_index = _player_index
        death_args.killing_blow_dmg_value = loss_amount
        thrown.call_deferred("die", death_args)


func _apply_impact(thrown: Node) -> void:
    if not is_instance_valid(_weapon) or _weapon._parent.dead or _weapon._parent.cleaning_up:
        return
    var index = _main.get_meta(TARGET_INDEX.META_KEY)
    for enemy in index.candidates(_main, global_position, IMPACT_RADIUS):
        if not is_instance_valid(_weapon) or _weapon.is_queued_for_deletion():
            break
        if not is_instance_valid(enemy) or enemy == thrown or enemy.dead or enemy._pending_die or enemy.has_meta(META_KEY):
            continue
        if enemy.global_position.distance_squared_to(global_position) <= IMPACT_RADIUS * IMPACT_RADIUS:
            enemy.hurt_area_entered_deferred(_hitbox)


func _restore_source() -> void:
    if not is_instance_valid(_source):
        _source = null
        return
    if _source.is_connected("died", self, "_on_source_died"):
        _source.disconnect("died", self, "_on_source_died")
    if _source.is_connected("tree_exiting", self, "_on_source_exiting"):
        _source.disconnect("tree_exiting", self, "_on_source_exiting")
    _source.remove_meta(META_KEY)
    _source.sprite.position = _sprite_position
    _source.sprite.rotation = _sprite_rotation
    _source.sprite.scale = _sprite_scale
    _source.z_index = _z_index
    _source.mode = _mode
    _source.collision_layer = _layer
    _source.collision_mask = _mask
    _source.set_physics_process(_physics_enabled)
    _source._animation_player.set_active(_animation_active)
    if _source is Boss:
        _source._check_state_timer.paused = _boss_timer_paused
    _source._hitbox.active = _hitbox_active
    if not _source.dead and not _source._pending_die:
        if not _hitbox_disabled:
            _source._hitbox.enable()
        if not _hurtbox_disabled:
            _source._hurtbox.enable()
    _source = null


func _finish() -> void:
    _restore_source()
    _target = null
    set_physics_process(false)
    queue_free()


func _on_source_died(_enemy: Node, _args) -> void:
    _finish()


func _on_source_exiting() -> void:
    _finish()


func _exit_tree() -> void:
    _restore_source()


func _draw() -> void:
    if not _visuals:
        return
    if not _landed:
        var height: float = sin(min(_age / FLIGHT_DURATION, 1.0) * PI)
        draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.38))
        draw_circle(Vector2.ZERO, 18.0 - height * 6.0, Color(0.08, 0.06, 0.10, 0.28 - height * 0.10))
    else:
        var progress: float = clamp((_age - FLIGHT_DURATION) / IMPACT_DURATION, 0.0, 1.0)
        draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.55))
        draw_arc(Vector2.ZERO, lerp(12.0, IMPACT_RADIUS, progress), 0.0, TAU, 24, Color(1.0, 0.66, 0.77, (1.0 - progress) * 0.8), 3.0 * (1.0 - progress), true)
