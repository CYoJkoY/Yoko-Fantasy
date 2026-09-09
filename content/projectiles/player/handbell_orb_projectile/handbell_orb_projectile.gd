extends "res://mods-unpacked/Yoko-Fantasy/content/projectiles/player/micro_homing_player_projectile.gd"

const HIT_RIPPLE_SCENE: PackedScene = preload("res://mods-unpacked/Yoko-Fantasy/content/projectiles/player/handbell_orb_projectile/handbell_hit_ripple.tscn")
const FLIGHT_PULSE_SCENE: PackedScene = preload("res://mods-unpacked/Yoko-Fantasy/content/projectiles/player/handbell_orb_projectile/handbell_flight_pulse.tscn")
onready var _hit_ripple_pool_id: int = HIT_RIPPLE_SCENE.get_instance_id()
onready var _flight_pulse_pool_id: int = FLIGHT_PULSE_SCENE.get_instance_id()

export (float) var homing_turn_rate: float = 4.2
export (float) var homing_max_range: float = 950.0

var _time_alive: float = 0.0
var _pulse_timer: float = 0.0
const PULSE_INTERVAL: float = 0.085

onready var _core_sprite: Sprite = $Sprite
onready var _glow_sprite: Sprite = $Glow


func _ready() -> void:
    ._ready()
    _time_alive = rand_range(0.0, PI)
    _pulse_timer = 0.0


func _physics_process(delta: float) -> void:
    _time_alive += delta
    _pulse_timer += delta

    _process_micro_homing(delta, homing_turn_rate, homing_max_range, 180.0, 180.0)
    ._physics_process(delta)

    if is_instance_valid(_core_sprite):
        var vibration = sin(_time_alive * 18.0) * 0.12
        _core_sprite.scale = Vector2(1.0 + vibration, 1.0 - vibration)

    if is_instance_valid(_glow_sprite):
        var glow_pulse: float = 1.0 + 0.22 * sin(_time_alive * 9.0)
        _glow_sprite.scale = Vector2.ONE * glow_pulse
        _glow_sprite.modulate.a = 0.75 + 0.25 * sin(_time_alive * 9.0)

    if _pulse_timer >= PULSE_INTERVAL:
        _pulse_timer = 0.0
        _spawn_flight_pulse()


func _spawn_flight_pulse() -> void:
    var main = Utils.get_scene_node()
    if main == null or not is_instance_valid(main):
        return
    var pulse = main.get_node_from_pool(_flight_pulse_pool_id, main._effects)
    if pulse == null:
        pulse = FLIGHT_PULSE_SCENE.instance()
        main.add_effect(pulse)
        pulse.set_meta("pool_id", _flight_pulse_pool_id)
    pulse.play(global_position, main, _flight_pulse_pool_id)


func _on_Hitbox_hit_something(thing_hit: Node, damage_dealt: int) -> void:
    _spawn_hit_vfx(global_position)
    ._on_Hitbox_hit_something(thing_hit, damage_dealt)


func _spawn_hit_vfx(at_pos: Vector2) -> void:
    var main = Utils.get_scene_node()
    if main == null or not is_instance_valid(main):
        return
    var ripple = main.get_node_from_pool(_hit_ripple_pool_id, main._effects)
    if ripple == null:
        ripple = HIT_RIPPLE_SCENE.instance()
        main.add_effect(ripple)
        ripple.set_meta("pool_id", _hit_ripple_pool_id)
    ripple.play(at_pos, main, _hit_ripple_pool_id)
