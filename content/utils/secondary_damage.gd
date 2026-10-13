extends Reference

var _weapon: Weapon
var _player_index: int
var _weapon_pos: int
var _damage: int
var _crit_chance: float
var _crit_damage: float
var _args: TakeDamageArgs


func _init(source: Hitbox, damage: int, color: Color) -> void:
    _weapon = source.from
    _player_index = _weapon.player_index
    _weapon_pos = _weapon.weapon_pos
    _damage = damage
    _crit_chance = source.crit_chance
    _crit_damage = source.crit_damage
    _args = Utils.ncl_create_custom_damage_args(_player_index, color)


func deal(target: Unit) -> int:
    if not is_instance_valid(_weapon) or _weapon.is_queued_for_deletion() or _weapon._parent.dead or _weapon._parent.cleaning_up:
        return 0
    if not is_instance_valid(target) or target.dead or target._pending_die:
        return 0
    var was_crit: bool = Utils.get_chance_success(_crit_chance)
    var damage: int = int(_damage * _crit_damage) if was_crit else _damage
    var health_before: int = target.current_stats.health
    var damage_taken: Array = target.take_damage(damage, _args)
    RunData.add_weapon_dmg_dealt(_weapon_pos, damage_taken[1], _player_index)
    Utils.fa_apply_direct_crit_kill_gold_rewards(
        _player_index,
        was_crit,
        health_before > 0 and damage_taken[1] >= health_before
    )
    return damage_taken[1]
