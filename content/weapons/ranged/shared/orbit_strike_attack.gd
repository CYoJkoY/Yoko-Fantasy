extends "res://overlap/hitbox.gd"

signal strike_started(target)

const STRIKE_INTERVAL: float = 0.038

var _stats: RangedWeaponStats
var _main: Node
var _targets: Array = []
var _next_index: int = 0
var _remaining: float = 0.0


func _ready() -> void:
    set_physics_process(false)


func start(weapon: Weapon, targets: Array, main: Node) -> void:
    from = weapon
    _main = main
    _targets = targets
    _stats = weapon.current_stats.duplicate()
    _stats.burning_data = weapon.current_stats.burning_data.duplicate()
    var args = Hitbox.HitboxArgs.new().set_from_weapon_stats(_stats)
    set_damage(_stats.damage, args)
    effect_scale = _stats.effect_scale
    speed_percent_modifier = _stats.speed_percent_modifier
    damage_tracking_key_hash = weapon._hitbox.damage_tracking_key_hash
    effects = weapon.effects.duplicate()
    projectiles_on_hit = weapon._hitbox.projectiles_on_hit.duplicate()
    player_attack_id = weapon._shooting_behavior._get_next_attack_id()
    connect("hit_something", self, "_on_hit_something")
    connect("killed_something", weapon, "on_killed_something", [self])
    connect("critically_hit_something", weapon, "_on_weapon_critically_hit_something")
    connect("one_shot_something", weapon, "on_one_shot_something")
    connect("added_gold_on_crit", weapon, "on_added_gold_on_crit")
    set_physics_process(true)
    _advance(0.0)


func _physics_process(delta: float) -> void:
    _advance(delta)


func _advance(delta: float) -> void:
    if not _can_continue():
        _finish()
        return

    _remaining -= delta
    while _remaining <= 0.0 and _next_index < _targets.size():
        var target = _targets[_next_index]
        _next_index += 1
        _remaining += STRIKE_INTERVAL
        if from.is_valid_strike_target(target):
            emit_signal("strike_started", target)
            target.hurt_area_entered_deferred(self)
            if not _can_continue():
                _finish()
                return

    if _next_index >= _targets.size():
        _finish()


func _can_continue() -> bool:
    return (
        is_instance_valid(from)
        and not from.is_queued_for_deletion()
        and from.is_physics_processing()
        and not from._parent.dead
        and not from._parent.cleaning_up
        and is_instance_valid(_main)
        and not _main._cleaning_up
    )


func _on_hit_something(target: Node, damage_dealt: int) -> void:
    RunData.manage_life_steal(_stats, from.player_index)
    ignored_objects.append(target)
    from.on_weapon_hit_something(target, damage_dealt, self)
    if not from.custom_hit_sounds.empty():
        SoundManager2D.play(Utils.get_rand_element(from.custom_hit_sounds), target.global_position, -2, 0.1)


func _finish() -> void:
    active = false
    set_physics_process(false)
    queue_free()
