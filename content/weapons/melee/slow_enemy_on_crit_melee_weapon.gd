extends MeleeWeapon

var enemies_in_slow_area: Array = []

# =========================== Extension =========================== #
func _on_weapon_critically_hit_something(_thing_hit, _damage_dealt) -> void:
    ._on_weapon_critically_hit_something(_thing_hit, _damage_dealt)
    fa_slow_enemy_on_crit()
    
# =========================== Method =========================== #
func fa_slow_enemy_on_crit() -> void:
    for enemy in enemies_in_slow_area: enemy.add_decaying_speed(-300)

func fa_on_SlowArea_body_entered(body: Node) -> void:
    enemies_in_slow_area.append(body)

func fa_on_SlowArea_body_exited(body: Node) -> void:
    enemies_in_slow_area.erase(body)
