extends Pet

const COOLDOWN_VAR_NAMES: Array = [
	"_cooldown", "_current_cooldown", "_current_ranged_cooldown",
	"_current_ultime_cooldown", "_landmines_cooldown",
	"_left_cooldown", "_right_cooldown",
]

export(int) var max_num: int = 8
export(String) var damage_tracking_id
var damage_tracking_id_hash: int = Keys.empty_hash
export(Color) var damage_color = Color("#F5D35E")
export(bool) var has_shoot_anim = false

var _base_weapon_stats: RangedWeaponStats = RangedWeaponStats.new()
var _current_weapon_stats: RangedWeaponStats = RangedWeaponStats.new()

var _cooldown: float = 0.0
var _is_shooting: bool = false

# ══════════════════════════════════════════ Extension ══════════════════════════════════════════ #
func init(zone_min_pos: Vector2, zone_max_pos: Vector2, p_players_ref: Array = [], entity_spawner_ref = null) -> void:
	.init(zone_min_pos, zone_max_pos, p_players_ref, entity_spawner_ref)
	damage_tracking_id_hash = Keys.generate_hash(damage_tracking_id)

func update_data(effect: PetEffect) -> void:
	.update_data(effect)
	_base_weapon_stats = effect.weapon_stats

	reload_data()

	_cooldown = _current_weapon_stats.cooldown

func should_data_be_reload() -> bool:
	return true

func reload_data():
	var args := WeaponServiceInitStatsArgs.new()
	_current_weapon_stats = WeaponService.init_ranged_pet_stats(_base_weapon_stats, player_index, false, args)
	_current_weapon_stats.burning_data.from = self

func set_current_stats(stats: Array) -> void:
	_current_weapon_stats = stats[0]
	_current_weapon_stats.burning_data.from = self

func get_stats() -> Array:
	return [_current_weapon_stats]

func _physics_process(delta) -> void:
	if dead: return

	_cooldown -= Utils.physics_one(delta)

	if _cooldown > 0 or _is_shooting: return

	if !fa_has_valid_enemy():
		return

	_is_shooting = true
	if has_shoot_anim: _animation_player.play("shoot")
	else: shoot()

func shoot() -> void:
	var enemies: Array = entity_spawner.get_all_enemies(false)

	if enemies.empty():
		_is_shooting = false
		return

	var crit_chance: float = _current_weapon_stats.crit_chance
	var crit_damage: float = _current_weapon_stats.crit_damage
	var damage: int = _current_weapon_stats.damage
	var damage_args: TakeDamageArgs = null
	if Utils.get_chance_success(crit_chance):
		damage = int(damage * crit_damage)
		damage_args = Utils.ncl_create_custom_damage_args(player_index, damage_color)
	else: damage_args = TakeDamageArgs.new(player_index)

	var targets: Array = fa_get_highest_health_enemies(enemies)
	for enemy in targets:

		if !enemy.is_connected("died", self , "fa_on_wolf_totem_killed_best_enemy"):
			enemy.connect("died", self , "fa_on_wolf_totem_killed_best_enemy", [], CONNECT_ONESHOT)

		var take_damage_array: Array = enemy.take_damage(damage, damage_args)
		var actual_damage: int = take_damage_array[1]
		RunData.add_tracked_value(player_index, damage_tracking_id_hash, actual_damage)

	if has_shoot_anim: return

	_cooldown = _current_weapon_stats.cooldown
	_is_shooting = false

# ══════════════════════════════════════════ Method ══════════════════════════════════════════ #
func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	if anim_name == "shoot" and !dead:
		_cooldown = _current_weapon_stats.cooldown
		_is_shooting = false
		_animation_player.play("idle")

func fa_on_wolf_totem_killed_best_enemy(_entity: Entity, _die_args: Entity.DieArgs) -> void:
	for pet in entity_spawner.pets:
		if !is_instance_valid(pet): continue

		for cooldown_var_name in COOLDOWN_VAR_NAMES:
			if pet.get(cooldown_var_name) == null:
				continue

			pet.set(cooldown_var_name, 0.0)

func fa_get_highest_health_enemies(enemies: Array) -> Array:
	var targets: Array = []
	var target_limit: int = int(max(0, max_num))
	if target_limit == 0: return targets

	for enemy in enemies:
		if !is_instance_valid(enemy) or !(enemy is Enemy) or enemy.dead: continue

		var insert_index: int = targets.size()
		for i in range(targets.size()):
			if enemy.current_stats.health > targets[i].current_stats.health:
				insert_index = i
				break

		if insert_index >= target_limit: continue

		targets.insert(insert_index, enemy)
		if targets.size() > target_limit:
			targets.pop_back()

	return targets

func fa_has_valid_enemy() -> bool:
	for enemy in entity_spawner.get_all_enemies(false):
		if is_instance_valid(enemy) and enemy is Enemy and !enemy.dead:
			return true
	return false
