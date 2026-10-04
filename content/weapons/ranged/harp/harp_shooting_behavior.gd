extends "res://weapons/shooting_behaviors/ranged_weapon_shooting_behavior.gd"

const AUDIO = preload("res://mods-unpacked/Yoko-Fantasy/content/weapons/ranged/harp/harp_audio.gd")
var _harp_audio: Node


func _ready() -> void:
    var scene: Node = get_tree().current_scene
    _harp_audio = scene.get_node_or_null("FantasyHarpAudio")
    if _harp_audio == null:
        _harp_audio = AUDIO.new()
        _harp_audio.name = "FantasyHarpAudio"
        scene.add_child(_harp_audio)


func shoot(_distance: float) -> void:
    _harp_audio.pluck()
    _parent.set_shooting(true)
    var attack_id: int = _get_next_attack_id()
    for _i in range(_parent.current_stats.nb_projectiles):
        var angle: float = rand_range(_parent.rotation - _parent.current_stats.projectile_spread,
            _parent.rotation + _parent.current_stats.projectile_spread)
        var projectile = shoot_projectile(angle, Vector2.RIGHT.rotated(angle))
        projectile._hitbox.player_attack_id = attack_id
    _parent.tween.interpolate_callback(_parent, _parent.current_stats.recoil_duration * 2.0, "set_shooting", false)
    _parent.tween.start()
