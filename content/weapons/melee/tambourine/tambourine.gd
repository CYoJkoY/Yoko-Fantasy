extends "res://weapons/melee/melee_weapon.gd"

const SHOCKWAVE_SCENE: PackedScene = preload("res://mods-unpacked/Yoko-Fantasy/content/weapons/melee/tambourine/vfx/tambourine_shockwave.tscn")
const HIT_SOUND: AudioStream = preload("res://mods-unpacked/Yoko-Fantasy/content/weapons/melee/tambourine/audio/tambourine_hit.wav")
const HIT_SOUND_INTERVAL_MS: int = 55
const BLAST_INTERVAL: float = 0.03
const BASE_BLAST_SCALE: float = 0.4
const BLAST_SCALE_VARIATION: float = 0.2

onready var _swing_trail: Line2D = $SwingTrail

var _successful_hits: int = 0
var _next_hit_sound_time: int = 0
var _blast_effect: ExplodingEffect = ExplodingEffect.new()
var _shockwave_sequences: Array = []


func _ready() -> void:
	_blast_effect.explosion_scene = SHOCKWAVE_SCENE
	_blast_effect.base_smoke_amount = 3


func _process(delta: float) -> void:
	._process(delta)
	if _parent.dead or _parent.cleaning_up:
		_swing_trail.clear_trail()
		_shockwave_sequences.clear()
		return
	if not ProgressData.settings.visual_effects:
		_swing_trail.clear_trail()
	_advance_shockwaves(delta)


func enable_hitbox() -> void:
	.enable_hitbox()
	if ProgressData.settings.visual_effects:
		_swing_trail.begin_trail(sprite)


func disable_hitbox() -> void:
	.disable_hitbox()
	if _swing_trail != null:
		_swing_trail.end_trail()


func on_weapon_hit_something(thing_hit: Node, damage_dealt: int, hitbox: Hitbox) -> void:
	var counts_as_hit: bool = hitbox == _hitbox and damage_dealt > 0 and is_instance_valid(thing_hit) and thing_hit is Enemy
	var impact_position: Vector2 = thing_hit.global_position if counts_as_hit else Vector2.ZERO
	.on_weapon_hit_something(thing_hit, damage_dealt, hitbox)
	if not counts_as_hit:
		return

	var hit_time: int = OS.get_ticks_msec()
	if hit_time >= _next_hit_sound_time:
		_next_hit_sound_time = hit_time + HIT_SOUND_INTERVAL_MS
		SoundManager2D.play(HIT_SOUND, impact_position, current_stats.sound_db_mod, 0.06)

	for effect in effects:
		if effect == null or effect.get_id() != "fantasy_tambourine_shockwave":
			continue
		_successful_hits += 1
		var hit_threshold: int = max(1, int(effect.value))
		while _successful_hits >= hit_threshold:
			_successful_hits -= hit_threshold
			_trigger_shockwave(effect, impact_position)


func _trigger_shockwave(effect: Resource, impact_position: Vector2) -> void:
	var main: Node = Utils.get_scene_node()
	if not is_instance_valid(main) or main._cleaning_up:
		return

	var blast_offsets: Array = []
	var selection_radius_squared: float = float(effect.value2) * effect.value2
	for enemy in main._entity_spawner.get_all_enemies(false):
		if not is_instance_valid(enemy) or enemy.dead:
			continue
		var offset: Vector2 = enemy.global_position - impact_position
		if offset.length_squared() <= selection_radius_squared:
			blast_offsets.append(offset)
	if blast_offsets.empty():
		return
	blast_offsets.sort_custom(self, "_sort_blast_offsets")
	var blast_stats: MeleeWeaponStats = effect.get_explosion_stats()
	var args: WeaponServiceExplodeArgs = WeaponServiceExplodeArgs.new()
	args.pos = impact_position + blast_offsets[0]
	args.damage = WeaponService.get_explosion_damage(blast_stats, player_index)
	args.scaling_stats = blast_stats.scaling_stats
	args.accuracy = _hitbox.accuracy
	args.crit_chance = _hitbox.crit_chance
	args.crit_damage = _hitbox.crit_damage
	args.from_player_index = player_index
	_spawn_shockwave(args, effect.damage_color)
	if blast_offsets.size() > 1:
		_shockwave_sequences.append({
			"offsets": blast_offsets,
			"origin": impact_position,
			"args": args,
			"next_index": 1,
			"delay": BLAST_INTERVAL,
			"created_frame": Engine.get_idle_frames(),
			"tint": effect.damage_color
		})


func _sort_blast_offsets(a: Vector2, b: Vector2) -> bool:
	return a.length_squared() < b.length_squared()


func _advance_shockwaves(delta: float) -> void:
	if _shockwave_sequences.empty():
		return
	var main: Node = Utils.get_scene_node()
	if not is_instance_valid(main) or main._cleaning_up:
		_shockwave_sequences.clear()
		return
	var frame: int = Engine.get_idle_frames()
	for i in range(_shockwave_sequences.size() - 1, -1, -1):
		var sequence: Dictionary = _shockwave_sequences[i]
		if sequence.created_frame == frame:
			continue
		sequence.delay -= delta
		while sequence.delay <= 0.0 and sequence.next_index < sequence.offsets.size():
			sequence.args.pos = sequence.origin + sequence.offsets[sequence.next_index]
			_spawn_shockwave(sequence.args, sequence.tint)
			sequence.next_index += 1
			sequence.delay += BLAST_INTERVAL
		if sequence.next_index >= sequence.offsets.size():
			_shockwave_sequences.remove(i)


func _spawn_shockwave(args: WeaponServiceExplodeArgs, tint: Color) -> void:
	_blast_effect.scale = BASE_BLAST_SCALE * rand_range(1.0 - BLAST_SCALE_VARIATION, 1.0 + BLAST_SCALE_VARIATION)
	var explosion: Node = WeaponService.explode(_blast_effect, args)
	explosion.set_tint(tint)
	explosion.connect("hit_something", self, "on_weapon_hit_something", [explosion._hitbox])
	explosion.connect("killed_something", self, "on_killed_something", [explosion._hitbox])
