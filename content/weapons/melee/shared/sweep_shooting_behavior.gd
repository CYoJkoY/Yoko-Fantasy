extends "res://weapons/shooting_behaviors/melee_weapon_shooting_behavior.gd"

var _phase: int = 0
var _active: bool = false
var _rest_position: Vector2
var _sweep_distance: float


func shoot(distance: float) -> void:
    _phase = 0
    _active = true
    _rest_position = _parent.sprite.position
    _sweep_distance = min(_parent.current_stats.max_range, max(MIN_SWEEP_DISTANCE, distance))
    _parent._hitbox.active = true
    .shoot(distance)
    set_physics_process(true)


func interpolate(property: String, val_a, val_b, duration, tween_trans = Tween.TRANS_EXPO, tween_ease = Tween.EASE_OUT, object = _parent.sprite) -> void:
    if property == "position":
        _phase += 1
    if _phase == 1:
        var speed: float = 1.0 + max(0.0, shooting_data.atk_spd)
        duration = max(0.045, duration / sqrt(speed))
        tween_trans = Tween.TRANS_SINE
        tween_ease = Tween.EASE_OUT
    elif _phase == 2:
        duration *= 0.80
        tween_trans = Tween.TRANS_QUAD
        tween_ease = Tween.EASE_IN
    elif _phase == 3:
        duration *= 0.80
        tween_trans = Tween.TRANS_QUAD
        tween_ease = Tween.EASE_OUT
    else:
        duration *= 0.85
        tween_trans = Tween.TRANS_SINE
        tween_ease = Tween.EASE_IN_OUT
    if property == "position":
        if _phase == 2:
            _parent.begin_swing(_sweep_distance)
        elif _phase == 4:
            _parent.end_swing()
        if _phase == 2 or _phase == 3:
            var progress_start: float = 0.0 if _phase == 2 else 0.5
            _parent.tween.interpolate_method(_parent, "update_swing", progress_start, progress_start + 0.5, duration, tween_trans, tween_ease)
    .interpolate(property, val_a, val_b, duration, tween_trans, tween_ease, object)


func _physics_process(_delta: float) -> void:
    if not _active:
        return
    if _parent._parent.dead or _parent._parent.cleaning_up:
        _parent.tween.stop_all()
        _parent.tween.remove_all()
        _parent._hitbox.active = false
        _parent.disable_hitbox()
        _parent.sprite.position = _rest_position
        _parent.sprite.rotation = 0.0
        _parent.set_shooting(false)
        _parent.end_swing()
    if not _parent._is_shooting:
        _active = false
        set_physics_process(false)
