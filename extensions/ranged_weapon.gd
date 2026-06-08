extends "res://weapons/ranged/ranged_weapon.gd"

# =========================== Extension =========================== #
func _ready() -> void:
	WeaponService.fantasy_cannot_damage_tree(self)

func should_shoot() -> bool:
	if WeaponService.fantasy_cannot_attack_while_stationary(self):
		return false

	return .should_shoot()

func shoot() -> void:
	.shoot()
	WeaponService.fantasy_on_shoot(self)

func on_killed_something(_thing_killed: Node, hitbox: Hitbox) -> void:
	.on_killed_something(_thing_killed, hitbox)
	WeaponService.fantasy_on_killed_something(self)

func _on_Range_body_entered(body: Node) -> void:
	if WeaponService.fantasy_should_ignore_tree_body(self, body): return
	._on_Range_body_entered(body)

func _on_Range_body_exited(body: Node) -> void:
	if WeaponService.fantasy_should_ignore_tree_body(self, body): return
	._on_Range_body_exited(body)

func on_weapon_hit_something(thing_hit: Node, damage_dealt: int, hitbox: Hitbox) -> void:
	.on_weapon_hit_something(thing_hit, damage_dealt, hitbox)
	WeaponService.fantasy_on_weapon_hit(self, thing_hit, damage_dealt, hitbox)

func _on_weapon_critically_hit_something(_thing_hit, _damage_dealt) -> void:
	._on_weapon_critically_hit_something(_thing_hit, _damage_dealt)
	WeaponService.fantasy_on_weapon_critically_hit(self)
