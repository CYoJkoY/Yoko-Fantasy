extends "res://weapons/shooting_behaviors/ranged_weapon_shooting_behavior.gd"


func shoot(_distance: float) -> void:
    SoundManager.play(Utils.get_rand_element(_parent.current_stats.shooting_sounds), _parent.current_stats.sound_db_mod, 0.008)
    var initial_position: Vector2 = _parent.sprite.position
    var recoil_position: Vector2 = initial_position - Vector2(_parent.current_stats.recoil, 0.0)
    var recoil_duration: float = _parent.current_stats.recoil_duration
    _parent.set_shooting(true)

    var attack_id: int = _get_next_attack_id()
    var projectile_count: int = _parent.current_stats.nb_projectiles
    var half_spread: float = _parent.current_stats.projectile_spread
    for i in range(projectile_count):
        var spread_weight: float = float(i) / float(projectile_count - 1) if projectile_count > 1 else 0.5
        var angle: float = _parent.rotation + lerp(-half_spread, half_spread, spread_weight)
        _parent.shamisen_note_index = i % 3
        var projectile = shoot_projectile(angle, Vector2.RIGHT.rotated(angle))
        projectile._hitbox.player_attack_id = attack_id

    _parent.tween.interpolate_property(_parent.sprite, "position", initial_position,
        recoil_position, recoil_duration, Tween.TRANS_EXPO, Tween.EASE_OUT)
    _parent.tween.interpolate_property(_parent.sprite, "position", recoil_position,
        initial_position, recoil_duration, Tween.TRANS_EXPO, Tween.EASE_OUT, recoil_duration)
    _parent.tween.interpolate_callback(_parent, recoil_duration * 2.0, "set_shooting", false)
    _parent.tween.start()
