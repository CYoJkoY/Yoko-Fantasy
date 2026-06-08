extends Area2D

export (float) var base_radius: float = 350.0
export (float) var source_radius: float = 236.0
export (bool) var animate: bool = true

var main: Main = null
var player_index: int = -1
var pos: Vector2 = Vector2.ZERO
var area_base_range: int = 350
var area_range_rate: float = 0.65
var _enemy_speed_percent: int = -10
var _structure_attack_speed_bonus_applied: int = 0
var _player_in_area: bool = false
var _time: float = 0.0
var _affected_enemies: Dictionary = {}
var _affected_projectiles: Dictionary = {}
var _gear_speeds: Dictionary = {
	"GearTopCenterS": 0.37,
	"GearTopRightS": -0.60,
	"GearUpperLowerM": -0.31,
	"GearTopLeftL": 0.42,
	"GearMiddleRightS": 1.55,
	"GearMiddleTopS": -1.45,
	"GearMiddleLeftM": 0.70,
	"GearMiddleBottomM": -0.58,
	"GearBottomCenterL": 0.17,
}
var _shadow_phases: Dictionary = {
	"Shadow1": 0.0,
	"Shadow2": 2.1,
	"Shadow3": 4.2,
}
var _shadow_alpha_ranges: Dictionary = {
	"Shadow1": [0.08, 0.58],
	"Shadow2": [0.04, 0.44],
	"Shadow3": [0.02, 0.34],
}

onready var gears: Node2D = $Visual/Gears
onready var shadows: Node2D = $Visual/Shadows
onready var collision: CollisionShape2D = $Collision

func init(_main: Main, _player_index: int, _pos: Vector2, radius: float = -1.0, _base_range: int = 350, _range_rate: float = 0.65) -> Area2D:
	main = _main
	player_index = _player_index
	pos = _pos
	area_base_range = _base_range
	area_range_rate = _range_rate
	if radius > 0.0:
		base_radius = radius
	return self


func _ready() -> void:
	global_position = pos
	set_area_radius(base_radius)
	_enemy_speed_percent = Utils.fa_get_clock_tower_enemy_speed_percent(player_index)
	_update_player_area_state()

func _exit_tree() -> void:
	_remove_structure_attack_speed_bonus()
	Utils.fa_set_clock_tower_player_in_area(player_index, false)
	for enemy in _affected_enemies.keys():
		_restore_enemy(enemy)
	for projectile in _affected_projectiles.keys():
		_restore_projectile(projectile)

func _process(delta: float) -> void:
	_time += delta
	if animate:
		_update_gears(delta)
		_update_shadows()
	_refresh_area_radius()
	_update_player_area_state()
	_refresh_structure_attack_speed_bonus()
	_refresh_enemy_speed_percent()


func set_area_radius(radius: float) -> void:
	var safe_radius: float = max(radius, 1.0)
	base_radius = safe_radius
	var visual_scale: float = safe_radius / source_radius
	$Visual.scale = Vector2.ONE * visual_scale
	collision.shape.radius = safe_radius


func _refresh_area_radius() -> void:
	var new_radius: float = Utils.fa_get_clock_tower_area_radius(area_base_range, area_range_rate, player_index)
	if abs(new_radius - base_radius) < 0.1:
		return

	set_area_radius(new_radius)


func _update_gears(delta: float) -> void:
	for gear_name in _gear_speeds.keys():
		if gears == null or !gears.has_node(gear_name):
			continue
		var gear := gears.get_node(gear_name) as Node2D
		gear.rotation += float(_gear_speeds[gear_name]) * delta


func _update_shadows() -> void:
	for shadow_name in _shadow_phases.keys():
		if shadows == null or !shadows.has_node(shadow_name):
			continue
		var shadow := shadows.get_node(shadow_name) as Sprite
		var phase := float(_shadow_phases[shadow_name])
		var alpha_range: Array = _shadow_alpha_ranges.get(shadow_name, [0.08, 0.5])
		var pulse := 0.5 + 0.5 * sin(_time * 2.16 + phase)
		shadow.modulate.a = float(alpha_range[0]) + pulse * (float(alpha_range[1]) - float(alpha_range[0]))


func _update_player_area_state() -> void:
	if main == null or player_index < 0 or player_index >= main._players.size():
		_set_player_in_area(false)
		return

	var player: Node2D = main._players[player_index]
	if !is_instance_valid(player) or player.dead:
		_set_player_in_area(false)
		return

	_set_player_in_area(player.global_position.distance_to(global_position) <= base_radius)


func _set_player_in_area(in_area: bool) -> void:
	if _player_in_area == in_area:
		return

	_player_in_area = in_area
	Utils.fa_set_clock_tower_player_in_area(player_index, in_area)
	if in_area:
		_apply_structure_attack_speed_bonus()
	else:
		_remove_structure_attack_speed_bonus()


func _apply_structure_attack_speed_bonus() -> void:
	if player_index < 0:
		return

	var new_bonus: int = Utils.fa_get_clock_tower_structure_attack_speed_bonus(player_index)
	if new_bonus == _structure_attack_speed_bonus_applied:
		return

	_remove_structure_attack_speed_bonus()
	if new_bonus <= 0:
		return

	TempStats.add_stat(Keys.structure_attack_speed_hash, new_bonus, player_index)
	_structure_attack_speed_bonus_applied = new_bonus


func _remove_structure_attack_speed_bonus() -> void:
	if _structure_attack_speed_bonus_applied == 0 or player_index < 0:
		_structure_attack_speed_bonus_applied = 0
		return

	TempStats.remove_stat(Keys.structure_attack_speed_hash, _structure_attack_speed_bonus_applied, player_index)
	_structure_attack_speed_bonus_applied = 0


func _refresh_structure_attack_speed_bonus() -> void:
	if _player_in_area:
		_apply_structure_attack_speed_bonus()


func _get_speed_multiplier() -> float:
	return max(0.05, 1.0 + float(_enemy_speed_percent) / 100.0)


func _refresh_enemy_speed_percent() -> void:
	var new_enemy_speed_percent: int = Utils.fa_get_clock_tower_enemy_speed_percent(player_index)
	if new_enemy_speed_percent == _enemy_speed_percent:
		return

	_enemy_speed_percent = new_enemy_speed_percent
	var speed_multiplier: float = _get_speed_multiplier()
	for enemy in _affected_enemies.keys():
		if !is_instance_valid(enemy) or enemy.dead:
			continue
		enemy.current_stats.speed = int(_affected_enemies[enemy] * speed_multiplier)

	for projectile in _affected_projectiles.keys():
		if !is_instance_valid(projectile):
			continue
		if !(projectile.get("velocity") is Vector2):
			continue
		projectile.velocity = _affected_projectiles[projectile] * speed_multiplier


func _slow_enemy(enemy: Node) -> void:
	if _affected_enemies.has(enemy) or !is_instance_valid(enemy) or enemy.dead:
		return

	var original_speed: int = enemy.current_stats.speed
	_affected_enemies[enemy] = original_speed
	enemy.current_stats.speed = int(original_speed * _get_speed_multiplier())


func _restore_enemy(enemy: Node) -> void:
	if !_affected_enemies.has(enemy):
		return

	var original_speed: int = _affected_enemies[enemy]
	_affected_enemies.erase(enemy)
	if !is_instance_valid(enemy) or enemy.dead:
		return

	enemy.current_stats.speed = original_speed


func _slow_projectile(projectile: Node) -> void:
	if _affected_projectiles.has(projectile) or !is_instance_valid(projectile):
		return
	var original_velocity = projectile.get("velocity")
	if !(original_velocity is Vector2):
		return

	_affected_projectiles[projectile] = original_velocity
	projectile.velocity = original_velocity * _get_speed_multiplier()


func _restore_projectile(projectile: Node) -> void:
	if !_affected_projectiles.has(projectile):
		return

	var original_velocity: Vector2 = _affected_projectiles[projectile]
	_affected_projectiles.erase(projectile)
	if !is_instance_valid(projectile):
		return
	if !(projectile.get("velocity") is Vector2):
		return

	projectile.velocity = original_velocity


func fa_on_ClockTowerArea_body_entered(body: Node) -> void:
	if body is Enemy:
		_slow_enemy(body)


func fa_on_ClockTowerArea_body_exited(body: Node) -> void:
	_restore_enemy(body)


func fa_on_ClockTowerArea_area_entered(area: Area2D) -> void:
	var projectile: Node = area.get_parent()
	if projectile is EnemyProjectile:
		_slow_projectile(projectile)


func fa_on_ClockTowerArea_area_exited(area: Area2D) -> void:
	_restore_projectile(area.get_parent())
