extends "res://weapons/melee/melee_weapon.gd"

var melee_shooting_cancelled: bool = true

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
	_fantasy_projectiles_every_x_melee_shoot()

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

# =========================== Melee Only =========================== #
func _fantasy_projectiles_every_x_melee_shoot() -> void:
	for effect in effects:
		if effect.get_id() != "fantasy_projectiles_every_x_melee_shoot" or \
		_nb_shots_taken % effect.value != 0: continue

		melee_shooting_cancelled = true
		var projs_per_frame: int = effect.projectiles_per_frame

		var args: WeaponServiceInitStatsArgs = WeaponServiceInitStatsArgs.new()
		args.effects = effects
		var proj_stats: RangedWeaponStats = WeaponService.init_ranged_stats(effect.projectile_stats, player_index, false, args)
		var proj_args: WeaponServiceSpawnProjectileArgs = WeaponServiceSpawnProjectileArgs.new()
		var proj_pos: Vector2 = muzzle.global_position

		if !proj_stats.shooting_sounds.empty(): SoundManager2D.play(Utils.get_rand_element(proj_stats.shooting_sounds), proj_pos, 0, 0.2)

		proj_args.effects = effects
		proj_args.damage_tracking_key_hash = _hitbox.damage_tracking_key_hash
		proj_args.from_player_index = player_index

		melee_shooting_cancelled = false
		_fantasy_spawn_melee_projectils(proj_stats, proj_pos, proj_args, projs_per_frame)

func _fantasy_spawn_melee_projectils(proj_stats: RangedWeaponStats, proj_pos: Vector2, proj_args: WeaponServiceSpawnProjectileArgs, projs_per_frame: int) -> void:
		var projs_this_frame: int = 0

		for _i in range(proj_stats.nb_projectiles):
			if melee_shooting_cancelled: return

			var proj_rotation: float = rand_range(rotation - proj_stats.projectile_spread, rotation + proj_stats.projectile_spread)
			var proj_knockback: Vector2 = Vector2(cos(proj_rotation), sin(proj_rotation))
			proj_args.knockback_direction = proj_knockback

			var projectile: PlayerProjectile = WeaponService.spawn_projectile(
				proj_pos,
				proj_stats,
				proj_rotation,
				self ,
				proj_args
			)

			projectile._hitbox.player_attack_id = _hitbox.player_attack_id

			if !effects.empty() or !RunData.get_player_effect(Keys.gain_stat_when_attack_killed_enemies_hash, player_index).empty():
				if !projectile.killed_something_connected:
					var _killed_sthing = projectile._hitbox.connect("killed_something", self , "on_killed_something", [projectile._hitbox])
					projectile.killed_something_connected = true

			if !projectile.hit_something_connected:
				var _hit_sthing = projectile.connect("hit_something", self , "on_weapon_hit_something", [projectile._hitbox])
				projectile.hit_something_connected = true

			if !projectile.critically_hit_something_connected:
				var _crit_hit_sthing = projectile.connect("critically_hit_something", self , "_on_weapon_critically_hit_something")
				projectile.critically_hit_something_connected = true

			projs_this_frame += 1
			if projs_this_frame < projs_per_frame: continue

			yield (get_tree(), "idle_frame")
			projs_this_frame = 0
