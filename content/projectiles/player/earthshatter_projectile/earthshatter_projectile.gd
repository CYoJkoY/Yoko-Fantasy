extends PlayerProjectile

const FISSURE_SCENE = preload("res://mods-unpacked/Yoko-Fantasy/content/projectiles/player/earthshatter_projectile/earthshatter_fissure.tscn")
const SHARD_SCENE = preload("res://mods-unpacked/Yoko-Fantasy/content/projectiles/player/earthshatter_projectile/earthshatter_shard.tscn")
const IMPACT_VFX_SCENE = preload("res://mods-unpacked/Yoko-Fantasy/content/projectiles/player/earthshatter_projectile/earthshatter_impact_vfx.tscn")
const EARTHSHATTER_EFFECT = preload("res://mods-unpacked/Yoko-Fantasy/content/weapons/ranged/earthshatter/earthshatter_effect.gd")

var _earthshatter_effect: Resource

var _detonated: bool = false
var _boulder_spin_speed: float = 8.0

onready var _trail_particles: CPUParticles2D = $"%TrailParticles"


func _ready() -> void:
	_boulder_spin_speed = rand_range(6.0, 10.0) * (1.0 if randf() > 0.5 else -1.0)


func set_effects(effects: Array) -> void:
	.set_effects(effects)
	_earthshatter_effect = null
	for effect in effects:
		if effect is EARTHSHATTER_EFFECT:
			_earthshatter_effect = effect
			return


func shoot() -> void:
	_detonated = false
	.shoot()
	_trail_particles.modulate.a = _sprite.modulate.a
	_trail_particles.emitting = true
	_trail_particles.restart()


func _physics_process(delta: float) -> void:
	if _enable_stop_delay:
		return

	_sprite.rotation += _boulder_spin_speed * delta


func _on_Hitbox_hit_something(thing_hit: Node, damage_dealt: int) -> void:
	_detonate(velocity)
	._on_Hitbox_hit_something(thing_hit, damage_dealt)


func stop() -> void:
	_detonate(velocity)
	.stop()


func _detonate(impact_dir: Vector2) -> void:
	if _detonated:
		return
	_detonated = true

	var main = Utils.get_scene_node()
	var impact_pos: Vector2 = global_position
	var weapon_pos: int = _hitbox.from.weapon_pos
	var crit_ch: float = _weapon_stats.crit_chance
	var crit_dmg: float = _weapon_stats.crit_damage
	var base_dmg: int = _hitbox.damage

	var vfx_pool_id: int = IMPACT_VFX_SCENE.get_instance_id()
	var vfx = main.get_node_from_pool(vfx_pool_id, main._effects)
	if vfx == null:
		vfx = IMPACT_VFX_SCENE.instance()
		main.add_effect(vfx)
	vfx.play(impact_pos, main, vfx_pool_id, int(_earthshatter_effect.value) - 1)

	var fissure_pool_id: int = FISSURE_SCENE.get_instance_id()
	var fissure = main.get_node_from_pool(fissure_pool_id, main._tile_map)
	if fissure == null:
		fissure = FISSURE_SCENE.instance()
		main._tile_map.add_child(fissure)
	var fissure_dmg: int = int(max(1, base_dmg * _earthshatter_effect.fissure_damage_percent / 100.0))
	fissure.activate(
		impact_pos,
		fissure_dmg,
		_get_player_index(),
		weapon_pos,
		crit_ch,
		crit_dmg,
		main,
		fissure_pool_id,
		_earthshatter_effect.slow_percent
	)

	var shard_pool_id: int = SHARD_SCENE.get_instance_id()
	var shard_dmg: int = int(max(1, base_dmg * _earthshatter_effect.shard_damage_percent / 100.0))
	var count: int = _earthshatter_effect.shard_count

	var base_angle: float = impact_dir.angle()
	var step_angle: float = TAU / float(count)

	for i in range(count):
		var shard = main.get_node_from_pool(shard_pool_id, main._effects)
		if shard == null:
			shard = SHARD_SCENE.instance()
			main.add_effect(shard)

		var shard_angle: float = base_angle + i * step_angle + rand_range(-step_angle * 0.35, step_angle * 0.35)
		var shard_dir: Vector2 = Vector2.RIGHT.rotated(shard_angle)

		shard.launch_shard(
			impact_pos,
			shard_dir,
			shard_dmg,
			_get_player_index(),
			weapon_pos,
			crit_ch,
			crit_dmg,
			main,
			shard_pool_id
		)


func _return_to_pool() -> void:
	._return_to_pool()
	_trail_particles.emitting = false
