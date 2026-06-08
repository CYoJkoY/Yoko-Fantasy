extends UnitEffectBehavior

const PLAYER_LIGHT_RANGE: float = 240.0
const AURA_ALPHA_MIN: float = 0.04
const AURA_ALPHA_MAX: float = 0.07
const AURA_BREATH_DURATION: float = 1.4
const HOLY_PULSE_START_SCALE: float = 0.72
const HOLY_PULSE_TARGET_SCALE: float = 1.08
const HOLY_PULSE_FADE_IN_DURATION: float = 0.17
const HOLY_PULSE_FADE_OUT_DURATION: float = 0.32
const HOLY_PULSE_ALPHA: float = 0.55
const FOG_LIGHT_PULSE_START_SCALE: float = 0.9
const FOG_LIGHT_PULSE_MIN_SCALE: float = 1.65
const FOG_LIGHT_PULSE_FADE_IN_DURATION: float = 0.35
const FOG_LIGHT_PULSE_FADE_OUT_DURATION: float = 0.80
const FOG_LIGHT_PULSE_ALPHA: float = 0.80

var _player_index: int = -1
var _base_range: int = 0
var _range_rate: float = 0.0
var _scaling_stats: Array = []
var _base_cooldown: int = 0
var _base_damage: int = 0
var _tracked_key: int = 0
var _damage_color: Color = Color.white
var _hit_visual_scene: PackedScene = null
var _can_light: bool = true

var total_range: float = 0.0
var total_cooldown: float = 0.0
var enemies_in_aura: Array = []
var sprite_range: float = 0.0

onready var collision: CollisionShape2D = $"%Collision"
onready var audio: AudioStreamPlayer2D = $"Audio"
onready var sprite_scale: Node2D = $"SpriteScale"
onready var aura_sprite: Sprite = $"%AuraSprite"
onready var aura_tween: Tween = $"AuraTween"
onready var pulse_tween: Tween = $"PulseTween"
onready var sprite: Sprite = $"%Sprite"
onready var timer: Timer = $"Timer"

# =========================== Extension =========================== #
func init(parent: Player, base_range: int, range_rate: float, scaling_stats: Array, base_cooldown: int, base_damage: int, tracked_key: int, damage_color: Color, hit_visual_scene: PackedScene, can_light: bool) -> UnitEffectBehavior:
    _parent = parent
    _player_index = _parent.player_index
    _base_range = base_range
    _range_rate = range_rate
    _scaling_stats = scaling_stats
    _base_cooldown = base_cooldown
    _base_damage = base_damage
    _tracked_key = tracked_key
    _damage_color = damage_color
    _hit_visual_scene = hit_visual_scene
    _can_light = can_light
    return self

func _ready() -> void:
    var attack_speed_mod: float = Utils.get_stat(Keys.stat_attack_speed_hash, _player_index) / 100.0

    total_range = Utils.ncl_get_range_with_detection(_base_range, _range_rate, _player_index)
    collision.shape.radius = total_range
    sprite_range = sprite.texture.get_width() / 2.0
    sprite_scale.scale = Vector2.ONE * (total_range / sprite_range)
    var damage_args: TakeDamageArgs = Utils.ncl_create_custom_damage_args(_player_index, _damage_color)
    total_cooldown = float(WeaponService.apply_attack_speed_mod_to_cooldown(_base_cooldown, attack_speed_mod)) / 60.0

    timer.wait_time = total_cooldown
    timer.connect("timeout", self , "fa_on_PeriodicRadiusTimer_timeout", [damage_args])
    fa_start_aura_breath()

func on_moved(_delta_position: Vector2) -> void:
    pass

# =========================== Method =========================== #
func fa_start_aura_breath() -> void:
    aura_tween.stop_all()
    aura_tween.remove_all()
    aura_sprite.self_modulate.a = AURA_ALPHA_MIN

    aura_tween.interpolate_property(
        aura_sprite, "self_modulate:a",
        AURA_ALPHA_MIN, AURA_ALPHA_MAX,
        AURA_BREATH_DURATION, Tween.TRANS_SINE, Tween.EASE_IN_OUT
    )

    aura_tween.interpolate_property(
        aura_sprite, "self_modulate:a",
        AURA_ALPHA_MAX, AURA_ALPHA_MIN,
        AURA_BREATH_DURATION, Tween.TRANS_SINE, Tween.EASE_IN_OUT, AURA_BREATH_DURATION
    )

    aura_tween.set_repeat(true)
    aura_tween.start()

func fa_play_holy_aura_pulse() -> void:
    pulse_tween.stop_all()
    pulse_tween.remove_all()

    sprite.visible = true
    sprite.scale = Vector2.ONE * HOLY_PULSE_START_SCALE
    sprite.modulate = Color(1.0, 0.96, 0.72, 0.0)

    pulse_tween.interpolate_property(
        sprite, "scale",
        sprite.scale, Vector2.ONE * HOLY_PULSE_TARGET_SCALE,
        HOLY_PULSE_FADE_IN_DURATION, Tween.TRANS_SINE, Tween.EASE_OUT
    )

    pulse_tween.interpolate_property(
        sprite, "scale",
        Vector2.ONE * HOLY_PULSE_TARGET_SCALE, Vector2.ONE,
        HOLY_PULSE_FADE_OUT_DURATION, Tween.TRANS_SINE, Tween.EASE_IN_OUT, HOLY_PULSE_FADE_IN_DURATION
    )

    pulse_tween.interpolate_property(
        sprite, "modulate:a",
        0.0, HOLY_PULSE_ALPHA,
        HOLY_PULSE_FADE_IN_DURATION, Tween.TRANS_SINE, Tween.EASE_OUT
    )

    pulse_tween.interpolate_property(
        sprite, "modulate:a",
        HOLY_PULSE_ALPHA, 0.0,
        HOLY_PULSE_FADE_OUT_DURATION, Tween.TRANS_SINE, Tween.EASE_IN, HOLY_PULSE_FADE_IN_DURATION
    )

    pulse_tween.interpolate_callback(
        sprite,
        HOLY_PULSE_FADE_IN_DURATION + HOLY_PULSE_FADE_OUT_DURATION,
        "hide"
    )

    pulse_tween.start()

func fa_on_PeriodicRadiusTimer_timeout(damage_args: TakeDamageArgs) -> void:
    var total_damage: int = int(Utils.ncl_get_dmg_with_scaling_stats(_base_damage, _scaling_stats, _player_index))

    for enemy in enemies_in_aura:
        if !is_instance_valid(enemy) or enemy.dead: continue

        var take_damage_array: Array = enemy.take_damage(total_damage, damage_args)
        RunData.add_tracked_value(_player_index, _tracked_key, take_damage_array[1])
        if take_damage_array[1] > 0 and _hit_visual_scene != null: fa_spawn_hit_visual(enemy.global_position)

    fa_play_holy_aura_pulse()
    audio.play()
    fa_pulse_fog_player_light()

func fa_spawn_hit_visual(spawn_position: Vector2) -> void:
    var main: Node = Utils.get_scene_node()
    var pool_id: int = _hit_visual_scene.get_instance_id()
    var hit_visual: Node = main.get_node_from_pool(pool_id, main._effects)
    if hit_visual == null:
        hit_visual = _hit_visual_scene.instance()
        main.add_effect(hit_visual)
        hit_visual.set_meta("pool_id", pool_id)

    hit_visual.play(spawn_position, main, pool_id)

func fa_on_Range_body_entered(body: Node) -> void:
    if !enemies_in_aura.has(body):
        enemies_in_aura.append(body)

func fa_on_Range_body_exited(body: Node) -> void:
    enemies_in_aura.erase(body)

func fa_pulse_fog_player_light() -> void:
    if !_can_light: return

    var main: Node = Utils.get_scene_node()
    if main == null or !main._is_fog_wave: return

    var fog_viewport: FogViewport = main._fog_viewport
    if fog_viewport == null or _player_index < 0 or _player_index >= fog_viewport.player_lights.size(): return

    var player_light: Node2D = fog_viewport.player_lights[_player_index]
    if player_light == null or !is_instance_valid(player_light): return
    if fog_viewport.player_light_in_shadow_scene == null: return

    var pulse_light: Node2D = fog_viewport.player_light_in_shadow_scene.instance()
    player_light.add_child(pulse_light)

    var scale_multiplier: float = total_range / PLAYER_LIGHT_RANGE
    pulse_light.scale = Vector2.ONE * FOG_LIGHT_PULSE_START_SCALE
    pulse_light.modulate = Color(1.0, 1.0, 1.0, 0.0)

    var fog_pulse_tween: Tween = Tween.new()
    fog_pulse_tween.name = "FantasyLightPulseTween"
    pulse_light.add_child(fog_pulse_tween)

    var target_scale: Vector2 = Vector2.ONE * max(FOG_LIGHT_PULSE_MIN_SCALE, scale_multiplier)
    fog_pulse_tween.interpolate_property(
        pulse_light, "scale",
        pulse_light.scale, target_scale,
        FOG_LIGHT_PULSE_FADE_IN_DURATION, Tween.TRANS_SINE, Tween.EASE_OUT
    )

    fog_pulse_tween.interpolate_property(
        pulse_light, "scale",
        target_scale, Vector2.ONE,
        FOG_LIGHT_PULSE_FADE_OUT_DURATION, Tween.TRANS_SINE, Tween.EASE_IN_OUT, FOG_LIGHT_PULSE_FADE_IN_DURATION
    )

    fog_pulse_tween.interpolate_property(
        pulse_light, "modulate:a",
        0.0, FOG_LIGHT_PULSE_ALPHA,
        FOG_LIGHT_PULSE_FADE_IN_DURATION, Tween.TRANS_SINE, Tween.EASE_OUT
    )

    fog_pulse_tween.interpolate_property(
        pulse_light, "modulate:a",
        FOG_LIGHT_PULSE_ALPHA, 0.0,
        FOG_LIGHT_PULSE_FADE_OUT_DURATION, Tween.TRANS_SINE, Tween.EASE_IN, FOG_LIGHT_PULSE_FADE_IN_DURATION
    )

    fog_pulse_tween.interpolate_callback(
        pulse_light,
        FOG_LIGHT_PULSE_FADE_IN_DURATION + FOG_LIGHT_PULSE_FADE_OUT_DURATION,
        "queue_free"
    )
    
    fog_pulse_tween.start()
