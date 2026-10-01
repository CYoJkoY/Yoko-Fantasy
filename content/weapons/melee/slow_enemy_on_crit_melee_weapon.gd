extends MeleeWeapon

var enemies_in_slow_area: Array = []
var _last_slow_shot_index: int = -1

# ══════════════════════════════════════════ Extension ══════════════════════════════════════════ #
func _on_weapon_critically_hit_something(_thing_hit, _damage_dealt) -> void:
    ._on_weapon_critically_hit_something(_thing_hit, _damage_dealt)
    if (is_big_reload_active() or current_stats.additional_cooldown_every_x_shots == -1) and _last_slow_shot_index != _nb_shots_taken:
        _last_slow_shot_index = _nb_shots_taken
        fa_slow_enemy_on_crit()

# ══════════════════════════════════════════ Method ══════════════════════════════════════════ #
func fa_slow_enemy_on_crit() -> void:
    for enemy in enemies_in_slow_area:
        if is_instance_valid(enemy) and !enemy.dead:
            enemy.add_decaying_speed(-300)

func fa_on_SlowArea_body_entered(body: Node) -> void:
    enemies_in_slow_area.append(body)
    body.connect("died", self, "fa_on_slow_area_enemy_died")

func fa_on_SlowArea_body_exited(body: Node) -> void:
    enemies_in_slow_area.erase(body)
    body.disconnect("died", self, "fa_on_slow_area_enemy_died")

func fa_on_slow_area_enemy_died(enemy: Node, _die_args: Entity.DieArgs) -> void:
    enemies_in_slow_area.erase(enemy)
