extends "res://weapons/melee/melee_weapon.gd"

const EXPLOSION_SCENE: PackedScene = preload("res://mods-unpacked/Yoko-Fantasy/content/weapons/melee/crusader_hammer/vfx/crusader_hammer_explosion.tscn")
const SWING_FADE_DURATION: float = 0.09

onready var _rune: Sprite = $Sprite/Rune
onready var _swing: Sprite = $SwingGlow

var rune_charge: float = 0.0
var _clock: float = 0.0
var _swing_fade: float = 0.0
var _hammer_effect: Resource
var _blast_stats: MeleeWeaponStats
var _blast_effect: ExplodingEffect = ExplodingEffect.new()


func _ready() -> void:
    for effect in effects:
        if effect.get_id() == "weapon_crusader_hammer":
            _hammer_effect = effect
            break
    _blast_stats = _hammer_effect.get_explosion_stats()
    _blast_effect.explosion_scene = EXPLOSION_SCENE
    _blast_effect.scale = 0.82
    _blast_effect.base_smoke_amount = 1
    _blast_effect.sound_db_mod = -14
    _clock = rand_range(0.0, TAU)
    _swing.visible = false
    _shooting_behavior.set_physics_process(false)


func _process(delta: float) -> void:
    ._process(delta)
    _rune.flip_v = sprite.flip_v
    _swing.flip_v = sprite.flip_v
    _clock += delta
    var breath: float = pow(0.5 + 0.5 * sin(_clock * 2.1), 1.8)
    _rune.material.set_shader_param("opacity", 0.025 + breath * 0.68)
    _rune.material.set_shader_param("charge", rune_charge)
    _rune.material.set_shader_param("phase", _clock)
    if _swing_fade > 0.0:
        _swing_fade = max(0.0, _swing_fade - delta)
        var fade: float = _swing_fade / SWING_FADE_DURATION
        _swing.modulate.a = fade * fade * 0.18 * ProgressData.settings.explosion_opacity
        rune_charge = fade * 0.35
        _swing.visible = _swing_fade > 0.0 and ProgressData.settings.visual_effects


func begin_swing(distance: float) -> void:
    _swing_fade = 0.0
    _swing.scale = Vector2.ONE * distance / 250.0
    _swing.position = Vector2.ZERO
    update_swing(0.0)


func update_swing(progress: float) -> void:
    _swing.visible = ProgressData.settings.visual_effects
    _swing.material.set_shader_param("progress", progress)
    _swing.modulate.a = (0.18 + sin(progress * PI) * 0.18) * ProgressData.settings.explosion_opacity
    rune_charge = 0.35 + sin(progress * PI) * 0.65


func end_swing() -> void:
    _swing_fade = SWING_FADE_DURATION


func on_weapon_hit_something(thing_hit: Node, damage_dealt: int, hitbox: Hitbox) -> void:
    .on_weapon_hit_something(thing_hit, damage_dealt, hitbox)
    if hitbox != _hitbox or not Utils.get_chance_success(_hammer_effect.value / 100.0):
        return
    var args = WeaponServiceExplodeArgs.new()
    args.pos = thing_hit.global_position
    args.damage = WeaponService.get_explosion_damage(_blast_stats, player_index)
    args.scaling_stats = _blast_stats.scaling_stats
    args.accuracy = _hitbox.accuracy
    args.crit_chance = _hitbox.crit_chance
    args.crit_damage = _hitbox.crit_damage
    args.burning_data = _hitbox.burning_data
    args.from_player_index = player_index
    args.is_healing = _hitbox.is_healing
    var explosion = WeaponService.explode(_blast_effect, args)
    explosion._hitbox.player_attack_id = _hitbox.player_attack_id
    explosion.connect("hit_something", self, "on_weapon_hit_something", [explosion._hitbox])
    explosion.connect("killed_something", self, "on_killed_something", [explosion._hitbox])
