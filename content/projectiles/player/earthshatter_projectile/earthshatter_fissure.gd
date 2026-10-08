extends Node2D

const CRACK_EXPAND_DURATION: float = 0.18
const TREMOR_DURATION: float = 1.0
const TREMOR_DURATION_VARIATION: float = 0.5
const FADE_START_RATIO: float = 2.0 / 3.0

var _elapsed: float = 0.0
var _duration: float = TREMOR_DURATION
var _main: Node = null
var _pool_id: int = 0
var _slow_percent: int = 25
var _damage: int = 10
var _player_index: int = 0
var _weapon_pos: int = -1
var _crit_chance: float = 0.05
var _crit_damage: float = 1.5
var _has_pulsed_damage: bool = false
var _slowed_enemies: Dictionary = {}
var _enemies_in_area: Dictionary = {}

onready var _slow_source_id: String = "earthshatter_fissure_%s" % get_instance_id()

onready var _fissure_sprite: Sprite = $"%FissureSprite"
onready var _crater_sprite: Sprite = $"%CraterSprite"
onready var _dust_particles: CPUParticles2D = $"%DustParticles"
onready var _aoe_area: Area2D = $"%AoeArea"


func _ready() -> void:
    visible = false
    set_physics_process(false)


func activate(
    pos: Vector2,
    damage: int,
    player_index: int,
    weapon_pos: int,
    crit_chance: float,
    crit_damage: float,
    main: Node,
    pool_id: int,
    slow_percent: int
) -> void:
    _main = main
    _pool_id = pool_id
    _slow_percent = slow_percent
    _damage = damage
    _player_index = player_index
    _weapon_pos = weapon_pos
    _crit_chance = crit_chance
    _crit_damage = crit_damage
    _elapsed = 0.0
    _duration = rand_range(TREMOR_DURATION - TREMOR_DURATION_VARIATION, TREMOR_DURATION + TREMOR_DURATION_VARIATION)
    _has_pulsed_damage = false

    global_position = pos
    modulate.a = FantasyProjectileVisualUtils.get_opacity()

    rotation = rand_range(0.0, TAU)
    var base_scale: float = rand_range(0.7225, 0.8925)
    scale = Vector2.ONE * base_scale

    _fissure_sprite.material.set_shader_param("crack_progress", 0.0)
    _fissure_sprite.material.set_shader_param("dissolve_amount", 0.0)
    _fissure_sprite.material.set_shader_param("pulse_time", 0.0)

    _crater_sprite.modulate.a = 0.65

    _dust_particles.emitting = true
    _dust_particles.restart()

    visible = true
    set_physics_process(true)


func _physics_process(delta: float) -> void:
    var previous_elapsed: float = _elapsed
    _elapsed += delta

    if previous_elapsed < CRACK_EXPAND_DURATION:
        var crack_prog = min(_elapsed / CRACK_EXPAND_DURATION, 1.0)
        _fissure_sprite.material.set_shader_param("crack_progress", crack_prog)
    _fissure_sprite.material.set_shader_param("pulse_time", _elapsed)

    _enemies_in_area.clear()
    for area in _aoe_area.get_overlapping_areas():
        var unit = area.get_parent()
        if unit is Enemy and not unit.dead:
            _enemies_in_area[unit.get_instance_id()] = unit

    if not _has_pulsed_damage and _elapsed >= 0.04:
        _has_pulsed_damage = true
        _apply_seismic_pulse(_enemies_in_area)

    _apply_tremor_slow()

    var fade_start: float = _duration * FADE_START_RATIO
    if _elapsed > fade_start:
        var fade_prog = clamp((_elapsed - fade_start) / (_duration - fade_start), 0.0, 1.0)
        _fissure_sprite.material.set_shader_param("dissolve_amount", fade_prog)
        _crater_sprite.modulate.a = (1.0 - fade_prog) * 0.65

    if _elapsed >= _duration:
        _finish()


func _apply_seismic_pulse(enemies_in_area: Dictionary) -> void:
    for unit_id in enemies_in_area:
        var unit = enemies_in_area[unit_id]
        var was_crit: bool = Utils.get_chance_success(_crit_chance)
        var final_damage: float = float(_damage)
        if was_crit:
            final_damage *= _crit_damage

        var push_dir = (unit.global_position - global_position).normalized()
        if push_dir.length_squared() < 0.01:
            push_dir = Vector2.RIGHT.rotated(rand_range(0.0, TAU))

        var dmg_args: TakeDamageArgs = Utils.ncl_create_custom_damage_args(_player_index, Color("#ffaa33"))
        var health_before: int = unit.current_stats.health
        var damage_taken: Array = unit.take_damage(int(final_damage), dmg_args)
        RunData.add_weapon_dmg_dealt(_weapon_pos, damage_taken[1], _player_index)

        if unit.current_stats.health > 0:
            unit.knockback_vector = push_dir * 1.8

        Utils.fa_apply_direct_crit_kill_gold_rewards(
            _player_index,
            was_crit,
            health_before > 0 and damage_taken[1] >= health_before
        )


func _apply_tremor_slow() -> void:
    for unit_id in _enemies_in_area:
        if not _slowed_enemies.has(unit_id):
            EnemySpeedModifierService.set_percent_modifier(_enemies_in_area[unit_id], _slow_source_id, -float(_slow_percent), "earthshatter")

    for unit_id in _slowed_enemies:
        var enemy = _slowed_enemies[unit_id]
        if is_instance_valid(enemy) and not _enemies_in_area.has(unit_id):
            EnemySpeedModifierService.remove_modifier(enemy, _slow_source_id)
    var previous_enemies: Dictionary = _slowed_enemies
    _slowed_enemies = _enemies_in_area
    _enemies_in_area = previous_enemies


func _clear_tremor_slow() -> void:
    for unit_id in _slowed_enemies:
        var enemy = _slowed_enemies[unit_id]
        if is_instance_valid(enemy):
            EnemySpeedModifierService.remove_modifier(enemy, _slow_source_id)
    _slowed_enemies.clear()
    _enemies_in_area.clear()


func _exit_tree() -> void:
    _clear_tremor_slow()


func _finish() -> void:
    set_physics_process(false)
    visible = false
    _dust_particles.emitting = false
    _main.add_node_to_pool(self, _pool_id)
