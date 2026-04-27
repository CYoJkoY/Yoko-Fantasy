extends UnitEffectBehavior

const SPRITE_RANGE: float = 150.0

var _player_index: int = -1
var _base_range: int = 0
var _range_rate: float = 0.0
var _scaling_stats: Array = []
var _base_cooldown: int = 0
var _base_damage: int = 0
var _tracked_key: int = 0
var _damage_color: Color = Color.white
var _hit_visual_scene: PackedScene = null
var enemies_in_aura: Array = []

onready var animation_player: AnimationPlayer = $"AnimationPlayer"
onready var collision: CollisionShape2D = $"%Collision"
onready var audio: AudioStreamPlayer2D = $"Audio"
onready var sprite_scale: Node2D = $"SpriteScale"
onready var timer: Timer = $"Timer"

# =========================== Extension =========================== #
func init(parent: Player, base_range: int, range_rate: float, scaling_stats: Array, base_cooldown: int, base_damage: int, tracked_key: int, damage_color: Color, hit_visual_scene: PackedScene) -> UnitEffectBehavior:
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
    return self

func _ready() -> void:
    _fantasy_wait_time_ready()

func on_moved(_delta_position: Vector2) -> void:
    pass

# =========================== Custom =========================== #
func _fantasy_wait_time_ready() -> void:
    var attack_speed_mod: float = Utils.get_stat(Keys.stat_attack_speed_hash, _player_index) / 100.0

    var total_range: float = Utils.ncl_get_range_with_detection(_base_range, _range_rate, _player_index)
    collision.shape.radius = total_range
    sprite_scale.scale = Vector2.ONE * (total_range / SPRITE_RANGE)
    var damage_args: TakeDamageArgs = Utils.ncl_create_custom_damage_args(_player_index, _damage_color)
    
    timer.wait_time = float(WeaponService.apply_attack_speed_mod_to_cooldown(_base_cooldown, attack_speed_mod)) / 60.0
    timer.connect("timeout", self , "fa_on_PeriodicRadiusTimer_timeout", [damage_args])

# =========================== Method =========================== #
func fa_on_PeriodicRadiusTimer_timeout(damage_args: TakeDamageArgs) -> void:
    var total_damage: int = Utils.ncl_get_dmg_with_scaling_stats(_base_damage, _scaling_stats, _player_index) as int

    for enemy in enemies_in_aura:
        if !is_instance_valid(enemy) or enemy.dead: continue

        var take_damage_array: Array = enemy.take_damage(total_damage, damage_args)
        RunData.add_tracked_value(_player_index, _tracked_key, take_damage_array[1])
        if take_damage_array[1] > 0 and _hit_visual_scene != null: fa_spawn_hit_visual(enemy.global_position)

    animation_player.play("pulse")
    audio.play()

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
