extends "res://main.gd"

var FaTimers: Array = []

# ui_entry
var UIHolyScenes = {}
const UI_HOLY_SCENE = preload("res://mods-unpacked/Yoko-Fantasy/content/ui_entry/ui_holy.tscn")
var UISoulScenes = {}
const UI_SOUL_SCENE = preload("res://mods-unpacked/Yoko-Fantasy/content/ui_entry/ui_soul.tscn")
const JOB_SYSTEM = preload("res://mods-unpacked/Yoko-Fantasy/extensions/jobs/job_system.gd")
const FANTASY_SAUSAGE_BURNING_DATA_PATH: String = "res://items/all/scared_sausage/scared_sausage_burning_data.tres"
const FANTASY_LIGHTNING_SHIV_PROJECTILE_2_PATH: String = "res://weapons/melee/lightning_shiv/2/lightning_shiv_projectile_2.tres"

# =========================== Extension =========================== #
func _on_EntitySpawner_players_spawned(players: Array) -> void:
	._on_EntitySpawner_players_spawned(players)
	_fantasy_sync_special_job_runtime_effects()
	_fantasy_sync_all_job_weapon_count_effects()
	_fantasy_holy_display()
	_fantasy_soul_display()

	_fantasy_start_ui_update_timer()
	_fantasy_start_time_bonus_current_health_damage_timer()

func _on_EntitySpawner_enemy_respawned(_enemy: Enemy) -> void:
	._on_EntitySpawner_enemy_respawned(_enemy)
	call_deferred("_fantasy_change_living_cursed_enemy", _enemy, true)
	_fantasy_decaying_slow_enemy(_enemy)

func _on_enemy_died(enemy: Enemy, args: Entity.DieArgs) -> void:
	._on_enemy_died(enemy, args)
	_fantasy_change_living_cursed_enemy(enemy, false)
	_fantasy_process_dark_mage_kills(args)

func on_gold_picked_up(gold: Node, player_index: int) -> void:
	.on_gold_picked_up(gold, player_index)
	if player_index >= 0:
		_fantasy_random_reload_when_pickup_gold(player_index)

func on_upgrade_selected(upgrade_data: UpgradeData, upgrade: UpgradesUI.UpgradeToProcess) -> void:
	.on_upgrade_selected(upgrade_data, upgrade)
	# Job effects must be materialized before leaving the wave scene.
	_fantasy_sync_special_job_runtime_effects()

func _on_WaveTimer_timeout() -> void:
	_fantasy_apply_wave_end_job_rewards()
	_fantasy_queue_job_upgrades()
	._on_WaveTimer_timeout()

func clean_up_room() -> void:
	for timer in FaTimers: timer.stop()
	.clean_up_room()

# =========================== Custom =========================== #
func _fantasy_start_ui_update_timer() -> void:
	var timer = Timer.new()
	timer.wait_time = 0.2
	timer.autostart = true
	timer.connect("timeout", self , "fa_update_all_ui_stats")
	add_child(timer)
	FaTimers.append(timer)

func _fantasy_start_time_bonus_current_health_damage_timer() -> void:
	for player_index in _players.size():
		var effect_items: Array = RunData.get_player_effect(Utils.fantasy_time_bonus_current_health_damage_hash, player_index)
		for effect in effect_items:
			var timer: Timer = Timer.new()
			timer.wait_time = effect[1]
			timer.autostart = true
			timer.connect("timeout", self , "fa_time_bonus_current_health_damage", [effect[2] / 100.0, player_index, effect[0]])
			add_child(timer)
			FaTimers.append(timer)

func _fantasy_holy_display() -> void:
	for i in _players.size():
		if _players[i] in UIHolyScenes:
			continue
			
		var UIHolyInstance = UI_HOLY_SCENE.instance()
		match i:
			0, 2: UIHolyInstance.alignment = BoxContainer.ALIGN_BEGIN
			1, 3: UIHolyInstance.alignment = BoxContainer.ALIGN_END
		
		var player_ui = _players_ui[i]
		if !is_instance_valid(player_ui) or !is_instance_valid(player_ui.hud_container):
			continue

		var after_gold_index = player_ui.hud_container.get_children().find(player_ui.gold) + 1
		player_ui.hud_container.add_child(UIHolyInstance)
		player_ui.hud_container.move_child(UIHolyInstance, after_gold_index)
		
		UIHolyInstance.update_value(Utils.get_stat(Utils.stat_fantasy_holy_hash, i))

		if !UIHolyInstance.is_connected("mouse_entered", self , "fa_on_UIHoly_mouse_entered"):
			UIHolyInstance.connect("mouse_entered", self , "fa_on_UIHoly_mouse_entered", [Utils.average_all_player_stats(Utils.stat_fantasy_holy_hash)])
		if !UIHolyInstance.is_connected("mouse_exited", self , "fa_on_UIHoly_mouse_exited"):
			UIHolyInstance.connect("mouse_exited", self , "fa_on_UIHoly_mouse_exited")
		
		UIHolyScenes[_players[i]] = UIHolyInstance

func _fantasy_soul_display() -> void:
	for i in _players.size():
		var effects: Dictionary = RunData.get_player_effects(i)
		effects[Utils.stat_fantasy_soul_hash] = 0
		RunData._are_player_stats_dirty[i] = true
		Utils.reset_stat_cache(i)

		if _players[i] in UISoulScenes: continue
			
		var UISoulInstance = UI_SOUL_SCENE.instance()
		match i:
			0, 2: UISoulInstance.alignment = BoxContainer.ALIGN_BEGIN
			1, 3: UISoulInstance.alignment = BoxContainer.ALIGN_END
		
		var player_ui = _players_ui[i]
		if !is_instance_valid(player_ui) or !is_instance_valid(player_ui.hud_container): continue

		var after_gold_index = player_ui.hud_container.get_children().find(player_ui.gold) + 1
		player_ui.hud_container.add_child(UISoulInstance)
		player_ui.hud_container.move_child(UISoulInstance, after_gold_index)
		
		UISoulInstance.update_value(RunData.get_stat(Utils.stat_fantasy_soul_hash, i))
		
		if !UISoulInstance.is_connected("mouse_entered", self , "fa_on_UISoul_mouse_entered"):
			UISoulInstance.connect("mouse_entered", self , "fa_on_UISoul_mouse_entered", [i])
		if !UISoulInstance.is_connected("mouse_exited", self , "fa_on_UISoul_mouse_exited"):
			UISoulInstance.connect("mouse_exited", self , "fa_on_UISoul_mouse_exited")
		
		UISoulScenes[_players[i]] = UISoulInstance

func _fantasy_holy_process() -> void:
	for i in _players.size():
		if _players[i] in UIHolyScenes and \
		is_instance_valid(UIHolyScenes[_players[i]]):
			UIHolyScenes[_players[i]].update_value(Utils.get_stat(Utils.stat_fantasy_holy_hash, i))

func _fantasy_soul_process() -> void:
	for i in _players.size():
		if _players[i] in UISoulScenes and \
		is_instance_valid(UISoulScenes[_players[i]]):
			UISoulScenes[_players[i]].update_value(RunData.get_stat(Utils.stat_fantasy_soul_hash, i))

func _fantasy_change_living_cursed_enemy(enemy: Enemy, is_add: bool) -> void:
	var num: int = 1 if is_add else -1
	if !enemy._outline_colors.has(Utils.CURSE_COLOR): return

	for player_index in _players.size():
		Utils.ncl_quiet_add_stat(Utils.stat_fantasy_living_cursed_enemy_hash, num, player_index)
		LinkedStats.reset_player(player_index)

func _fantasy_random_reload_when_pickup_gold(player_index: int) -> void:
	var random_weapon: Weapon = Utils.get_rand_element(_players[player_index].current_weapons)
	var effect_items: Array = RunData.get_player_effect(Utils.fantasy_random_reload_when_pickup_gold_hash, player_index)

	for effect_item in effect_items:
		var chance: float = effect_item[1] / 100.0

		if !Utils.get_chance_success(chance): continue

		var tracking_key_hash: int = effect_item[0]
		RunData.ncl_add_effect_tracking_value(tracking_key_hash, 1, player_index)

		random_weapon._current_cooldown = 0
		random_weapon.tween_animation.interpolate_property(
			random_weapon.sprite, "self_modulate",
			Color("#3E68DA"), Color.white, 0.48,
			Tween.TRANS_SINE, Tween.EASE_IN_OUT
		)
		random_weapon.tween_animation.start()
		
func _fantasy_decaying_slow_enemy(enemy: Enemy) -> void:
	# For decaying slow new enemy
	for player_index in _players.size():
		var stat_nb: float = TempStats.get_stat(Utils.stat_fantasy_decaying_slow_enemy_hash, player_index)
		if stat_nb == 0: continue

		var player: Player = _players[player_index]
		enemy.current_stats.speed += int(enemy.current_stats.speed * stat_nb / 100.0)
		match enemy.sprite.material == enemy.flash_mat:
			true: player._non_decaying_slow_material[enemy] = enemy._non_flash_material
			false: player._non_decaying_slow_material[enemy] = enemy.sprite.material
		enemy.sprite.material = load("res://mods-unpacked/Yoko-Fantasy/extensions/effects/decaying_slow_enemy_when_below_hp/decaying_slow_enemy_when_below_hp_shader.tres")

func _fantasy_queue_job_upgrades() -> void:
	if !JOB_SYSTEM.ENABLE_JOB_SYSTEM:
		return

	var pending_tier: int = JOB_SYSTEM.get_pending_tier_for_wave(RunData.current_wave)
	if pending_tier == JOB_SYSTEM.JOB_PENDING_NONE:
		return

	for player_index in RunData.get_player_count():
		var effects: Dictionary = RunData.get_player_effects(player_index)
		Utils.fantasy_normalize_effect_keys(effects)
		if int(Utils.fantasy_get_effect_value(effects, Utils.fantasy_job_pending_tier_hash, JOB_SYSTEM.JOB_PENDING_NONE)) != JOB_SYSTEM.JOB_PENDING_NONE:
			continue
		if !JOB_SYSTEM.can_queue_pending_tier(player_index, pending_tier):
			continue

		Utils.fantasy_set_effect_value(effects, Utils.fantasy_job_pending_tier_hash, pending_tier)
		_fantasy_push_job_upgrade_to_queue(player_index)

func _fantasy_push_job_upgrade_to_queue(player_index: int) -> void:
	var upgrade_to_process = UpgradesUI.UpgradeToProcess.new()
	upgrade_to_process.level = RunData.get_player_level(player_index)
	upgrade_to_process.player_index = player_index

	_upgrades_to_process[player_index].push_back(upgrade_to_process)
	_things_to_process_player_containers[player_index].upgrades.add_element(
		ItemService.get_icon(Keys.icon_upgrade_to_process_hash),
		upgrade_to_process.level
	)

func _fantasy_apply_wave_end_job_rewards() -> void:
	var remaining_enemies: int = max(RunData.current_living_enemies, 0)
	if remaining_enemies <= 0:
		return

	for player_index in RunData.get_player_count():
		var effects: Dictionary = RunData.get_player_effects(player_index)
		var tier_2_job_hash: int = int(Utils.fantasy_get_effect_value(effects, Utils.fantasy_job_tier2_id_hash, 0))
		if !Utils.fantasy_hash_equals(tier_2_job_hash, Keys.generate_hash("land_lord_t2")):
			continue

		RunData.add_gold(remaining_enemies, player_index)

func fantasy_force_refresh_player_weapons(player_index: int) -> void:
	if player_index < 0 or player_index >= _players.size():
		return

	var player: Player = _players[player_index]
	if !is_instance_valid(player) or player.dead:
		return

	_stats_manager.reload_stats(player)
	for weapon in player.current_weapons:
		if !is_instance_valid(weapon):
			continue
		weapon.init_stats(false)


func _fantasy_process_dark_mage_kills(args: Entity.DieArgs) -> void:
	if !args.enemy_killed_by_player:
		return

	var player_index: int = args.killed_by_player_index
	if player_index < 0 or player_index >= RunData.get_player_count():
		return

	var effects: Dictionary = RunData.get_player_effects(player_index)
	var dark_mage_hash: int = Keys.generate_hash("dark_mage_t2")
	if !Utils.fantasy_hash_equals(int(Utils.fantasy_get_effect_value(effects, Utils.fantasy_job_tier2_id_hash, 0)), dark_mage_hash):
		return

	var kill_counter: int = int(Utils.fantasy_get_effect_value(effects, Utils.fantasy_job_dark_mage_kill_counter_hash, 0)) + 1
	var gained_curse: int = int(kill_counter / 100)
	kill_counter = kill_counter % 100
	Utils.fantasy_set_effect_value(effects, Utils.fantasy_job_dark_mage_kill_counter_hash, kill_counter)

	if gained_curse <= 0:
		return

	RunData.add_stat(Keys.stat_curse_hash, gained_curse, player_index)
	Utils.reset_stat_cache(player_index)
	LinkedStats.reset_player(player_index)

# =========================== Method =========================== #
func fa_update_all_ui_stats() -> void:
	_fantasy_sync_special_job_runtime_effects()
	_fantasy_sync_all_job_weapon_count_effects()
	_fantasy_holy_process()
	_fantasy_soul_process()

func _fantasy_sync_all_job_weapon_count_effects() -> void:
	for player_index in RunData.get_player_count():
		Utils.sync_fantasy_job_weapon_count_effects(player_index)


func _fantasy_sync_special_job_runtime_effects() -> void:
	for player_index in RunData.get_player_count():
		var effects: Dictionary = RunData.get_player_effects(player_index)
		if effects.empty():
			continue
		var effect_keys_changed: bool = Utils.fantasy_normalize_effect_keys(effects)

		var tier_2_job_hash: int = int(Utils.fantasy_get_effect_value(effects, Utils.fantasy_job_tier2_id_hash, 0))
		var is_fire_mage_selected: bool = Utils.fantasy_hash_equals(tier_2_job_hash, Keys.generate_hash("fire_mage_t2")) \
			or int(Utils.fantasy_get_effect_value(effects, Utils.fantasy_job_fire_mage_active_hash, 0)) > 0
		var is_thunder_mage_selected: bool = Utils.fantasy_hash_equals(tier_2_job_hash, Keys.generate_hash("thunder_mage_t2")) \
			or int(Utils.fantasy_get_effect_value(effects, Utils.fantasy_job_thunder_mage_active_hash, 0)) > 0 \
			or int(Utils.fantasy_get_effect_value(effects, Utils.fantasy_job_thunder_projectile_on_death_hash, 0)) > 0
		var needs_weapon_refresh: bool = false

		if is_fire_mage_selected:
			needs_weapon_refresh = _fantasy_ensure_fire_mage_runtime_effects(effects) or needs_weapon_refresh
		if is_thunder_mage_selected:
			needs_weapon_refresh = _fantasy_ensure_thunder_mage_runtime_effects(effects) or needs_weapon_refresh

		if needs_weapon_refresh or effect_keys_changed:
			RunData._are_player_stats_dirty[player_index] = true
			Utils.reset_stat_cache(player_index)
			LinkedStats.reset_player(player_index)
			if needs_weapon_refresh:
				fantasy_force_refresh_player_weapons(player_index)


func _fantasy_ensure_fire_mage_runtime_effects(effects: Dictionary) -> bool:
	var changed: bool = false

	if int(Utils.fantasy_get_effect_value(effects, Utils.fantasy_job_fire_mage_active_hash, 0)) <= 0:
		Utils.fantasy_set_effect_value(effects, Utils.fantasy_job_fire_mage_active_hash, 1)
		changed = true

	if int(Utils.fantasy_get_effect_value(effects, Keys.burning_cooldown_reduction_hash, 0)) < 50:
		Utils.fantasy_set_effect_value(effects, Keys.burning_cooldown_reduction_hash, 50)
		changed = true

	if int(Utils.fantasy_get_effect_value(effects, Keys.can_burn_enemies_hash, 0)) <= 0:
		Utils.fantasy_set_effect_value(effects, Keys.can_burn_enemies_hash, 1)
		changed = true

	var burn_chance = Utils.fantasy_get_effect_value(effects, Keys.burn_chance_hash, BurningData.new())
	if !(burn_chance is BurningData):
		burn_chance = BurningData.new()
		changed = true

	var expected_burning_data: BurningData = _fantasy_create_fire_mage_burning_data()
	if expected_burning_data == null:
		return changed

	if burn_chance.chance < expected_burning_data.chance:
		burn_chance.chance = expected_burning_data.chance
		changed = true
	if burn_chance.damage < expected_burning_data.damage:
		burn_chance.damage = expected_burning_data.damage
		changed = true
	if burn_chance.duration < expected_burning_data.duration:
		burn_chance.duration = expected_burning_data.duration
		changed = true
	if burn_chance.spread < expected_burning_data.spread:
		burn_chance.spread = expected_burning_data.spread
		changed = true
	if !burn_chance.is_global_burn:
		burn_chance.is_global_burn = true
		changed = true

	Utils.fantasy_set_effect_value(effects, Keys.burn_chance_hash, burn_chance)
	return changed


func _fantasy_ensure_thunder_mage_runtime_effects(effects: Dictionary) -> bool:
	var changed: bool = false

	if int(Utils.fantasy_get_effect_value(effects, Utils.fantasy_job_thunder_mage_active_hash, 0)) <= 0:
		Utils.fantasy_set_effect_value(effects, Utils.fantasy_job_thunder_mage_active_hash, 1)
		changed = true

	if int(Utils.fantasy_get_effect_value(effects, Utils.fantasy_job_thunder_projectile_on_death_hash, 0)) <= 0:
		Utils.fantasy_set_effect_value(effects, Utils.fantasy_job_thunder_projectile_on_death_hash, 1)
		changed = true

	return changed


func _fantasy_create_fire_mage_burning_data() -> BurningData:
	var burning_data_resource: Resource = load(FANTASY_SAUSAGE_BURNING_DATA_PATH)
	if !(burning_data_resource is BurningData):
		return null

	var duplicated_burning_data: Resource = (burning_data_resource as BurningData).duplicate(true)
	if !(duplicated_burning_data is BurningData):
		return null

	var burning_data: BurningData = duplicated_burning_data
	burning_data._late_init()
	burning_data.duration = 5
	burning_data.is_global_burn = true
	return burning_data


func _fantasy_create_thunder_projectile_stats() -> RangedWeaponStats:
	var projectile_stats_resource: Resource = load(FANTASY_LIGHTNING_SHIV_PROJECTILE_2_PATH)
	if !(projectile_stats_resource is RangedWeaponStats):
		return null

	var duplicated_projectile_stats: Resource = (projectile_stats_resource as RangedWeaponStats).duplicate(true)
	if !(duplicated_projectile_stats is RangedWeaponStats):
		return null

	var projectile_stats: RangedWeaponStats = duplicated_projectile_stats
	projectile_stats.damage = 12
	projectile_stats.bounce = 4
	return projectile_stats

func fa_on_UIHoly_mouse_entered(stat_holy: int) -> void:
	var damage_bonus: int = stat_holy
	var chance_drop_soul: int = int(stat_holy / (stat_holy + 50.0) * 100)
	var enemy_health_reduction: int = int(stat_holy / (stat_holy + 100.0) * 100)
	_info_popup.display(_ui_bonus_gold, Text.text("FANTASY_INFO_HOLY", [str(damage_bonus), str(chance_drop_soul), str(enemy_health_reduction)]))

func fa_on_UIHoly_mouse_exited() -> void:
	_info_popup.hide()

func fa_on_UISoul_mouse_entered(player_index: int) -> void:
	var bonus: int = 20 + RunData.get_player_effect(Utils.fantasy_soul_bonus_hash, player_index)
	_info_popup.display(_ui_bonus_gold, Text.text("FANTASY_INFO_SOUL", [str(bonus), str(bonus)]))

func fa_on_UISoul_mouse_exited() -> void:
	_info_popup.hide()

func fa_time_bonus_current_health_damage(bonus: float, player_index: int, tracking_key_hash: int):
	var enemies: Array = _entity_spawner.get_all_enemies(false)
	for enemy in enemies:
		var enemy_current_hp: int = enemy.current_stats.health
		var enemy_max_hp: int = enemy.max_stats.health

		if enemy_current_hp == 1: continue
		
		var full_dmg_value: int = 0
		if enemy is Boss:
			full_dmg_value += int(enemy_current_hp * bonus / 10.0)
			enemy.current_stats.health -= full_dmg_value
		else:
			full_dmg_value += int(enemy_current_hp * bonus)
			enemy.current_stats.health -= full_dmg_value
		
		RunData.add_tracked_value(player_index, tracking_key_hash, full_dmg_value)
		enemy.emit_signal("health_updated", enemy, enemy.current_stats.health, enemy_max_hp)

		var time_bonus_args: TakeDamageArgs = TakeDamageArgs.new(player_index)
		enemy.emit_signal(
			"took_damage",
			enemy,
			full_dmg_value,
			Vector2.ZERO,
			false,
			false,
			false,
			false,
			time_bonus_args,
			HitType.NORMAL,
			false
		)
