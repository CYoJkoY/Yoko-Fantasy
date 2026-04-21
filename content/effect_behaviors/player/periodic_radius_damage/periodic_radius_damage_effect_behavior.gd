extends PlayerEffectBehavior

const SPRITE_RANGE: float = 150.0
const DETECTION_RANGE: int = 200

var FaTimers: Array = []
var enemies_in_aura: Array = []

onready var animation_player: AnimationPlayer = $"%AnimationPlayer"
onready var collision: CollisionShape2D = $"%Hitbox/Collision"
onready var audio: AudioStreamPlayer2D = $"Audio"
onready var sprite_scale: Node2D = $"SpriteScale"

# =========================== Extension =========================== #
func _ready() -> void:
    _fantasy_wait_time_ready()

func should_add_on_spawn() -> bool:
    return !RunData.get_player_effect(Utils.fantasy_periodic_radius_damage_hash, _player_index).empty()

func on_death(_die_args: Entity.DieArgs) -> void:
    for timer in FaTimers: timer.stop()

# =========================== Custom =========================== #
func _fantasy_wait_time_ready() -> void:
    var item_effects: Array = RunData.get_player_effect(Utils.fantasy_periodic_radius_damage_hash, _player_index)
    if item_effects.empty(): return

    for item_effect in item_effects:
        var base_cooldown: int = item_effect[3]
        var attack_speed_mod: float = Utils.get_stat(Keys.stat_attack_speed_hash, _player_index) / 100.0
        var timer: Timer = Timer.new()
        timer.wait_time = float(WeaponService.apply_attack_speed_mod_to_cooldown(base_cooldown, attack_speed_mod)) / 60.0
        timer.autostart = true
        timer.connect("timeout", self , "fa_on_PeriodicRadiusTimer_timeout", [item_effect[0], item_effect[1] / 100.0, item_effect[2], item_effect[4], item_effect[5]])
        add_child(timer)
        FaTimers.append(timer)

# =========================== Method =========================== #
func fa_on_PeriodicRadiusTimer_timeout(base_range: int, range_rate: float, scaling_stats: Array, base_damage: int, tracked_key_hash: int) -> void:
    var total_range: float = Utils.get_stat(Keys.stat_range_hash, _player_index) * range_rate + base_range + DETECTION_RANGE
    var total_damage: int = base_damage + Utils.ncl_get_scaling_stats_dmg(scaling_stats, _player_index)

    collision.shape.radius = total_range
    sprite_scale.scale = Vector2.ONE * (total_range / SPRITE_RANGE)

    var damage_args: TakeDamageArgs = Utils.ncl_create_custom_damage_args(_player_index, Color("#F5D35E"))
    for enemy in enemies_in_aura:
        if !is_instance_valid(enemy) or enemy.dead: continue

        var take_damage_array: Array = enemy.take_damage(total_damage, damage_args)
        RunData.add_tracked_value(_player_index, tracked_key_hash, take_damage_array[1])

    animation_player.play("pulse")
    audio.play()

func fa_on_Hitbox_body_entered(body: Node) -> void:
    if !enemies_in_aura.has(body):
        enemies_in_aura.push_back(body)

func fa_on_Hitbox_body_exited(body: Node) -> void:
    enemies_in_aura.erase(body)
