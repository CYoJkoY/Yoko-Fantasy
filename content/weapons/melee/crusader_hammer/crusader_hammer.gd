extends "res://mods-unpacked/Yoko-Fantasy/content/weapons/melee/shared/sweep_weapon.gd"

const EXPLOSION_SCENE: PackedScene = preload("res://mods-unpacked/Yoko-Fantasy/content/weapons/melee/crusader_hammer/vfx/crusader_hammer_explosion.tscn")

onready var _rune: Sprite = $Sprite/Rune

var rune_charge: float = 0.0
var _clock: float = 0.0
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


func _process(delta: float) -> void:
    var was_fading: bool = _swing_fade > 0.0
    ._process(delta)
    _rune.flip_v = sprite.flip_v
    _clock += delta
    var breath: float = pow(0.5 + 0.5 * sin(_clock * 2.1), 1.8)
    _rune.material.set_shader_param("opacity", 0.025 + breath * 0.68)
    _rune.material.set_shader_param("charge", rune_charge)
    _rune.material.set_shader_param("phase", _clock)
    if was_fading:
        rune_charge = _swing_fade / SWING_FADE_DURATION * 0.35


func update_swing(progress: float) -> void:
    .update_swing(progress)
    rune_charge = 0.35 + sin(progress * PI) * 0.65


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
