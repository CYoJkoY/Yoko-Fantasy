extends "res://projectiles/player_projectile.gd"

const FANTASY_PROJECTILE_VISUAL_UTILS = preload("res://mods-unpacked/Yoko-Fantasy/content/utils/projectile_visual_utils.gd")

const FLASH_SCENE: PackedScene = preload("res://mods-unpacked/Yoko-Fantasy/content/weapons/ranged/deadeye/vfx/deadeye_flash.tscn")
const FOLLOWUP_TEXTURE: Texture = preload("res://mods-unpacked/Yoko-Fantasy/content/projectiles/player/deadeye_projectile/deadeye_followup.webp")
const NORMAL_TEXTURE: Texture = preload("res://mods-unpacked/Yoko-Fantasy/content/projectiles/player/deadeye_projectile/deadeye_projectile.webp")

onready var _flash_pool_id: int = FLASH_SCENE.get_instance_id()

var _is_followup: bool = false
var _crit_checked: bool = false
var _critical_hit: bool = false


func shoot() -> void:
    _is_followup = false
    _crit_checked = false
    _critical_hit = false
    _sprite.texture = NORMAL_TEXTURE
    _sprite.modulate = Color.white
    player_index = _hitbox.from.player_index
    .shoot()


func mark_as_followup() -> void:
    _is_followup = true
    _sprite.texture = FOLLOWUP_TEXTURE


func _on_Hitbox_critically_hit_something(thing_hit: Node, damage_dealt: int) -> void:
    _critical_hit = true
    ._on_Hitbox_critically_hit_something(thing_hit, damage_dealt)
    if _is_followup or _crit_checked or damage_dealt <= 0:
        return
    _crit_checked = true
    if is_instance_valid(_hitbox.from):
        _hitbox.from.request_followup(thing_hit, rotation, _weapon_stats)


func _on_Hitbox_hit_something(thing_hit: Node, damage_dealt: int) -> void:
    var opacity: float = FANTASY_PROJECTILE_VISUAL_UTILS.get_opacity() if damage_dealt > 0 else 0.0
    if opacity > 0.0:
        var main = Utils.get_scene_node()
        var flash = main.get_node_from_pool(_flash_pool_id, main._effects)
        if flash == null:
            flash = FLASH_SCENE.instance()
            main.add_effect(flash)
            flash.set_meta("pool_id", _flash_pool_id)
        var impact_position: Vector2 = global_position
        if is_instance_valid(thing_hit):
            impact_position = thing_hit.global_position
        flash.play_flash(impact_position, rotation, false, _critical_hit or _is_followup, main, opacity)
    _critical_hit = false
    ._on_Hitbox_hit_something(thing_hit, damage_dealt)
