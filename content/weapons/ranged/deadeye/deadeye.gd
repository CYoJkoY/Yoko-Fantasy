extends "res://weapons/ranged/ranged_weapon.gd"

const FLASH_SCENE: PackedScene = preload("res://mods-unpacked/Yoko-Fantasy/content/weapons/ranged/deadeye/vfx/deadeye_flash.tscn")
const FOLLOWUP_SOUND: AudioStream = preload("res://weapons/ranged/pistol/gun_pistol_shot_02.wav")

onready var _flash_pool_id: int = FLASH_SCENE.get_instance_id()
onready var _eye: Sprite = $Sprite/EagleEye

var _followup_chance: int = 0
var _eye_pulse: float = 0.0
var _sound_cooldown: float = 0.0
var _followup_args := WeaponServiceSpawnProjectileArgs.new()


func _ready() -> void:
    for effect in effects:
        if effect.text_key == "EFFECT_FANTASY_DEADEYE":
            _followup_chance = effect.value
            break
    assert(_followup_chance > 0)
    _followup_args.effects = effects
    _followup_args.from_player_index = player_index
    _eye.visible = false


func _process(delta: float) -> void:
    _sound_cooldown = max(0.0, _sound_cooldown - delta)
    if _eye_pulse > 0.0:
        _eye_pulse = max(0.0, _eye_pulse - delta * 8.0)
        var facing: float = -1.0 if sprite.flip_v else 1.0
        _eye.position.y = -4.0 * facing
        _eye.material.set_shader_param("pulse", _eye_pulse)
        _eye.visible = _eye_pulse > 0.0


func shoot() -> void:
    .shoot()
    _spawn_muzzle_flash(rotation, false, FantasyProjectileVisualUtils.get_opacity())


func request_followup(target: Node, direction: float, source_stats: Resource) -> void:
    if is_queued_for_deletion():
        return
    if not Utils.get_chance_success(_followup_chance / 100.0):
        return
    call_deferred("_fire_followup", weakref(target), direction, source_stats)


func _fire_followup(target_ref: WeakRef, direction: float, source_stats: Resource) -> void:
    if is_queued_for_deletion() or not is_instance_valid(_parent) or _parent.dead or _parent.cleaning_up:
        return

    var min_distance_squared: float = pow(current_stats.min_range, 2)
    var max_distance_squared: float = pow(current_stats.max_range + 50, 2)
    var target = target_ref.get_ref()
    if _get_followup_target_distance_squared(target, min_distance_squared, max_distance_squared) == INF:
        target = null
        var nearest_distance: float = INF
        for candidate in _targets_in_range:
            var distance: float = _get_followup_target_distance_squared(candidate, min_distance_squared, max_distance_squared)
            if distance < nearest_distance:
                nearest_distance = distance
                target = candidate
    if is_instance_valid(target):
        direction = (target.global_position - muzzle.global_position).angle()

    _followup_args.knockback_direction = Vector2.RIGHT.rotated(direction)
    var projectile = WeaponService.spawn_projectile(muzzle.global_position, source_stats, direction, self, _followup_args)
    projectile.mark_as_followup()
    projectile._hitbox.player_attack_id = _shooting_behavior._get_next_attack_id()
    on_projectile_shot(projectile)

    var opacity: float = FantasyProjectileVisualUtils.get_opacity()
    _eye_pulse = 1.0
    _eye.modulate.a = opacity
    _eye.material.set_shader_param("pulse", _eye_pulse)
    _eye.visible = _eye.modulate.a > 0.0
    _spawn_muzzle_flash(direction, true, opacity)
    if _sound_cooldown <= 0.0:
        SoundManager2D.play(FOLLOWUP_SOUND, global_position, current_stats.sound_db_mod - 1.5, 0.06)
        _sound_cooldown = 0.06


func _get_followup_target_distance_squared(target: Node, min_distance_squared: float, max_distance_squared: float) -> float:
    if not is_instance_valid(target) or target.dead or target.current_stats.health <= 0:
        return INF
    var distance: float = global_position.distance_squared_to(target.global_position)
    if distance < min_distance_squared or distance > max_distance_squared:
        return INF
    return distance


func _spawn_muzzle_flash(direction: float, followup: bool, opacity: float) -> void:
    if opacity <= 0.0:
        return
    var main = Utils.get_scene_node()
    var flash = main.get_node_from_pool(_flash_pool_id, main._effects)
    if flash == null:
        flash = FLASH_SCENE.instance()
        main.add_effect(flash)
        flash.set_meta("pool_id", _flash_pool_id)
    flash.play_flash(muzzle.global_position, direction, true, followup, main, opacity)
