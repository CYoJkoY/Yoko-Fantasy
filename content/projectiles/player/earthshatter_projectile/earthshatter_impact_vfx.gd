extends Node2D

const FANTASY_PROJECTILE_VISUAL_UTILS = preload("res://mods-unpacked/Yoko-Fantasy/content/utils/projectile_visual_utils.gd")

const IMPACT_SOUND = preload("res://projectiles/rocket/explosion_small_no_tail_01.wav")
const DURATION: float = 0.32
const FLASH_DURATION: float = 0.10

var _elapsed: float = 0.0
var _main: Node = null
var _pool_id: int = 0
var _opacity: float = 1.0

onready var _shockwave: Sprite = $"%Shockwave"
onready var _dust_burst: CPUParticles2D = $"%DustBurst"
onready var _rock_burst: CPUParticles2D = $"%RockBurst"


func _ready() -> void:
    visible = false
    set_physics_process(false)


func play(pos: Vector2, main: Node, pool_id: int, visual_tier: int) -> void:
    _main = main
    _pool_id = pool_id
    _elapsed = 0.0
    global_position = pos

    _opacity = FANTASY_PROJECTILE_VISUAL_UTILS.get_opacity()
    modulate.a = _opacity

    _shockwave.visible = true
    _shockwave.scale = Vector2.ONE * 0.25
    _shockwave.modulate.a = 0.9
    _shockwave.material.set_shader_param("expansion_progress", 0.0)
    _shockwave.material.set_shader_param("ring_width", 0.07 + 0.02 * visual_tier)

    _dust_burst.emitting = true
    _dust_burst.restart()
    _rock_burst.emitting = true
    _rock_burst.restart()

    SoundManager2D.play(IMPACT_SOUND, global_position, -4.0, 0.15)

    _main._screenshaker.shake(3.5, 0.09)

    visible = true
    set_physics_process(true)


func _physics_process(delta: float) -> void:
    var previous_elapsed: float = _elapsed
    _elapsed += delta
    var progress = clamp(_elapsed / DURATION, 0.0, 1.0)

    modulate.a = _opacity * (1.0 - progress)
    if previous_elapsed < FLASH_DURATION:
        var flash_progress: float = min(_elapsed / FLASH_DURATION, 1.0)
        var ease_wave = 1.0 - pow(1.0 - flash_progress, 3.0)
        _shockwave.scale = Vector2.ONE * lerp(0.25, 1.35, ease_wave)
        _shockwave.material.set_shader_param("expansion_progress", flash_progress)
        if _elapsed >= FLASH_DURATION:
            _shockwave.visible = false

    if progress >= 1.0:
        _finish()


func _finish() -> void:
    set_physics_process(false)
    visible = false
    _dust_burst.emitting = false
    _rock_burst.emitting = false
    _main.add_node_to_pool(self, _pool_id)
