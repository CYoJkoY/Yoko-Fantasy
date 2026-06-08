extends Node2D

var start_point: Vector2
var end_point: Vector2
var width: float = 4.0
var jaggedness: float = 20.0
var color: Color = Color.white
var glow_color: Color = Color.white
var duration: float = 0.3
var crit_chance: float = 0.0
var crit_damage: float = 1.5

onready var line: Line2D = $"Line"
onready var glow_line: Line2D = $"GlowLine"
onready var duration_timer: Timer = $"Timer"

# =========================== Extension =========================== #
func _ready() -> void:
	reset()

func reset() -> void:
	hide()
	set_process(false)
	set_as_toplevel(true)
	position = Vector2.ZERO
	modulate.a = 1.0
	start_point = Vector2.ZERO
	end_point = Vector2.ZERO
	line.points = PoolVector2Array()
	glow_line.points = PoolVector2Array()

func link(
	enemies: Array,
	damage: int,
	chain_damage_mult: float,
	player_index: int,
	_width: float,
	_jaggedness: float,
	_color: Color,
	_glow_color: Color,
	_duration: float,
	_crit_chance: float,
	_crit_damage: float,
	parent_effects: Array,
	damage_scaling_stats: Array
) -> int:
	var true_damage: int = 0
	if enemies.size() < 2: return true_damage

	width = _width
	jaggedness = _jaggedness
	color = _color
	glow_color = _glow_color
	duration = _duration
	crit_chance = _crit_chance
	crit_chance += Utils.get_capped_stat(Keys.stat_crit_chance_hash, player_index) / 100.0 \
		if RunData.get_player_effect_bool(Utils.fantasy_lightning_chain_can_crit_hash, player_index) else 0.0
	crit_damage = _crit_damage

	var dmg_args: TakeDamageArgs = TakeDamageArgs.new(player_index)
	dmg_args.set_meta("custom_color", color)

	for i in range(1, enemies.size()):
		var enemy: Enemy = enemies[i]
		if !is_instance_valid(enemy) or enemy.dead: continue

		var final_damage: float = damage * pow(chain_damage_mult, i - 1)

		if Utils.get_chance_success(crit_chance):
			final_damage *= crit_damage

			var gold_on_crit_kill_effects: Array = RunData.get_player_effect(Keys.gold_on_crit_kill_hash, player_index)
			for effect in gold_on_crit_kill_effects:
				if !Utils.get_chance_success(effect[1] / 100.0): continue

				RunData.add_gold(1, player_index)
				RunData.add_tracked_value(player_index, Keys.item_hunting_trophy_hash, 1)

		var damage_taken: Array = enemy.take_damage(int(final_damage), dmg_args)
		true_damage += damage_taken[1]

		var effects: Array = []
		var item_effects: Array = RunData.get_player_effect(Keys.enemy_percent_damage_taken_hash, player_index)
		effects.append_array(item_effects)
		
		for effect in parent_effects:
			if effect.custom_key_hash == Keys.enemy_percent_damage_taken_hash:
				effects.push_back(effect.to_array())

		for effect_behavior in enemy.effect_behaviors.get_children():
			if !(effect_behavior is PercentDamageTakenEnemyEffectBehavior): continue

			effect_behavior.try_add_effects(effects, damage_scaling_stats)

	_fantasy_update_chain_arc(enemies)
	duration_timer.wait_time = duration
	duration_timer.start()
	show()
	set_process(true)

	return true_damage

func _process(_delta: float) -> void:
	var time_left = duration_timer.time_left
	if time_left > 0: modulate.a = time_left / duration
	else: modulate.a = 0.0

# =========================== Custom =========================== #
func _fantasy_update_chain_arc(enemies: Array) -> void:
	var points = PoolVector2Array()

	var seg_points = _fantasy_generate_lightning_segment(
		enemies[0].global_position,
		enemies[1].global_position,
		3,
		jaggedness
	)
	points.append_array(seg_points)

	for i in range(1, enemies.size() - 1):
		var from = enemies[i].global_position
		var to = enemies[i + 1].global_position

		seg_points = _fantasy_generate_lightning_segment(from, to, 3, jaggedness)
		for j in range(1, seg_points.size()):
			points.append(seg_points[j])

	line.points = points
	line.width = width
	line.default_color = color

	glow_line.points = points
	glow_line.width = width * 2.5
	glow_line.default_color = glow_color

func _fantasy_generate_lightning_segment(
	from: Vector2,
	to: Vector2,
	depth: int,
	roughness: float
) -> PoolVector2Array:
	var points = PoolVector2Array()
	points.append(from)
	_fantasy_subdivide_lightning(points, from, to, depth, roughness)
	points.append(to)
	return points

func _fantasy_subdivide_lightning(
	points: PoolVector2Array,
	p1: Vector2,
	p2: Vector2,
	depth: int,
	roughness: float
) -> void:
	if depth <= 0:
		return

	var mid = (p1 + p2) * 0.5
	var displacement = (p2 - p1).length() * 0.2 * roughness
	mid += Vector2(rand_range(-1, 1), rand_range(-1, 1)) * displacement

	_fantasy_subdivide_lightning(points, p1, mid, depth - 1, roughness * 0.5)
	points.append(mid)
	_fantasy_subdivide_lightning(points, mid, p2, depth - 1, roughness * 0.5)

# =========================== Method =========================== #
func fa_on_DurationTimerTimeout() -> void:
	Utils.get_scene_node().add_node_to_pool(get_meta("pool_id"))
	reset()
