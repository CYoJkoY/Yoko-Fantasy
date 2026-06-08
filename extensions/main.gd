extends "res://main.gd"

const UpgradeHooks = preload("res://mods-unpacked/Yoko-Fantasy/extensions/services/upgrade_hooks.gd")
const LightningChainService = preload("res://mods-unpacked/Yoko-Fantasy/extensions/services/lightning_chain_service.gd")

var FaTimers: Array = []
var summoned_twins: Array = []
var cursed_enemies: Array = []

# =========================== Extension =========================== #
func _ready() -> void:
	_fantasy_connect_effect()
	_fantasy_queue_job_upgrades()
	_fantasy_start_time_bonus_current_health_damage_timer()

func on_bonus_gold_changed(value: int) -> void:
	.on_bonus_gold_changed(value)
	if value != 0: _ui_bonus_gold.show()

func on_upgrade_selected(upgrade_data: UpgradeData, upgrade: UpgradesUI.UpgradeToProcess) -> void:
	UpgradeHooks.fa_handle_selected_upgrade_hooks(upgrade_data, upgrade.player_index, "normal_upgrade")
	.on_upgrade_selected(upgrade_data, upgrade)
	_fantasy_add_job(upgrade_data, upgrade.player_index)

func _on_EntitySpawner_players_spawned(players: Array) -> void:
	._on_EntitySpawner_players_spawned(players)
	_fantasy_teleport_if_world_tree_enemy(players)
	# This signal is called before fog wave judgment
	call_deferred("_fantasy_sacrificial_circle", players)
	call_deferred("_fantasy_clock_tower_area", players)

func _on_EntitySpawner_enemy_spawned(enemy: Enemy) -> void:
	._on_EntitySpawner_enemy_spawned(enemy)
	_fantasy_twin_connect(enemy)

func _on_EntitySpawner_enemy_respawned(_enemy: Enemy) -> void:
	._on_EntitySpawner_enemy_respawned(_enemy)
	call_deferred("_fantasy_change_living_cursed_enemy", _enemy, true)
	_fantasy_decaying_slow_enemy(_enemy)

func _on_enemy_died(enemy: Enemy, args: Entity.DieArgs) -> void:
	._on_enemy_died(enemy, args)
	_fantasy_lightning_chain_on_death(enemy)
	_fantasy_change_living_cursed_enemy(enemy, false)

func on_gold_picked_up(gold: Node, player_index: int) -> void:
	.on_gold_picked_up(gold, player_index)
	if player_index >= 0:
		_fantasy_random_reload_when_pickup_gold(player_index)

func clean_up_room() -> void:
	for timer in FaTimers: timer.stop()
	.clean_up_room()
	_fantasy_clear_living_cursed_enemy()

func _on_EndWaveTimer_timeout() -> void:
	_coop_upgrades_ui.propagate_call("set_process_input", [true])
	DebugService.log_data("_on_EndWaveTimer_timeout")
	SoundManager.clear_queue()
	SoundManager2D.clear_queue()
	InputService.set_gamepad_echo_processing(true)

	_end_wave_timer_timedout = true

	if _is_wave_failed and RunData.current_wave > 0:
		_retry_wave.show()
		_pause_menu.enabled = false
		return

	_wave_cleared_label.hide()
	_wave_timer_label.hide()

	_camera.move_speed_factor = 0.0
	_camera.zoom_in_speed_factor = 0.0
	_camera.zoom_out_speed_factor = 0.0

	RunData.on_wave_end()
	LinkedStats.reset()

	var scene: String
	var _args: Entity.DieArgs = Utils.default_die_args
	if _is_run_lost or _is_run_won:
		DebugService.log_data("end run...")
		MusicManager.fa_clear_override()
		scene = RunData.get_end_run_scene_path()
	else:
		DebugService.log_data("process fantasy jobs, consumables and upgrades...")
		MusicManager.tween( - 8)

		if RunData.is_coop_run:
			_hud.hide()
			if _coop_upgrades_ui.call("show_fantasy_job_options"):
				yield(_coop_upgrades_ui, "fantasy_jobs_processed")
			_fantasy_clear_job_process_icons()
			if _coop_upgrades_ui.show_options(_consumables_to_process, _upgrades_to_process):
				yield(_coop_upgrades_ui, "options_processed")
			_coop_upgrades_ui.hide()
		else:
			if _upgrades_ui.call("show_fantasy_job_options"):
				yield(_upgrades_ui, "fantasy_jobs_processed")
			_fantasy_clear_job_process_icons()
			if _upgrades_ui.show_options(_consumables_to_process, _upgrades_to_process):
				var things_to_process_player_container = _things_to_process_player_containers[0]
				var ui_consumables_to_process = things_to_process_player_container.consumables
				var ui_upgrades_to_process = things_to_process_player_container.upgrades
				while not ui_consumables_to_process.is_empty():
					var consumable = yield(_upgrades_ui, "consumable_selected")
					ui_consumables_to_process.remove_element(consumable.consumable_data)
				while not ui_upgrades_to_process.is_empty():
					var args = yield(_upgrades_ui, "upgrade_selected")
					var upgrade = args[1]
					ui_upgrades_to_process.remove_element(upgrade.level)
				yield(_upgrades_ui, "options_processed")
			_upgrades_ui.hide()

		DebugService.log_data("display challenge ui...")
		if _is_chal_ui_displayed:
			yield(_challenge_completed_ui, "finished")

		scene = RunData.get_shop_scene_path()

	_change_scene(scene)

# =========================== Custom =========================== #
func _fantasy_start_time_bonus_current_health_damage_timer() -> void:
	for player_index in range(_players.size()):
		var effect_items: Array = RunData.get_player_effect(Utils.fantasy_time_bonus_current_health_damage_hash, player_index)
		for effect in effect_items:
			var timer: Timer = Timer.new()
			timer.wait_time = effect[1]
			timer.autostart = true
			timer.connect("timeout", self , "fa_time_bonus_current_health_damage", [effect[2] / 100.0, player_index, effect[0]])
			add_child(timer)
			FaTimers.append(timer)

func _fantasy_change_living_cursed_enemy(enemy: Enemy, is_add: bool) -> void:
	if !enemy._outline_colors.has(Utils.CURSE_COLOR): return

	var num: int = 0
	match is_add:
		true:
			num = 1
			cursed_enemies.append(enemy)
			_fantasy_slow_cursed_enemy(enemy)
		false:
			num = -1
			cursed_enemies.erase(enemy)

	for player_index in range(_players.size()):
		Utils.ncl_quiet_add_stat(Utils.fantasy_living_cursed_enemy_hash, num, player_index)
		LinkedStats.reset_player(player_index)

func _fantasy_clear_living_cursed_enemy() -> void:
	cursed_enemies.clear()
	for player_index in range(_players.size()):
		Utils.ncl_quiet_set_stat(Utils.fantasy_living_cursed_enemy_hash, 0, player_index)
		LinkedStats.reset_player(player_index)

func _fantasy_random_reload_when_pickup_gold(player_index: int) -> void:
	var random_weapon: Weapon = Utils.get_rand_element(_players[player_index].current_weapons)
	var effect_items: Array = RunData.get_player_effect(Utils.fantasy_random_reload_when_pickup_gold_hash, player_index)

	if random_weapon == null: return

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

func _fantasy_lightning_chain_on_death(enemy: Enemy) -> void:
	if enemy == null:
		return

	for player_index in range(_players.size()):
		var effect_items: Array = RunData.get_player_effect(Utils.fantasy_lightning_chain_on_death_hash, player_index)
		for effect_item in effect_items:
			var chance: float = effect_item[0]
			if !Utils.get_chance_success(chance):
				continue

			var params: Dictionary = LightningChainService.build_params_from_array(effect_item, player_index)
			LightningChainService.spawn_lightning_chain(
				self,
				enemy,
				player_index,
				params.damage,
				params.chain_targets,
				params.chain_damage_mult,
				params.arc_width,
				params.arc_jaggedness,
				params.arc_color,
				params.arc_glow_color,
				params.arc_duration,
				params.arc_crit_chance,
				params.arc_crit_damage,
				[],
				params.damage_scaling_stats,
				params.arc_scene_path
			)
		
func _fantasy_decaying_slow_enemy(enemy: Enemy) -> void:
	# For decaying slow new enemy
	for player_index in range(_players.size()):
		var slow_percent: float = TempStats.get_stat(Utils.stat_fantasy_decaying_slow_enemy_hash, player_index)
		if slow_percent == 0: continue

		var player: Player = _players[player_index]
		player._original_non_decaying_slow_speed[enemy] = enemy.current_stats.speed
		enemy.current_stats.speed += int(enemy.current_stats.speed * slow_percent / 100.0)
		match enemy.sprite.material == enemy.flash_mat:
			true: player._non_decaying_slow_material[enemy] = enemy._non_flash_material
			false: player._non_decaying_slow_material[enemy] = enemy.sprite.material
		enemy.sprite.material = load("res://mods-unpacked/Yoko-Fantasy/extensions/effects/decaying_slow_enemy_when_below_hp/decaying_slow_enemy_when_below_hp_shader.tres")
		# Speed will reset when timeout

func _fantasy_twin_connect(enemy: Enemy) -> void:
	match [enemy.enemy_id, summoned_twins.has(enemy.pool_id)]:
		["fantasy_twin_blaze", false]:
			var scene: PackedScene = load("res://mods-unpacked/Yoko-Fantasy/content/entities/enemies/twin_frost/twin_frost.tscn")
			summoned_twins.append(scene.get_instance_id())
			var args: EntitySpawner.SpawnEntityArgs = EntitySpawner.SpawnEntityArgs.new(enemy.global_position, EntityType.BOSS)
			var _new_enemy: Enemy = _entity_spawner.spawn_entity(scene, args)

			var _error_twin_state_connect_1: int = enemy.connect("state_changed", _new_enemy, "fa_change_state")
			var _error_twin_dead_change_state_connect_1: int = enemy.connect("died", _new_enemy, "fa_died_change_state")

			var _error_twin_state_connect_2: int = _new_enemy.connect("state_changed", enemy, "fa_change_state")
			var _error_twin_dead_change_state_connect_2: int = _new_enemy.connect("died", enemy, "fa_died_change_state")

		["fantasy_twin_frost", false]:
			var scene: PackedScene = load("res://mods-unpacked/Yoko-Fantasy/content/entities/enemies/twin_blaze/twin_blaze.tscn")
			summoned_twins.append(scene.get_instance_id())
			var args: EntitySpawner.SpawnEntityArgs = EntitySpawner.SpawnEntityArgs.new(enemy.global_position, EntityType.BOSS)
			var _new_enemy: Enemy = _entity_spawner.spawn_entity(scene, args)

			var _error_twin_state_connect: int = enemy.connect("state_changed", _new_enemy, "fa_change_state")
			var _error_twin_dead_change_state_connect: int = enemy.connect("died", _new_enemy, "fa_died_change_state")

			var _error_twin_state_connect_2: int = _new_enemy.connect("state_changed", enemy, "fa_change_state")
			var _error_twin_dead_change_state_connect_2: int = _new_enemy.connect("died", enemy, "fa_died_change_state")

func _fantasy_slow_cursed_enemy(enemy: Enemy) -> void:
	for player_index in range(_players.size()):
		var slow_percent: int = RunData.get_player_effect(Utils.fantasy_slow_cursed_enemy_hash, player_index)
		enemy.current_stats.speed += int(enemy.current_stats.speed * slow_percent / 100.0)

func _fantasy_add_job(job_data: UpgradeData, player_index: int) -> void:
	if job_data.get("stage") == null: return

	RunData.fa_add_job(job_data, player_index)

func _fantasy_connect_effect() -> void:
	var _error_on_soul_effect: int = RunData.connect("on_soul_effect", self , "fa_on_soul_effect")

func _fantasy_queue_job_upgrades() -> void:
	for player_index in range(_players.size()):
		if RunData.fa_has_pending_job_selection(player_index): continue

		if RunData.current_wave == 5:
			if !RunData.fa_has_s1_job(player_index):
				fa_queue_job_selection(player_index, 0)

		elif RunData.current_wave == 10 or RunData.current_wave == 15:
			if RunData.fa_get_s2_job_count(player_index) < 2:
				fa_queue_job_selection(player_index, 1)

func _fantasy_clear_job_process_icons() -> void:
	for player_index in range(_things_to_process_player_containers.size()):
		var upgrades_to_process = _things_to_process_player_containers[player_index].upgrades
		var levels: Array = upgrades_to_process._elements.duplicate()
		for level in levels:
			# Single-player end-wave flow waits on this UI list, so job icons must not leak into vanilla upgrade handling.
			if RunData.fa_is_job_ui_level(level):
				upgrades_to_process.remove_element(level)

func _fantasy_teleport_if_world_tree_enemy(players: Array) -> void:
	for group_data in _wave_manager.current_wave_data.groups_data:
		for enemy in group_data.wave_units_data:
			if enemy.unit_scene_name != "world_tree.tscn": continue

			var base_pos: Vector2 = ZoneService.get_rand_pos(200)
			var player_count: int = players.size()
			for player_index in range(player_count):
				if player_count > 1:
					players[player_index].global_position = Vector2(
						base_pos.x - 100 + (player_index % 2) * 100,
						base_pos.y + ((player_index / 2) % 2) * 100
					)
				else:
					players[player_index].global_position = base_pos

func _fantasy_sacrificial_circle(players: Array) -> void:
	var player_count: int = players.size()
	for player_index in range(player_count):
		var sacrificial_circles: Array = RunData.get_player_effect(Utils.fantasy_sacrificial_circle_hash, player_index)
		if sacrificial_circles.empty(): continue

		for sacrificial_circle in sacrificial_circles:
			var sacrificial_circle_node: Area2D = load("res://mods-unpacked/Yoko-Fantasy/content/specials/player/sacrificial_circle/sacrificial_circle.tscn").instance()
			var center_pos: Vector2 = ZoneService.get_map_center()
			_materials_container.add_child(sacrificial_circle_node.init(self , player_index, center_pos, sacrificial_circle))

func _fantasy_clock_tower_area(players: Array) -> void:
	var player_count: int = players.size()
	for player_index in range(player_count):
		var clock_tower_areas: Array = RunData.get_player_effect(Utils.fantasy_clock_tower_area_hash, player_index)
		if clock_tower_areas.empty(): continue

		for clock_tower_area in clock_tower_areas:
			var base_range: int = clock_tower_area[0]
			var range_rate: float = clock_tower_area[1] / 100.0
			var total_range: float = Utils.fa_get_clock_tower_area_radius(base_range, range_rate, player_index)
			var clock_tower_area_node: Area2D = load("res://mods-unpacked/Yoko-Fantasy/content/specials/player/clock_tower_area/clock_tower_area.tscn").instance()
			var center_pos: Vector2 = ZoneService.get_map_center()
			_materials_container.add_child(clock_tower_area_node.init(self , player_index, center_pos, total_range, base_range, range_rate))

# =========================== Method =========================== #
func fa_time_bonus_current_health_damage(bonus: float, player_index: int, tracking_key_hash: int) -> void:
	var enemies: Array = _entity_spawner.get_all_enemies(false)
	for enemy in enemies:
		var enemy_max_hp: int = enemy.max_stats.health

		var full_dmg_value: int = 0
		if enemy is Boss: full_dmg_value += int(enemy_max_hp * bonus / 10.0)
		else: full_dmg_value += int(enemy_max_hp * bonus)

		var damage_args: TakeDamageArgs = Utils.ncl_create_custom_damage_args(player_index, Color("#FFA500"))
		var take_damage_array: Array = enemy.take_damage(full_dmg_value, damage_args)
		RunData.add_tracked_value(player_index, tracking_key_hash, take_damage_array[1])

func fa_on_soul_effect(damage_to_add: int, speed_to_add: int, player_index: int) -> void:
	_players[player_index].fa_on_soul_effect(damage_to_add, speed_to_add)

func fa_queue_job_selection(player_index: int, job_stage: int) -> void:
	var ui_level: int = RunData.fa_queue_pending_job_selection(player_index, job_stage, RunData.current_wave)

	_things_to_process_player_containers[player_index].upgrades.add_element(ItemService.get_icon(Utils.icon_fantasy_job_to_process_hash), ui_level)
