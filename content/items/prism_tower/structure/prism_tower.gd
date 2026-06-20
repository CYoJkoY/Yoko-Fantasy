extends "res://entities/structures/turret/turret.gd"

const BEAM_SCENE_PATH = "res://mods-unpacked/Yoko-Fantasy/content/items/prism_tower/effects/prism_beam.tscn"
const HOLY_COLUMN_SCENE_PATH = "res://mods-unpacked/Yoko-Fantasy/content/items/prism_tower/effects/prism_holy_column.tscn"
const RESONANCE_FOCUS_SCENE_PATH = "res://mods-unpacked/Yoko-Fantasy/content/items/prism_tower/effects/prism_resonance_focus.tscn"
const RESONANCE_BURST_SCENE_PATH = "res://mods-unpacked/Yoko-Fantasy/content/items/prism_tower/effects/prism_resonance_burst.tscn"
const ChainTargetService = preload("res://mods-unpacked/Yoko-Fantasy/extensions/services/chain_target_service.gd")
var MAIN_BEAM_COLOR: Color = Color("#fff0a6")
var MAIN_GLOW_COLOR: Color = Color(0.65, 0.35, 1.0, 0.32)
var SCATTER_COLORS: Array = [
	Color("#ff4949"),
	Color("#42f06e"),
	Color("#52a9ff"),
	Color("#ffd85a"),
	Color("#42f0c6"),
	Color("#b66cff"),
	Color("#ff5ad8")
]
const SCATTER_DAMAGE_MULTS = [0.55, 0.45, 0.35, 0.30, 0.25, 0.22, 0.20]
const SCATTER_BASE_TARGETS = 3
const SCATTER_MAX_TARGETS = 7
const SCATTER_RANGE_RATE = 0.5
const SCATTER_RANGE_FLAT_BONUS = 100.0
const RESONANCE_REFRACTION_RANGE_BONUS = 120.0
const MAIN_DAMAGE_EFFECT_SCALE = 0.40
const SCATTER_DAMAGE_EFFECT_SCALE = 0.24
const RESONANCE_REFRACTION_EFFECT_SCALE = 0.30
const RESONANCE_MIN_TOWERS = 3
const RESONANCE_CHARGE_REQUIRED = 6
const RESONANCE_REFRACTION_TARGETS = 2
const RESONANCE_BASE_MULT = 1.50
const RESONANCE_EXTRA_MULT = 0.35
const RESONANCE_EXTRA_RADIUS_MULT = 0.20
const RESONANCE_RADIUS = 70.0
const RESONANCE_CHARGE_META = "fantasy_prism_tower_resonance_charge"
const RESONANCE_FOCUS_DURATION = 0.30
const RESONANCE_JUDGEMENT_DELAY = 0.34
const AURA_WAVE_PERIOD = 2.15
const VISUAL_FLOAT_PERIOD = 3.30
const VISUAL_FLOAT_AMPLITUDE = 15.0
const ATTACK_WAVE_BOOST_DURATION = 0.18

var AURA_WAVE_COLORS: Array = [
	Color(1.0, 0.28, 0.32, 1.0),
	Color(1.0, 0.86, 0.30, 1.0),
	Color(0.28, 1.0, 0.76, 1.0),
	Color(0.34, 0.70, 1.0, 1.0),
	Color(0.78, 0.38, 1.0, 1.0)
]

var RESONANCE_REFRACTION_DAMAGE_MULTS: Array = [0.70, 0.55]
var RESONANCE_REFRACTION_COLORS: Array = [
	Color("#ffd85a"),
	Color("#58e6ff"),
	Color("#b66cff")
]

var _beam_pool_id: int = Keys.empty_hash
var _holy_column_pool_id: int = Keys.empty_hash
var _resonance_focus_pool_id: int = Keys.empty_hash
var _resonance_burst_pool_id: int = Keys.empty_hash
onready var _prism_aura: Node2D = $Animation/PrismAura
onready var _aura_wave_a: Sprite = $Animation/PrismAura/WaveA
onready var _aura_wave_b: Sprite = $Animation/PrismAura/WaveB
onready var _aura_wave_c: Sprite = $Animation/PrismAura/WaveC

var _aura_time: float = 0.0
var _attack_wave_boost_left: float = 0.0
var _aura_waves: Array = []
var _base_sprite_offset: Vector2 = Vector2.ZERO
var _base_aura_position: Vector2 = Vector2.ZERO
var _base_muzzle_position: Vector2 = Vector2.ZERO
var _scatter_targets_scaling_stats: Array = [["stat_fantasy_holy", 0.1]]

func _ready() -> void:
	._ready()
	_scatter_targets_scaling_stats = Utils.convert_to_hash_array(_scatter_targets_scaling_stats)
	_beam_pool_id = Keys.generate_hash(BEAM_SCENE_PATH)
	_holy_column_pool_id = Keys.generate_hash(HOLY_COLUMN_SCENE_PATH)
	_resonance_focus_pool_id = Keys.generate_hash(RESONANCE_FOCUS_SCENE_PATH)
	_resonance_burst_pool_id = Keys.generate_hash(RESONANCE_BURST_SCENE_PATH)
	_aura_waves = [_aura_wave_a, _aura_wave_b, _aura_wave_c]
	_setup_prism_body_visuals()
	_reset_prism_body_visuals()

func _physics_process(delta: float) -> void:
	._physics_process(delta)
	_update_prism_body_visuals(delta)

func shoot() -> void:
	_nb_shots_taken += 1
	if _current_target.size() == 0 or !is_instance_valid(_current_target[0]):
		_is_shooting = false
		_cooldown = _get_next_cooldown()
		return

	var target: Unit = _current_target[0]
	if target.dead:
		_is_shooting = false
		_cooldown = _get_next_cooldown()
		return

	SoundManager2D.play(Utils.get_rand_element(stats.shooting_sounds), global_position, stats.sound_db_mod, 0.2)
	_start_attack_wave_boost()
	var damage: int = _get_prism_damage()
	_apply_prism_damage(target, damage, MAIN_BEAM_COLOR, MAIN_DAMAGE_EFFECT_SCALE)
	_spawn_beam(_muzzle.global_position, target.global_position, 8.0, MAIN_BEAM_COLOR, MAIN_GLOW_COLOR, 0.18, true)
	_scatter_from(target, damage)
	_try_charge_resonance(target, damage)

	if reset_shooting_speed_on_shoot:
		set_shooting_speed()
		reset_shooting_speed_on_shoot = false

func _get_prism_damage() -> int:
	return int(max(1, stats.damage))

func _apply_prism_damage(target: Unit, damage: int, color: Color, effect_scale: float) -> int:
	if target.dead:
		return 0

	var args: TakeDamageArgs = Utils.ncl_create_custom_damage_args(player_index, color)
	args.from = self
	args.base_effect_scale = effect_scale
	var damage_taken: Array = target.take_damage(int(max(1, damage)), args)
	if player_index >= 0 and _damage_tracking_key_hash != Keys.empty_hash:
		RunData.add_tracked_value(player_index, _damage_tracking_key_hash, damage_taken[1])
	return int(damage_taken[1])

func _scatter_from(primary_target: Node, base_damage: int) -> void:
	var target_count: int = ChainTargetService.get_scaled_target_count(
		SCATTER_BASE_TARGETS,
		_scatter_targets_scaling_stats,
		player_index,
		SCATTER_MAX_TARGETS
	)
	target_count = min(target_count, SCATTER_DAMAGE_MULTS.size())
	var targets: Array = _get_nearby_targets(primary_target.global_position, [primary_target], _get_scatter_radius(), target_count)
	for i in range(targets.size()):
		var enemy: Node = targets[i]
		var color: Color = SCATTER_COLORS[i % SCATTER_COLORS.size()]
		var damage: int = int(max(1, int(round(base_damage * SCATTER_DAMAGE_MULTS[i]))))
		_apply_prism_damage(enemy, damage, color, SCATTER_DAMAGE_EFFECT_SCALE)
		_spawn_beam(primary_target.global_position, enemy.global_position, 3.6, color, Color(color.r, color.g, color.b, 0.22), 0.16, false)

func _try_charge_resonance(primary_target: Node, base_damage: int) -> void:
	var tower_count: int = _get_prism_tower_count()
	if tower_count < RESONANCE_MIN_TOWERS:
		return

	var charge: int = _get_resonance_charge() + 1
	if charge < RESONANCE_CHARGE_REQUIRED:
		_set_resonance_charge(charge)
		return

	_set_resonance_charge(0)
	_spawn_resonance(primary_target, base_damage, tower_count)

func _spawn_resonance(primary_target: Node, base_damage: int, tower_count: int) -> void:
	var judgement_target: Node = _get_resonance_primary_target(primary_target)
	if judgement_target == null:
		return

	var extra_count: int = int(max(0, tower_count - RESONANCE_MIN_TOWERS))
	var damage_mult: float = RESONANCE_BASE_MULT + float(extra_count) * RESONANCE_EXTRA_MULT
	var radius: float = RESONANCE_RADIUS * (1.0 + float(extra_count) * RESONANCE_EXTRA_RADIUS_MULT)
	var damage: int = int(max(1, int(round(base_damage * damage_mult))))
	var focus_pos: Vector2 = judgement_target.global_position + Vector2(0, -260)

	_spawn_resonance_focus(_get_prism_tower_positions(), focus_pos)
	_spawn_holy_column(judgement_target.global_position, damage, radius, judgement_target)
	call_deferred("_spawn_resonance_refractions", judgement_target, damage, judgement_target.global_position)

func _spawn_resonance_refractions(primary_target: Node, base_damage: int, origin_pos: Vector2) -> void:
	yield(get_tree().create_timer(RESONANCE_JUDGEMENT_DELAY), "timeout")
	if is_instance_valid(primary_target):
		origin_pos = primary_target.global_position

	_spawn_resonance_burst(origin_pos)
	var targets: Array = _get_nearby_targets(origin_pos, [primary_target], _get_scatter_radius() + RESONANCE_REFRACTION_RANGE_BONUS, RESONANCE_REFRACTION_TARGETS)
	for i in range(targets.size()):
		var enemy: Node = targets[i]
		if _is_valid_enemy(enemy):
			var color: Color = RESONANCE_REFRACTION_COLORS[i % RESONANCE_REFRACTION_COLORS.size()]
			var damage: int = int(max(1, int(round(base_damage * RESONANCE_REFRACTION_DAMAGE_MULTS[i]))))
			_apply_prism_damage(enemy, damage, color, RESONANCE_REFRACTION_EFFECT_SCALE)
			_spawn_beam(origin_pos, enemy.global_position, 4.8, color, Color(color.r, color.g, color.b, 0.24), 0.18, true)

func _get_resonance_primary_target(primary_target: Node) -> Node:
	if _is_valid_enemy(primary_target):
		return primary_target

	var targets: Array = _get_nearby_targets(primary_target.global_position, [], _get_scatter_radius() + RESONANCE_REFRACTION_RANGE_BONUS, 1)
	if targets.empty():
		return null
	return targets[0]

func _get_scatter_radius() -> float:
	return max(1.0, stats.max_range * SCATTER_RANGE_RATE + SCATTER_RANGE_FLAT_BONUS)

func _get_nearby_targets(center: Vector2, excluded: Array, radius: float, max_count: int) -> Array:
	var main: Main = Utils.get_scene_node()
	return ChainTargetService.collect_nearby_enemies(main, center, excluded, radius, max_count)

func _is_valid_enemy(node: Node) -> bool:
	return is_instance_valid(node) and node is Enemy and !node.dead

func _get_prism_tower_count() -> int:
	var main: Main = Utils.get_scene_node()
	if main == null or main._entity_spawner == null:
		return 0

	var count: int = 0
	for structure in main._entity_spawner.structures:
		if _is_player_prism_tower(structure):
			count += 1
	return count

func _get_prism_tower_positions() -> Array:
	var result: Array = []
	var main: Main = Utils.get_scene_node()
	if main == null or main._entity_spawner == null:
		return result

	for structure in main._entity_spawner.structures:
		if _is_player_prism_tower(structure):
			result.push_back(structure._muzzle.global_position)
			if result.size() >= 6:
				break

	return result

func _is_player_prism_tower(structure) -> bool:
	return is_instance_valid(structure) and !structure.dead and structure.player_index == player_index and structure.has_method("_is_prism_tower")

func _spawn_beam(
	from_pos: Vector2,
	to_pos: Vector2,
	width: float,
	line_color: Color,
	glow_color: Color,
	duration: float,
	with_flash: bool
) -> void:
	var beam: Node = _get_or_create_effect(_beam_pool_id, BEAM_SCENE_PATH)
	if beam == null:
		return

	beam.show_beam(from_pos, to_pos, width, line_color, glow_color, duration, with_flash)

func _spawn_holy_column(pos: Vector2, damage: int, radius: float, primary_target: Node) -> void:
	var column: Node = _get_or_create_effect(_holy_column_pool_id, HOLY_COLUMN_SCENE_PATH)
	if column == null:
		return

	column.start_column(pos, damage, radius, player_index, _damage_tracking_key_hash, primary_target, true)

func _spawn_resonance_focus(tower_positions: Array, focus_pos: Vector2) -> void:
	var focus: Node = _get_or_create_effect(_resonance_focus_pool_id, RESONANCE_FOCUS_SCENE_PATH)
	if focus == null:
		return

	focus.start_focus(tower_positions, focus_pos, RESONANCE_FOCUS_DURATION)

func _spawn_resonance_burst(pos: Vector2) -> void:
	var burst: Node = _get_or_create_effect(_resonance_burst_pool_id, RESONANCE_BURST_SCENE_PATH)
	if burst == null:
		return

	burst.start_burst(pos, 34.0)

func _get_or_create_effect(pool_id: int, scene_path: String) -> Node:
	var main: Main = Utils.get_scene_node()
	if main == null:
		return null

	var effect: Node = main.get_node_from_pool(pool_id, main._effects)
	if !is_instance_valid(effect):
		effect = load(scene_path).instance()
		main.add_effect(effect)
		effect.set_meta("pool_id", pool_id)
	return effect

func _is_prism_tower() -> bool:
	return true

func _get_resonance_charge() -> int:
	var main: Main = Utils.get_scene_node()
	if main == null:
		return 0

	var charges: Dictionary = {}
	if main.has_meta(RESONANCE_CHARGE_META):
		charges = main.get_meta(RESONANCE_CHARGE_META)
	return int(charges.get(player_index, 0))

func _set_resonance_charge(charge: int) -> void:
	var main: Main = Utils.get_scene_node()
	if main == null:
		return

	var charges: Dictionary = {}
	if main.has_meta(RESONANCE_CHARGE_META):
		charges = main.get_meta(RESONANCE_CHARGE_META)
	charges[player_index] = charge
	main.set_meta(RESONANCE_CHARGE_META, charges)

func _reset_prism_body_visuals() -> void:
	for wave in _aura_waves:
		wave.modulate.a = 0.0
		wave.scale = Vector2.ONE * 0.35
	sprite.offset = _base_sprite_offset
	_prism_aura.position = _base_aura_position
	_muzzle.position = _base_muzzle_position

func _setup_prism_body_visuals() -> void:
	_base_sprite_offset = sprite.offset
	_base_aura_position = _prism_aura.position
	_base_muzzle_position = _muzzle.position

func _start_attack_wave_boost() -> void:
	_attack_wave_boost_left = ATTACK_WAVE_BOOST_DURATION

func _update_prism_body_visuals(delta: float) -> void:
	_aura_time += delta
	_attack_wave_boost_left = max(0.0, _attack_wave_boost_left - delta)
	_update_visual_float()
	_update_aura_waves()

func _update_visual_float() -> void:
	var wave: float = sin(_aura_time * TAU / VISUAL_FLOAT_PERIOD)
	var visual_offset: Vector2 = Vector2(0, wave * VISUAL_FLOAT_AMPLITUDE)
	sprite.offset = _base_sprite_offset + visual_offset
	_prism_aura.position = _base_aura_position + visual_offset
	_muzzle.position = _base_muzzle_position + visual_offset

func _update_aura_waves() -> void:
	var offsets: Array = [0.0, 0.33, 0.66]
	var boost: float = 0.0
	if _attack_wave_boost_left > 0.0:
		boost = _attack_wave_boost_left / ATTACK_WAVE_BOOST_DURATION
	for i in range(_aura_waves.size()):
		var wave: Sprite = _aura_waves[i]
		var progress: float = fmod((_aura_time / AURA_WAVE_PERIOD) + offsets[i], 1.0)
		var alpha_curve: float = sin(progress * PI)
		var color_index: int = int(floor(fmod(_aura_time * 1.8 + float(i) * 1.6, float(AURA_WAVE_COLORS.size()))))
		var color: Color = AURA_WAVE_COLORS[color_index]
		color.a = min(0.42, alpha_curve * (0.12 + boost * 0.12))
		wave.modulate = color
		wave.scale = Vector2.ONE * (0.34 + boost * 0.08 + progress * (1.14 + boost * 0.18))
		wave.rotation = progress * 0.12 + float(i) * 0.27
