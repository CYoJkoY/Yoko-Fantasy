extends Area2D

const SPRITE_RANGE: float = 256.0
const BREATH_SPRITE_COLOR: Color = Color("2CFFFFFF")
const DEFAULT_SPRITE_COLOR: Color = Color("55FFFFFF")
const MAX_SPRITE_COLOR: Color = Color("ADFFFFFF")
const REWARD_SPRITE_COLOR: Color = Color("AD8F0000")

var main: Main = null
var player_index: int = -1
var pos: Vector2 = Vector2.ZERO
var base_range: int = 0
var range_rate: float = 0
var killed_nedd: int = 0
var stat_id: int = Keys.empty_hash
var stat_num: int = 0
var gold_num: int = 0
var consumable_id: int = Keys.empty_hash
var consumable_num: int = 0

var killed_count: int = 0
var is_rewarding: bool = false

onready var sprite: Sprite = $"Sprite"
onready var breath_tween: Tween = $"BreathTween"
onready var sacrificial_tween: Tween = $"SacrificialTween"
onready var reward_tween: Tween = $"RewardTween"
onready var reward_audio: AudioStreamPlayer2D = $"RewardAudio"
onready var idle_delay_timer: Timer = $"IdleDelayTimer"

# =========================== Extension =========================== #
func init(_main: Main, _player_index: int, _pos: Vector2, sacrificial_circle: Array) -> Area2D:
    main = _main
    player_index = _player_index
    pos = _pos

    base_range = sacrificial_circle[0]
    range_rate = sacrificial_circle[1] / 100.0
    killed_nedd = sacrificial_circle[2]
    stat_id = sacrificial_circle[3]
    stat_num = sacrificial_circle[4]
    gold_num = sacrificial_circle[5]
    consumable_id = sacrificial_circle[6]
    consumable_num = sacrificial_circle[7]

    return self

func _ready() -> void:
    sprite.self_modulate = BREATH_SPRITE_COLOR
    var total_range: float = Utils.ncl_get_range_with_detection(base_range, range_rate, player_index)
    scale = Vector2.ONE * (total_range / SPRITE_RANGE)
    global_position = pos

    _fantasy_start_breath()

# =========================== Custom =========================== #
func _fantasy_start_breath() -> void:
    breath_tween.stop_all()

    breath_tween.interpolate_property(
        sprite, "self_modulate:a",
        BREATH_SPRITE_COLOR.a, DEFAULT_SPRITE_COLOR.a,
        0.35, Tween.TRANS_SINE, Tween.EASE_IN_OUT
    )

    breath_tween.interpolate_property(
        sprite, "self_modulate:a",
        DEFAULT_SPRITE_COLOR.a, BREATH_SPRITE_COLOR.a,
        0.35, Tween.TRANS_SINE, Tween.EASE_IN_OUT, 0.35
    )

    breath_tween.start()

func _fantasy_sacrifice() -> void:
    breath_tween.stop_all()
    idle_delay_timer.stop()
    sacrificial_tween.stop_all()

    sacrificial_tween.interpolate_property(
        sprite, "self_modulate:a",
        sprite.self_modulate.a, MAX_SPRITE_COLOR.a,
        0.2, Tween.TRANS_LINEAR, Tween.EASE_OUT
    )

    sacrificial_tween.interpolate_property(
        sprite, "self_modulate:a",
        MAX_SPRITE_COLOR.a, DEFAULT_SPRITE_COLOR.a,
        1.0, Tween.TRANS_SINE, Tween.EASE_OUT, 0.2
    )

    sacrificial_tween.start()

func _fantasy_reward() -> void:
    breath_tween.stop_all()
    sacrificial_tween.stop_all()
    reward_tween.stop_all()
    idle_delay_timer.stop()

    reward_audio.play()
    reward_tween.interpolate_property(
        sprite, "self_modulate",
        sprite.self_modulate, REWARD_SPRITE_COLOR,
        0.4, Tween.TRANS_LINEAR, Tween.EASE_OUT
    )

    reward_tween.interpolate_property(
        sprite, "self_modulate",
        REWARD_SPRITE_COLOR, DEFAULT_SPRITE_COLOR,
        0.8, Tween.TRANS_SINE, Tween.EASE_OUT, 0.4
    )

    reward_tween.start()

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

    if killed_count % killed_nedd != 0: return

    is_rewarding = true
    RunData.add_stat(stat_id, stat_num, player_index)
    main.spawn_gold(gold_num, global_position, 0)
    match consumable_id:
        Utils.consumable_fantasy_soul_hash: Utils.fa_spawn_soul(consumable_num, global_position, 0)
        _: Utils.ncl_spawn_consumable(consumable_id, consumable_num, global_position, 0)

    _fantasy_reward()

func fa_on_SacrificialTween_tween_all_completed() -> void:
    if !is_rewarding: idle_delay_timer.start()

func fa_on_RewardTween_tween_all_completed() -> void:
    is_rewarding = false
    idle_delay_timer.start()

func fa_on_IdleDelayTimer_timeout() -> void:
    _fantasy_start_breath()
