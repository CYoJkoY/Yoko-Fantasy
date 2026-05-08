extends Area2D

const PLAYER_LIGHT_RANGE: float = 240.0
const FOG_LIGHT_COLOR: Color = Color("FFF0A6D1")
const BREATH_SPRITE_COLOR: Color = Color("2AFFFFFF")
const DEFAULT_SPRITE_COLOR: Color = Color("5DFFFFFF")
const REWARD_SPRITE_COLOR: Color = Color("5D8F0000")

var main: Main = null
var player_index: int = -1
var pos: Vector2 = Vector2.ZERO
var base_range: int = 0
var range_rate: float = 0
var killed_need: int = 0
var stat_id: int = Keys.empty_hash
var stat_num: int = 0
var gold_num: int = 0
var consumable_id: int = Keys.empty_hash
var consumable_num: int = 0

var killed_count: int = 0
var fog_viewport: FogViewport = null
var fog_light: Sprite = null
var sprite_range: float = 0.0

onready var sprite: Sprite = $"Sprite"
onready var breath_tween: Tween = $"%BreathTween"
onready var reward_tween: Tween = $"%RewardTween"
onready var reward_audio: AudioStreamPlayer2D = $"%RewardAudio"
onready var idle_delay_timer: Timer = $"%IdleDelayTimer"
onready var pulse_sprite: Sprite = $"PulseSprite"
onready var pulse_tween: Tween = $"%PulseTween"
onready var collision: CollisionShape2D = $"Collision"

# =========================== Extension =========================== #
func init(_main: Main, _player_index: int, _pos: Vector2, sacrificial_circle: Array) -> Area2D:
	main = _main
	player_index = _player_index
	pos = _pos

	base_range = sacrificial_circle[0]
	range_rate = sacrificial_circle[1] / 100.0
	killed_need = sacrificial_circle[2]
	stat_id = sacrificial_circle[3]
	stat_num = sacrificial_circle[4]
	gold_num = sacrificial_circle[5]
	consumable_id = sacrificial_circle[6]
	consumable_num = sacrificial_circle[7]

	return self

func _ready() -> void:
	set_process(false)
	sprite.self_modulate = BREATH_SPRITE_COLOR
	pulse_sprite.texture = sprite.texture
	var total_range: float = Utils.ncl_get_range_with_detection(base_range, range_rate, player_index)
	sprite_range = sprite.texture.get_width() / 2.0
	var sprite_scale: Vector2 = Vector2.ONE * (total_range / sprite_range)
	var target_scale: Vector2 = sprite_scale * 2.35
	sprite.scale = sprite_scale
	pulse_sprite.scale = target_scale
	collision.shape.radius = total_range
	global_position = pos

	if main._is_fog_wave:
		set_process(true)
		fog_viewport = main._fog_viewport
		fog_light = fog_viewport.player_light_in_shadow_scene.instance()
		fog_viewport.add_child(fog_light)

		fog_light.scale = Vector2.ONE * (total_range / PLAYER_LIGHT_RANGE)
		fog_light.modulate = FOG_LIGHT_COLOR

	_fantasy_start_breath()

func _process(_delta: float) -> void:
	if !main._is_fog_wave: return

	var scale_factor: float = fog_viewport.fog_sprite.scale.x
	fog_light.global_position = (pos - fog_viewport.camera.global_position) / scale_factor + (fog_viewport.size / 2)

# =========================== Custom =========================== #
func _fantasy_start_breath() -> void:
	breath_tween.stop_all()

	breath_tween.interpolate_property(
		sprite, "self_modulate:a",
		BREATH_SPRITE_COLOR.a, DEFAULT_SPRITE_COLOR.a,
		1.75, Tween.TRANS_SINE, Tween.EASE_IN_OUT
	)

	breath_tween.interpolate_property(
		sprite, "self_modulate:a",
		DEFAULT_SPRITE_COLOR.a, BREATH_SPRITE_COLOR.a,
		1.75, Tween.TRANS_SINE, Tween.EASE_IN_OUT, 1.75
	)

	breath_tween.start()

func _fantasy_sacrifice() -> void:
	if killed_need <= 0: return

	var rem: int = killed_count % killed_need
	var progress: float = 1.0 if rem == 0 else float(rem) / float(killed_need)
	var target_color: Color = DEFAULT_SPRITE_COLOR.linear_interpolate(REWARD_SPRITE_COLOR, progress)
	sprite.self_modulate = Color(target_color.r, target_color.g, target_color.b, sprite.self_modulate.a)

func _fantasy_reward() -> void:
	breath_tween.stop_all()
	reward_tween.stop_all()
	pulse_tween.stop_all()
	idle_delay_timer.stop()

	var pulse_alpha: float = pulse_sprite.self_modulate.a
	var pulse_original_scale: Vector2 = pulse_sprite.scale * 0.18
	var pulse_target_scale: Vector2 = pulse_sprite.scale

	reward_audio.play()
	reward_tween.interpolate_property(
		sprite, "self_modulate",
		sprite.self_modulate, REWARD_SPRITE_COLOR,
		0.4, Tween.TRANS_LINEAR, Tween.EASE_OUT
	)

	pulse_tween.interpolate_property(
		pulse_sprite, "self_modulate:a",
		pulse_alpha, 0.0,
		0.28, Tween.TRANS_SINE, Tween.EASE_OUT
	)

	reward_tween.interpolate_property(
		sprite, "self_modulate",
		REWARD_SPRITE_COLOR, DEFAULT_SPRITE_COLOR,
		0.8, Tween.TRANS_SINE, Tween.EASE_OUT, 0.4
	)

	pulse_tween.interpolate_property(
		pulse_sprite, "scale",
		pulse_original_scale, pulse_target_scale,
		0.28, Tween.TRANS_SINE, Tween.EASE_OUT
	)

	reward_tween.start()

	pulse_tween.start()
	pulse_sprite.show()

	if pulse_tween.is_connected("tween_all_completed", self , "fa_on_PulseTween_tween_all_completed"): return

	pulse_tween.connect("tween_all_completed", self , "fa_on_PulseTween_tween_all_completed", [pulse_alpha, pulse_target_scale])

# =========================== Method =========================== #
func fa_on_SacrificialCircle_body_entered(body: Node) -> void:
	if !is_instance_valid(body) or body.dead: return

	body.connect("died", self , "fa_on_enemy_died_on_sacrificial_circle")

func fa_on_SacrificialCircle_body_exited(body: Node) -> void:
	if !is_instance_valid(body) or body.dead: return

	body.disconnect("died", self , "fa_on_enemy_died_on_sacrificial_circle")

func fa_on_enemy_died_on_sacrificial_circle(enemy: Enemy, die_args: Entity.DieArgs) -> void:
	if die_args.cleaning_up or !die_args.enemy_killed_by_player \
	or die_args.killed_by_player_index != player_index: return

	if enemy.is_connected("died", self , "fa_on_enemy_died_on_sacrificial_circle"):
		enemy.disconnect("died", self , "fa_on_enemy_died_on_sacrificial_circle")
	
	killed_count += 1
	_fantasy_sacrifice()

	if killed_count % killed_need != 0: return

	RunData.add_stat(stat_id, stat_num, player_index)
	main.spawn_gold(gold_num, global_position, 0)
	match consumable_id:
		Utils.consumable_fantasy_soul_hash: Utils.fa_spawn_soul(consumable_num, global_position, 0)
		_: Utils.ncl_spawn_consumable(consumable_id, consumable_num, global_position, 0)

	_fantasy_reward()

func fa_on_RewardTween_tween_all_completed() -> void:
	idle_delay_timer.start()

func fa_on_IdleDelayTimer_timeout() -> void:
	_fantasy_start_breath()

func fa_on_PulseTween_tween_all_completed(pulse_alpha: float, pulse_target_scale: Vector2) -> void:
	pulse_sprite.hide()
	pulse_sprite.self_modulate.a = pulse_alpha
	pulse_sprite.scale = pulse_target_scale
