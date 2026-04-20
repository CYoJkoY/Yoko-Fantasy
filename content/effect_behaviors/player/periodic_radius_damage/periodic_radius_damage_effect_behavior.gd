extends PlayerEffectBehavior

const BASE_HOLY_SCALING: float = 1.0

var enemies_in_aura: Array = []

onready var periodic_radius_timer: Timer = $"%PeriodicRadiusTimer"
onready var hitbox: Hitbox = $"%Hitbox"
onready var animation_player: AnimationPlayer = $"%AnimationPlayer"
onready var sprite: Sprite = $"%Sprite"
onready var collision: CollisionShape2D = $"%Hitbox/Collision"
onready var audio: AudioStreamPlayer2D = $Audio


func _ready() -> void:
	collision.shape = collision.shape.duplicate()
	_refresh_wait_time()


func should_add_on_spawn() -> bool:
	return RunData.get_player_effect(Utils.fantasy_priest_holy_pulse_hash, _player_index).size() > 0


func on_death(_die_args: Entity.DieArgs) -> void:
	periodic_radius_timer.stop()


func _on_Hitbox_body_entered(body: Node) -> void:
	if not enemies_in_aura.has(body):
		enemies_in_aura.push_back(body)


func _on_Hitbox_body_exited(body: Node) -> void:
	enemies_in_aura.erase(body)


func _on_PulseTimer_timeout() -> void:
	if _parent.dead or _parent.cleaning_up:
		return

	var pulse_effects: Array = RunData.get_player_effect(Utils.fantasy_priest_holy_pulse_hash, _player_index)
	if pulse_effects.empty():
		return

	var pulse_effect: Array = pulse_effects.back()
	var base_damage: int = int(pulse_effect[1])
	var base_radius: float = float(pulse_effect[2])
	var holy_damage: int = int(Utils.get_stat(Utils.stat_fantasy_holy_hash, _player_index) * BASE_HOLY_SCALING)
	var total_damage: int = WeaponService.apply_damage_bonus(base_damage + holy_damage, _player_index)
	var actual_radius: float = base_radius + max(0.0, Utils.get_stat(Keys.stat_range_hash, _player_index) * 0.5)

	var shape: CircleShape2D = collision.shape as CircleShape2D
	shape.radius = actual_radius
	sprite.scale = Vector2.ONE * (actual_radius / 150.0)

	var damage_args: TakeDamageArgs = Utils.fantasy_create_holy_damage_args(_player_index)
	for enemy in _get_enemies_in_pulse_radius(actual_radius):
		if not is_instance_valid(enemy) or enemy.dead:
			continue
		enemy.take_damage(total_damage, damage_args)

	animation_player.play("pulse")
	audio.play()
	_refresh_wait_time()


func _refresh_wait_time() -> void:
	var pulse_effects: Array = RunData.get_player_effect(Utils.fantasy_priest_holy_pulse_hash, _player_index)
	if pulse_effects.empty():
		return

	var pulse_effect: Array = pulse_effects.back()
	var base_cooldown_frames: int = int(pulse_effect[0]) * 60
	var attack_speed_mod: float = Utils.get_stat(Keys.stat_attack_speed_hash, _player_index) / 100.0
	periodic_radius_timer.wait_time = float(WeaponService.apply_attack_speed_mod_to_cooldown(base_cooldown_frames, attack_speed_mod)) / 60.0
	if periodic_radius_timer.is_stopped(): periodic_radius_timer.start()


func _get_enemies_in_pulse_radius(actual_radius: float) -> Array:
	var scene = Utils.get_scene_node()
	if scene == null or scene._entity_spawner == null:
		return enemies_in_aura

	var enemies_in_range: Array = []
	for enemy in scene._entity_spawner.get_all_enemies(false):
		if not is_instance_valid(enemy) or enemy.dead:
			continue
		if _parent.global_position.distance_to(enemy.global_position) > actual_radius:
			continue
		enemies_in_range.append(enemy)

	return enemies_in_range
