extends "res://weapons/ranged/ranged_weapon.gd"

const ASTROLABE_SCENE: PackedScene = preload("res://mods-unpacked/Yoko-Fantasy/content/weapons/ranged/finger_snap/vfx/finger_snap_astrolabe.tscn")
const BULLET_SCENE: PackedScene = preload("res://mods-unpacked/Yoko-Fantasy/content/projectiles/player/finger_snap_projectile/finger_snap_bullet.tscn")
const MUZZLE_FLASH_SCENE: PackedScene = preload("res://mods-unpacked/Yoko-Fantasy/content/weapons/ranged/finger_snap/vfx/finger_snap_muzzle_flash.tscn")
onready var _astrolabe_pool_id: int = ASTROLABE_SCENE.get_instance_id()
onready var _muzzle_flash_pool_id: int = MUZZLE_FLASH_SCENE.get_instance_id()

const CONVERGE_RADIUS: float = 125.0
const SNAP_ANIM_DURATION: float = 0.28

onready var _muzzle: Position2D = $Sprite/Muzzle

var _is_snapping: bool = false
var _snap_elapsed: float = 0.0
var _target: Node = null
var _finger_snap_effect = null
var _base_sprite_rotation: float = 0.0


func _ready() -> void:
    ._ready()
    visible = true
    if is_instance_valid(sprite):
        sprite.visible = true
        _base_sprite_rotation = sprite.rotation
    for effect in effects:
        if effect != null and effect.has_method("get_id") and effect.get_id() == "weapon_finger_snap":
            _finger_snap_effect = effect
            break


func should_shoot() -> bool:
    if _is_shooting:
        return false

    if WeaponService.fantasy_cannot_attack_while_stationary(self):
        return false

    if _current_cooldown > 0.0:
        return false

    if _parent == null or current_stats == null:
        return false

    if not is_instance_valid(_target) or ("dead" in _target and _target.dead):
        _target = _find_closest_target()
    return is_instance_valid(_target)


func _physics_process(delta: float) -> void:
    if not is_instance_valid(_parent) or _parent.dead:
        _target = null
        return

    _update_snap_motion(delta)

    _target = _find_closest_target()

    if is_instance_valid(_target):
        var target_angle = (_target.global_position - global_position).angle()
        rotation = lerp_angle(rotation, target_angle, delta * 15.0)


func _update_snap_motion(delta: float) -> void:
    if not _is_snapping:
        if is_instance_valid(sprite):
            sprite.rotation = _base_sprite_rotation
            sprite.scale = Vector2.ONE
        return

    _snap_elapsed += delta
    var progress = clamp(_snap_elapsed / SNAP_ANIM_DURATION, 0.0, 1.0)

    if is_instance_valid(sprite):
        var twist: float = 0.0
        var scale_x: float = 1.0
        var scale_y: float = 1.0

        if progress < 0.35:
            var p = progress / 0.35
            var ease_in = p * p
            twist = -0.42 * ease_in
            scale_x = 1.0 + 0.12 * ease_in
            scale_y = 1.0 - 0.08 * ease_in
        elif progress < 0.55:
            var p = (progress - 0.35) / 0.20
            twist = lerp(-0.42, 0.32, p)
            scale_x = lerp(1.12, 1.20, p)
            scale_y = lerp(0.92, 0.96, p)
        else:
            var p = (progress - 0.55) / 0.45
            var ease_out = 1.0 - pow(1.0 - p, 2.0)
            twist = lerp(0.32, 0.0, ease_out)
            scale_x = lerp(1.20, 1.0, ease_out)
            scale_y = lerp(0.96, 1.0, ease_out)

        sprite.rotation = _base_sprite_rotation + twist
        sprite.scale = Vector2(scale_x, scale_y)

    if progress >= 1.0:
        _is_snapping = false


func shoot() -> void:
    var main = Utils.get_scene_node()
    if main == null or not is_instance_valid(main):
        _is_shooting = false
        return

    if _parent == null or current_stats == null:
        _is_shooting = false
        return

    var target = _target
    if target == null or not is_instance_valid(target) or ("dead" in target and target.dead):
        _target = _find_closest_target()
        target = _target

    if target == null:
        _is_shooting = false
        return

    var target_pos = target.global_position

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

    _is_snapping = true
    _snap_elapsed = 0.0

    var muzzle_pos = _muzzle.global_position if is_instance_valid(_muzzle) else global_position
    _spawn_muzzle_flash(main, muzzle_pos, rotation)

    _play_shooting_sound()

    var tier_val: int = _get_current_tier()
    _spawn_target_astrolabe(main, target_pos, target, tier_val)
    _apply_direct_hit(target)

    _spawn_converging_bullet_ring(main, target_pos)

    WeaponService.fantasy_on_shoot(self)

    if original_stats != null:
        current_stats = original_stats
        var hitbox_args := Hitbox.HitboxArgs.new().set_from_weapon_stats(current_stats)
        _hitbox.set_damage(current_stats.damage, hitbox_args)

    _is_shooting = false


func _spawn_muzzle_flash(main: Node, pos: Vector2, rot: float) -> void:
    var flash = main.get_node_from_pool(_muzzle_flash_pool_id, main._effects)
    if flash == null:
        flash = MUZZLE_FLASH_SCENE.instance()
        main.add_effect(flash)
        flash.set_meta("pool_id", _muzzle_flash_pool_id)
    flash.play_flash(pos, rot, main, _muzzle_flash_pool_id)


func _play_shooting_sound() -> void:
    if current_stats != null and not current_stats.shooting_sounds.empty():
        SoundManager2D.play(Utils.get_rand_element(current_stats.shooting_sounds), global_position, current_stats.sound_db_mod, 0.2)


func _apply_direct_hit(target: Node) -> void:
    if not is_instance_valid(target) or ("dead" in target and target.dead):
        return

    var hitbox_args := Hitbox.HitboxArgs.new().set_from_weapon_stats(current_stats)
    _hitbox.set_damage(current_stats.damage, hitbox_args)

    if target.has_method("hurt_area_entered_deferred"):
        target.hurt_area_entered_deferred(_hitbox)


func _spawn_target_astrolabe(main: Node, target_pos: Vector2, target: Node, tier_val: int) -> void:
    var astrolabe = main.get_node_from_pool(_astrolabe_pool_id, main._effects)
    if astrolabe == null:
        astrolabe = ASTROLABE_SCENE.instance()
        main.add_effect(astrolabe)
        astrolabe.set_meta("pool_id", _astrolabe_pool_id)
    astrolabe.start_astrolabe(target_pos, target, tier_val, main, _astrolabe_pool_id)


func _spawn_converging_bullet_ring(main: Node, target_pos: Vector2) -> void:
    if _finger_snap_effect == null:
        return

    var extra_projectiles: int = 0
    if current_stats != null and stats != null:
        extra_projectiles = max(0, int(current_stats.nb_projectiles) - int(stats.nb_projectiles))
    var bullet_count: int = max(1, int(_finger_snap_effect.bullet_count) + extra_projectiles)
    var base_bullet_dmg: float = float(_finger_snap_effect.base_damage)
    var luck_ratio: float = float(_finger_snap_effect.scaling_stats[0][1])

    var player_luck: float = 0.0
    if is_instance_valid(_parent):
        player_luck = float(Utils.get_stat(Keys.stat_luck_hash, _parent.player_index))

    var luck_bonus_dmg: float = max(0.0, player_luck * luck_ratio)

    var percent_dmg: float = 0.0
    if is_instance_valid(_parent):
        percent_dmg = float(Utils.get_stat(Keys.stat_percent_damage_hash, _parent.player_index))

    var final_bullet_dmg: int = max(1, int(round((base_bullet_dmg + luck_bonus_dmg) * (1.0 + percent_dmg / 100.0))))

    var start_angle: float = rand_range(0.0, TAU)
    var angle_step: float = TAU / float(bullet_count)
    var pool_id: int = BULLET_SCENE.get_instance_id()
    var hitbox_args := Hitbox.HitboxArgs.new().set_from_weapon_stats(current_stats)

    for i in range(bullet_count):
        var angle: float = start_angle + float(i) * angle_step
        var spawn_pos: Vector2 = target_pos + Vector2(cos(angle), sin(angle)) * CONVERGE_RADIUS

        var bullet = main.get_node_from_pool(pool_id, main._player_projectiles)
        if bullet == null:
            bullet = BULLET_SCENE.instance()
            main.add_player_projectile(bullet)
            bullet.set_meta("pool_id", pool_id)

        bullet.set_weapon_stats(current_stats)

        var bullet_hitbox: Hitbox = bullet._hitbox
        if bullet_hitbox != null:
            bullet_hitbox.set_damage(final_bullet_dmg, hitbox_args)
            bullet_hitbox.player_attack_id = _shooting_behavior._get_next_attack_id()
            bullet_hitbox.from = _parent
            bullet_hitbox.active = true
            bullet_hitbox.enable()
            bullet_hitbox.ignored_objects.clear()

        bullet.init_converge(target_pos, spawn_pos, 460.0)


func _find_closest_target() -> Node:
    var closest_target: Node = null
    var closest_distance_sq: float = INF
    var min_distance_sq: float = float(current_stats.min_range) * float(current_stats.min_range)
    var max_distance_sq: float = float(current_stats.max_range) * float(current_stats.max_range)
    for target in _targets_in_range:
        if not is_instance_valid(target) or ("dead" in target and target.dead):
            continue
        var distance_sq: float = global_position.distance_squared_to(target.global_position)
        if distance_sq > min_distance_sq and distance_sq <= max_distance_sq and distance_sq < closest_distance_sq:
            closest_distance_sq = distance_sq
            closest_target = target
    return closest_target


func _get_current_tier() -> int:
    return int(clamp(tier, 0, 3))
