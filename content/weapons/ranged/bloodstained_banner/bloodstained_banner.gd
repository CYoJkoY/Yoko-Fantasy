extends "res://mods-unpacked/Yoko-Fantasy/content/weapons/ranged/shared/orbit_strike_weapon.gd"

onready var _visuals: Node2D = $Sprite/BannerEffects

var _sacrifice_args = TakeDamageArgs.new(-1)


func _ready() -> void:
    _visuals.set_cursed(is_cursed)
    _sacrifice_args.dodgeable = false
    _sacrifice_args.armor_applied = false
    _sacrifice_args.bypass_invincibility = true
    _sacrifice_args.from = _parent


func _get_thrust_height() -> float:
    return 0.0


func _start_cast_effects() -> void:
    _visuals.play_cast()


func _configure_strike_visuals(strike_vfx: Node2D) -> void:
    strike_vfx.set_cursed(is_cursed)


func _on_cast_completed() -> void:
    var _damage_taken: Array = _parent.take_damage(1, _sacrifice_args)
    if _parent.dead:
        _pending_strikes.clear()


func _update_visual_effects(delta: float) -> void:
    _visuals.advance(delta, _time)
